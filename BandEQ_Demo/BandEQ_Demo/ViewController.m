//
//  ViewController.m
//  BandEQ_Demo
//
//  Created by lc on 13-10-30.
//  Copyright (c) 2013年 Luo Chun. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, retain) NSMutableDictionary *valueListOfEQParam;
@property (nonatomic, retain) NSArray *eqFrequencies;
@property (nonatomic, retain) UIView *eqView;

@property (nonatomic, retain) TOBandEqualizer *bandeq;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.eqFrequencies = @[ @32, @64, @125, @250, @500, @1000, @2000, @4000, @8000, @16000 ];

    self.valueListOfEQParam=[[[NSMutableDictionary alloc]initWithObjects:@[ @0,@0,@0,@0,@0,@0,@0,@0,@0,@0]
                                forKeys:@[ @"H1",@"H2",@"H3",@"H4",@"H5",@"H6",@"H7",@"H8",@"H9",@"H10"] ] autorelease] ;
	self.bandeq = [[[TOBandEqualizer alloc] init] autorelease];
   
    [_bandeq setUp];
    [_bandeq setUpFilePlayerUnit];
    _bandeq.bands = _eqFrequencies;
}

- (void)EQParamValueChanged:(UISlider*)sender {
    [self.valueListOfEQParam setValue:[NSString stringWithFormat:@"%f",sender.value]
                               forKey:[NSString stringWithFormat:@"H%d",sender.tag]];
    NSLog(@"%d:%f",sender.tag,sender.value);

    [_bandeq setGain:sender.value forBandAtPosition:sender.tag- 1];
    UILabel *lab=(UILabel *)[_eqView viewWithTag:1000+sender.tag-1];
    lab.text = [NSString stringWithFormat:@"%@Hz: %.2fdB",_eqFrequencies[sender.tag-1],[_valueListOfEQParam[[NSString stringWithFormat:@"H%d",sender.tag]] floatValue]];
    
}
- (void)BackEQAction:(id)sender{
    //    for (AEAudioUnitFilter *filter in _eqList) {
    //        [_audioController removeFilter:filter];
    //    }
    //    [_eqList removeAllObjects];
    
    //[_audioController removeFilter:_testequalizer];
	[_eqView removeFromSuperview];
    _eqView=nil;
}
- (void)setDefaultAction:(id)sender{
    for (int i=0; i<_eqFrequencies.count; i++) {
        [self.valueListOfEQParam setValue:0 forKey:[NSString stringWithFormat:@"H%d",i+1]];
        [_bandeq setGain:0 forBandAtPosition:i];
        
        UILabel *lab=(UILabel *)[_eqView viewWithTag:1000+i];
        lab.text = [NSString stringWithFormat:@"%@Hz: %.2fdB",_eqFrequencies[i],
                    [_valueListOfEQParam[[NSString stringWithFormat:@"H%d",i+1]] floatValue]];
        UISlider *slider=(UISlider *)[_eqView viewWithTag:i+1];
        [slider setValue:0];
    }
}

- (IBAction)flipEQ:(UIButton *)sender {
    if(!_eqView){
        
        self.eqView=[[[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease] ;
        _eqView.backgroundColor=[UIColor whiteColor];
        UIButton *cancelBtn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancelBtn setTitle:@"Back" forState:UIControlStateNormal];
        [cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [cancelBtn setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        cancelBtn.frame=CGRectMake(self.view.bounds.size.width-80,self.view.bounds.size.height-40,
                                   70,35);
        [cancelBtn addTarget:self action:@selector(BackEQAction:) forControlEvents:UIControlEventTouchUpInside];
        [_eqView addSubview:cancelBtn];
        
        UIButton *setdefaultBtn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
        [setdefaultBtn setTitle:@"Default" forState:UIControlStateNormal];
        [setdefaultBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [setdefaultBtn setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        setdefaultBtn.frame=CGRectMake(20,self.view.bounds.size.height-40,
                                       70,35);
        [setdefaultBtn addTarget:self action:@selector(setDefaultAction:) forControlEvents:UIControlEventTouchUpInside];
        [_eqView addSubview:setdefaultBtn];

        for (int i=0; i<_eqFrequencies.count; i++) {
            UILabel *valueOfEQLable=[[UILabel alloc] initWithFrame:CGRectMake(5, 6+32*i, 140, 32)];
            [valueOfEQLable setTextColor:[UIColor redColor]];
            valueOfEQLable.text=[NSString stringWithFormat:@"%@Hz: %.2fdB",_eqFrequencies[i],[_valueListOfEQParam[[NSString stringWithFormat:@"H%d",i+1]] floatValue]];
            valueOfEQLable.tag=1000+i;
            [_eqView addSubview:valueOfEQLable];
            
            UISlider *eqslider=[[UISlider alloc] initWithFrame:CGRectMake(150, 6+32*i, 160, 32)];
            eqslider.maximumValue = 12.0;
            eqslider.minimumValue = -12.0;
            eqslider.value=[_valueListOfEQParam[[NSString stringWithFormat:@"H%d",i+1]] floatValue];
            eqslider.tag=i+1;   //all controls tag default 0 ,so tag<0
            [eqslider addTarget:self action:@selector(EQParamValueChanged:) forControlEvents:UIControlEventValueChanged];
            [_eqView addSubview:eqslider];
        }
        
    }
    [self.view addSubview:_eqView ];
}
    
@end
