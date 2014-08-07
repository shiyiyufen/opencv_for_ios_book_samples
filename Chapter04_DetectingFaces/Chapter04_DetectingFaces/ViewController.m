/*****************************************************************************
 *   ViewController.m
 ******************************************************************************
 *   by Kirill Kornyakov and Alexander Shishkov, 5th May 2013
 ******************************************************************************
 *   Chapter 4 of the "OpenCV for iOS" book
 *
 *   Detecting Faces with Cascade Classifier shows how to detect faces
 *   using OpenCV.
 *
 *   Copyright Packt Publishing 2013.
 *   http://bit.ly/OpenCV_for_iOS_book
 *****************************************************************************/

#import "ViewController.h"
#import "opencv2/highgui/ios.h"
#import "Utility.h"

@interface ViewController ()

@end

@implementation ViewController
static int kImageIndex = 0;
@synthesize imageView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load cascade classifier from the XML file
    NSString* cascadePath = [[NSBundle mainBundle]
                     pathForResource:@"haarcascade_frontalface_alt"
                              ofType:@"xml"];
    faceDetector.load([cascadePath UTF8String]);
    
    
    [self startNext];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)faceDetector:(UIImage *)targetImage
{
    //Load image with face
    UIImage* image = targetImage;
    cv::Mat faceImage;
    UIImageToMat(image, faceImage);
    
    // Convert to grayscale
    cv::Mat gray;
    cvtColor(faceImage, gray, CV_BGR2GRAY);
    
    // Detect faces
    std::vector<cv::Rect> faces;
    faceDetector.detectMultiScale(gray, faces, 1.1,
                                  2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
    
    cv::Rect someface;
    // Draw all detected faces
    for(unsigned int i = 0; i < faces.size(); i++)
    {
        const cv::Rect& face = faces[i];
        someface = face;
        // Get top-left and bottom-right corner points
        cv::Point tl(face.x, face.y);
        cv::Point br = tl + cv::Point(face.width, face.height);
        
        // Draw rectangle around the face
        cv::Scalar magenta = cv::Scalar(255, 0, 255);
        cv::rectangle(faceImage, tl, br, magenta, 4, 8, 0);
    }
    
    //面部
    CGImageRef cgimg = CGImageCreateWithImageInRect([image CGImage], CGRectMake(someface.x, someface.y, someface.width, someface.height));
    UIImage *target = [UIImage imageWithCGImage:cgimg];
    self.avatarImageView.image = target;
    CGImageRelease(cgimg);//用完一定要释放，否则内存泄露
    // Show resulting image
    imageView.image = MatToUIImage(faceImage);
    return target;
}

//画直方图用
int HistogramBins = 256;
float HistogramRange1[2]={0,255};
float *HistogramRange[1]={&HistogramRange1[0]};
int CompareHist(IplImage* image1, IplImage* image2)
{
    IplImage* srcImage;
    IplImage* targetImage;
    if (image1->nChannels != 1) {
        srcImage = cvCreateImage(cvSize(image1->width, image1->height), image1->depth, 1);
        cvCvtColor(image1, srcImage, CV_BGR2GRAY);
    } else {
        srcImage = image1;
    }
    
    if (image2->nChannels != 1) {
        targetImage = cvCreateImage(cvSize(image2->width, image2->height), srcImage->depth, 1);
        cvCvtColor(image2, targetImage, CV_BGR2GRAY);
    } else {
        targetImage = image2;
    }
    
    CvHistogram *Histogram1 = cvCreateHist(1, &HistogramBins, CV_HIST_ARRAY,HistogramRange);
    CvHistogram *Histogram2 = cvCreateHist(1, &HistogramBins, CV_HIST_ARRAY,HistogramRange);
    
    cvCalcHist(&srcImage, Histogram1);
    cvCalcHist(&targetImage, Histogram2);
    
    cvNormalizeHist(Histogram1, 1);
    cvNormalizeHist(Histogram2, 1);
    
    // CV_COMP_CHISQR,CV_COMP_BHATTACHARYYA这两种都可以用来做直方图的比较，值越小，说明图形越相似
    double chisqr = cvCompareHist(Histogram1, Histogram2, CV_COMP_CHISQR);
    double bhattacharyya = cvCompareHist(Histogram1, Histogram2, CV_COMP_BHATTACHARYYA);
    printf("CV_COMP_CHISQR : %.4f\n", chisqr);
    printf("CV_COMP_BHATTACHARYYA : %.4f\n", cvCompareHist(Histogram1, Histogram2, bhattacharyya));
    
    
    // CV_COMP_CORREL, CV_COMP_INTERSECT这两种直方图的比较，值越大，说明图形越相似
    double correl = cvCompareHist(Histogram1, Histogram2, CV_COMP_CORREL);
    double intersect = cvCompareHist(Histogram1, Histogram2, CV_COMP_INTERSECT);
    
    printf("CV_COMP_CORREL : %.4f\n", correl);
    printf("CV_COMP_INTERSECT : %.4f\n", intersect);
    
    cvReleaseHist(&Histogram1);
    cvReleaseHist(&Histogram2);
    if (image1->nChannels != 1) {
        cvReleaseImage(&srcImage);
    }
    if (image2->nChannels != 1) {
        cvReleaseImage(&targetImage);
    }
    
    if (chisqr + bhattacharyya < 0.2 && correl + intersect > 1.8)
    {
        return 1;
    }
    return 0;
}

- (IBAction)refrashIt:(id)sender
{
    [self startNext];
}

- (void)startNext
{
    int index = (kImageIndex % 3) + 1;
    UIImage *orgin = [self faceDetector:[UIImage imageNamed:[NSString stringWithFormat:@"%d.png",index]]];
    UIImage *target = [UIImage imageNamed:[NSString stringWithFormat:@"%d-%d.png",index,index]];
    self.targetImageView.image = target;
    kImageIndex++;
    
    IplImage *img1 = [Utility CreateIplImageFromUIImage:orgin];
    IplImage *img2 = [Utility CreateIplImageFromUIImage:target];
    int result = CompareHist(img1, img2);
    NSLog(@"Two image is equal: %@",result ? @"YES" : @"NO");
}
@end
