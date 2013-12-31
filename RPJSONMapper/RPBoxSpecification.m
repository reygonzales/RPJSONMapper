// Created by reynaldo on 12/30/13.


#import "RPBoxSpecification.h"

@implementation RPBoxSpecification
+ (RPBoxSpecification *)boxValueIntoPropertyWithName:(NSString *)propertyName
                                          usingBlock:(PropertyMapperBlock)block {
    RPBoxSpecification *blockWrapper = [RPBoxSpecification new];
    blockWrapper.propertyName = propertyName;
    blockWrapper.block = block;
    return blockWrapper;
}

@end