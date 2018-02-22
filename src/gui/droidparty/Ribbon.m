/*
 * Copyright (c) 2013 Dan Wilcox <danomatika@gmail.com>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/danomatika/PdParty for documentation
 *
 */
#import "Ribbon.h"

#import "Gui.h"

@interface Ribbon () {
	UITouch *leftTouch, *rightTouch;
	float pValue, pValue2;
}
@end

@implementation Ribbon

- (id)initWithAtomLine:(NSArray *)line andGui:(Gui *)gui {
	if(line.count < 7) { // sanity check
		DDLogWarn(@"Ribbon: cannot create, atom line length < 7");
		return nil;
	}
	self = [super initWithAtomLine:line andGui:gui];
	if(self) {
		leftTouch = nil;
		rightTouch = nil;
		self.multipleTouchEnabled = YES;
		self.label = nil; // don't need label
		
		self.sendName = [Gui filterEmptyStringValues:[line objectAtIndex:7]];
		if(![self hasValidSendName]) {
			// drop something we can't interact with
			DDLogVerbose(@"Ribbon: dropping, send name is empty");
			return nil;
		}
		
		self.originalFrame = CGRectMake(
			[[line objectAtIndex:2] floatValue], [[line objectAtIndex:3] floatValue],
			[[line objectAtIndex:5] floatValue], [[line objectAtIndex:6] floatValue]);
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.5, 0.5); // snap to nearest pixel
    CGContextSetLineWidth(context, 1.0);

	// background
	CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
	CGContextFillRect(context, rect);
	CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
	
	// border
	CGContextSetStrokeColorWithColor(context, self.frameColor.CGColor);
	CGContextStrokeRect(context, CGRectMake(0, 0, CGRectGetWidth(rect)-1, CGRectGetHeight(rect)-1));
	
	// control
	float leftEdge = roundf(2 * self.gui.scaleX), rightEdge = roundf(CGRectGetWidth(rect)-1 - leftEdge);
	float left = CLAMP(roundf(self.value2 * CGRectGetWidth(rect)-1), leftEdge, rightEdge);
	float right = CLAMP(roundf(self.value * CGRectGetWidth(rect)-1), leftEdge, rightEdge);
	CGContextSetFillColorWithColor(context, self.controlColor.CGColor);
	CGContextFillRect(context, CGRectMake(left, 0.5, MAX(roundf(fabsf(right-left)), leftEdge), CGRectGetHeight(rect)-1));
}

#pragma mark Overridden Getters / Setters

- (void)setValue:(float)f {
	pValue = self.value;
	[super setValue:CLAMP(f, 0.0, 1.0)];
}

- (void)setValue2:(float)f {
	pValue2 = self.value2;
	_value2 = CLAMP(f, 0.0, 1.0);
	[self setNeedsDisplay];
}

- (NSString *)type {
	return @"Ribbon";
}

#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		CGPoint pos = [touch locationInView:self];
		float controlWidth = 3 * self.gui.scaleX;
		float left = self.value2 * CGRectGetWidth(self.frame);
		float right = self.value * CGRectGetWidth(self.frame);
		if(!rightTouch && pos.x >= right - controlWidth && pos.x <= right + controlWidth) {
			rightTouch = touch;
		}
		else if(!leftTouch && pos.x >= left - controlWidth && pos.x <= left + controlWidth) {
			leftTouch = touch;
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	BOOL changed = NO;
	for(UITouch *touch in touches) {
		CGPoint pos = [touch locationInView:self];
		if(touch == rightTouch) {
			float v = CLAMP(pos.x / CGRectGetWidth(self.frame), self.value2, 1.0);
			if(v != self.value) {
				self.value = v;
				changed = YES;
			}
		}
		
		if(touch == leftTouch) {
			float v = CLAMP(pos.x / CGRectGetWidth(self.frame), 0.0, self.value);
			if(v != self.value2) {
				self.value2 = v;
				changed = YES;
			}
		}
	}
	if(changed) {
		[self sendList:[NSArray arrayWithObjects:
		[NSNumber numberWithFloat:self.value],
		[NSNumber numberWithFloat:self.value2], nil]];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		if(touch == leftTouch) {
			leftTouch = nil;
		}
		else if(touch == rightTouch) {
			rightTouch = nil;
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	for(UITouch *touch in touches) {
		if(touch == leftTouch) {
			leftTouch = nil;
		}
		else if(touch == rightTouch) {
			rightTouch = nil;
		}
	}
}

@end
