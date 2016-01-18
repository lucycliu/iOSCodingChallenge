//
//  ViewController.m
//  iOSCodingChallenge
//
//  Created by Administrator on 5/6/15.
//  Copyright (c) 2015 Touch of Modern. All rights reserved.
//

#import "MainTableViewController.h"
#import "ProductCell.h"

@interface MainTableViewController ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSMutableArray *products;

@end

@implementation MainTableViewController

static NSString *const iosCodingChallengeUrlString = @"https://public.touchofmodern.com/ioschallenge.json";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:nil];
    
    //fetch json products and refresh view
    [self fetchData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductCell *cell = (ProductCell *)[tableView dequeueReusableCellWithIdentifier:@"ProductCell"
                                                                       forIndexPath:indexPath];
    NSDictionary *product = _products[indexPath.row];
    
    cell.nameLabel.text = product[@"name"];
    cell.priceLabel.text = [NSString stringWithFormat:@"$%.2f", [product[@"price"] floatValue]];
    cell.descriptionLabel.text = product[@"description"];
    
    cell.productImageView.contentMode = UIViewContentModeScaleAspectFit;
    NSURL *imageURL = [NSURL URLWithString:product[@"image"]];
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    [cell.productImageView setImage:[UIImage imageWithData:imageData]];
    
    return cell;
}

// Delete item by swiping left
- (void)tableView:(UITableView *)tableView
  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
  forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_products removeObjectAtIndex:indexPath.row];
    [tableView reloadData];
}

#pragma Private Functions

- (void)fetchData {
    // Create JSON payload
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dict setValue:[dateFormatter stringFromDate:[NSDate date]] forKey:@"requestDate"];
    NSError *err;
    NSData *jsonPayload = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&err];
    
    // Send request
    NSURL *url = [NSURL URLWithString:iosCodingChallengeUrlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:jsonPayload];
    
    // Get & process data
    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request
                                                 completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (data) {
                NSArray *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:NULL];
                
                // Sort list by price
                NSSortDescriptor *priceDescriptor = [[NSSortDescriptor alloc] initWithKey:@"price"
                                                                                ascending:YES];
                NSArray *sortDescriptors = @[priceDescriptor];
                _products = [[jsonData sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
            else {
                // Did not get data, probably due to network issue.
                // If this were a full app, there'd be a lot more error handling implemented here.
                NSLog(@"%@", error);
            }
        }];
    [dataTask resume];
}

@end
