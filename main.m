//
//  main.m
//  SubsMgr
//
//  Created by Cyril DELAMARE on 31/01/09.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RubyCocoa/RBRuntime.h>

int main(int argc, const char *argv[])
{
    //return RBApplicationMain("rb_main.rb", argc, argv);
    
    
    RBApplicationInit("rb_main.rb", argc, argv, nil);
    return NSApplicationMain(argc, argv);
}
