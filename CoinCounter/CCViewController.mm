//
//  CCViewController.m
//  CoinCounter
//
//  Created by Nikola Mircic on 2/25/13.
//  Copyright (c) 2013 UNIT. All rights reserved.
//

#import "CCViewController.h"

@interface CCViewController ()
{
	UIImage * imageToProcess;
}
@end

@implementation CCViewController

@synthesize imagePickerController = _imagePickerController;
@synthesize finalImage = _finalImage;
- (void)viewDidLoad
{
    [super viewDidLoad];

	
	self.imagePickerController = [[UIImagePickerController alloc] init];
	self.imagePickerController.delegate = self;
	self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	// user wants to use the camera interface
	//
	self.imagePickerController.showsCameraControls = YES;
	self.imagePickerController.allowsEditing = NO;
	
	self.imagePickerController.navigationBarHidden = NO;
	self.imagePickerController.toolbarHidden = YES;
	

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
	CGFloat cols = image.size.width;
	CGFloat rows = image.size.height;
	
	cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
	
	CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
													cols,                       // Width of bitmap
													rows,                       // Height of bitmap
													8,                          // Bits per component
													cvMat.step[0],              // Bytes per row
													colorSpace,                 // Colorspace
													kCGImageAlphaNoneSkipLast |
													kCGBitmapByteOrderDefault); // Bitmap info flags
	
	CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
	cv::cvtColor(cvMat , cvMat , CV_RGBA2RGB);
	return cvMat;
}

- (cv::Mat)cvMatWithImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
	
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
	
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
													cols,                       // Width of bitmap
													rows,                       // Height of bitmap
													8,                          // Bits per component
													cvMat.step[0],              // Bytes per row
													colorSpace,                 // Colorspace
													kCGImageAlphaNoneSkipLast |
													kCGBitmapByteOrderDefault); // Bitmap info flags
	
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
	
    return cvMat;
}

- (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
	
    CGColorSpaceRef colorSpace;
	
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
	
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
										cvMat.rows,                                     // Height
										8,                                              // Bits per component
										8 * cvMat.elemSize(),                           // Bits per pixel
										cvMat.step[0],                                  // Bytes per row
										colorSpace,                                     // Colorspace
										kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
										provider,                                       // CGDataProviderRef
										NULL,                                           // Decode
										false,                                          // Should interpolate
										kCGRenderingIntentDefault);                     // Intent
	
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
	
    return image;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
	NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
	CGColorSpaceRef colorSpace;
	
	if (cvMat.elemSize() == 1) {
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	
	// Creating CGImage from cv::Mat
	CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
										cvMat.rows,                                 //height
										8,                                          //bits per component
										8 * cvMat.elemSize(),                       //bits per pixel
										cvMat.step[0],                            //bytesPerRow
										colorSpace,                                 //colorspace
										kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
										provider,                                   //CGDataProviderRef
										NULL,                                       //decode
										false,                                      //should interpolate
										kCGRenderingIntentDefault                   //intent
										);
	
	
	// Getting UIImage from CGImage
	UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return finalImage;
}

- (IBAction)takeAShot:(id)sender {
	[self presentViewController:self.imagePickerController animated:YES completion:nil];
}


- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{

	imageToProcess = [UIImage imageWithCGImage:[[info valueForKey:UIImagePickerControllerOriginalImage] CGImage] scale:1 orientation: UIImageOrientationUp];
		[self dismissViewControllerAnimated:YES completion:nil];
	[self doHoughTransform];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	
}



-(void) doHoughTransform
{
	cv::Mat srcImag = [self cvMatWithImage:imageToProcess];
	cv::Mat src_gray;
	
		
	cvtColor( srcImag, src_gray, CV_BGR2GRAY );
	/// Reduce the noise so we avoid false circle detection
	GaussianBlur( src_gray, src_gray, cv::Size(9, 9), 2, 2 );
	//adaptiveThreshold(src_gray, src_gray, 255,CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY,75,10);
	
	//UIImage *image=  [self UIImageFromCVMat:src_gray];
	//[self.finalImage setImage:image];
	
	cv::vector<cv::Vec3f> circles;
	
	/// Apply the Hough Transform to find the circles
	HoughCircles( src_gray, circles, CV_HOUGH_GRADIENT, 1, src_gray.rows/25, 50, 60, 0, 0 );

 //      src_gray: Input image (grayscale)
  //     circles: A vector that stores sets of 3 values:  for each detected circle.
	//   CV_HOUGH_GRADIENT: Define the detection method. Currently this is the only one available in OpenCV
//	   dp = 1: The inverse ratio of resolution
//	   min_dist = src_gray.rows/8: Minimum distance between detected centers
//	   param_1 = 200: Upper threshold for the internal Canny edge detector
//	   param_2 = 100*: Threshold for center detection.
//	   min_radius = 0: Minimum radio to be detected. If unknown, put zero as default.
//	   max_radius = 0: Maximum radius to be detected. If unknown, put zero as default


	/// Draw the circles detected
	for( size_t i = 0; i < circles.size(); i++ )
	{
		cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
		
		int radius = cvRound(circles[i][2]);
		cv::Point textancor(cvRound(circles[i][0]-radius*0.7), cvRound(circles[i][1]+radius*0.5));
		// circle center
		//circle( srcImag, center, 3, cv::Scalar(0,255,0), -1, 8, 0 );
		//putText(srcImag,[[NSString alloc ] initWithFormat:@"%d", radius] , center, cv::FONT_HERSHEY_COMPLEX_SMALL, 0.8, cvScalar(200,200,250), 1, CV_AA);
		putText( srcImag,[[[NSString alloc] initWithFormat:@"%d", radius] cStringUsingEncoding: NSASCIIStringEncoding], textancor, cv::FONT_HERSHEY_SIMPLEX, 3, cvScalar(200,200,250),6);
		// circle outline
		circle( srcImag, center, radius, cv::Scalar(0,0,255), 3, 8, 0 );
	}


	UIImage *image=  [self UIImageFromCVMat:srcImag];
	[self.finalImage setImage:image];
	
}


@end
