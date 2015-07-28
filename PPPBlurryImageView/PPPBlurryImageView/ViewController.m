//
//  ViewController.m
//  PPPBlurryImageView
//
//  Created by Yunfeng Liang on 15/7/22.
//
//

#import "ViewController.h"
#import "PPPBlurryImageView/PPPBlurryImageView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet PPPBlurryImageView *imageView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (nonatomic) CADisplayLink *displayLink;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;

@property (nonatomic) CFTimeInterval time;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"%@", NSStringFromCGSize([UIScreen mainScreen].bounds.size));
    
    self.imageView.image = [UIImage imageNamed:@"1"];
    self.imageView.blur = 0;
    //[self.imageView setEnableSetNeedsDisplay:NO];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)tick:(CADisplayLink *)displayLink {
    CFTimeInterval duration = displayLink.timestamp - self.time;
    self.time = displayLink.timestamp;
    self.fpsLabel.text = [NSString stringWithFormat:@"FPS %.0f", 1.0f / duration];
    
    //[self.imageView display];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)touh:(id)sender {
    NSLog(@"touch");
}
- (IBAction)changed:(id)sender {
    self.imageView.blur = self.slider.value * 20.0f;
    
}

@end
