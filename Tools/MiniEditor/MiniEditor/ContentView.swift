//
//  ContentView.swift
//  MiniEditor
//
//  Created by Kazuki Nakashima on 2026/04/05.
//

import ObjCSyntaxInk
import SwiftUI

struct ContentView: View {
    @State private var selectedSample: VerificationSample = .header
    @State private var selectedTheme: VerificationTheme = .defaultLight
    @State private var reloadRevision = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Sample", selection: $selectedSample) {
                    ForEach(VerificationSample.allCases) { sample in
                        Text(sample.title).tag(sample)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
                .accessibilityIdentifier("samplePicker")

                Picker("Theme", selection: $selectedTheme) {
                    ForEach(VerificationTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
                .accessibilityIdentifier("themePicker")

                Button("Reload") {
                    reloadRevision += 1
                }
                .accessibilityIdentifier("reloadButton")

                Spacer()
            }
            .padding(16)

            Divider()

            ObjCSyntaxHighlighterView(
                source: selectedSample.source,
                fileKind: selectedSample.fileKind,
                theme: selectedTheme.theme,
                fileName: selectedSample.resolvedFileName(reloadRevision: reloadRevision)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("objcHighlighterView")
        }
        .frame(minWidth: 960, minHeight: 680)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("MiniEditor Root")
        .accessibilityIdentifier("miniEditorRoot")
    }
}

private enum VerificationTheme: String, CaseIterable, Identifiable {
    case defaultLight
    case defaultDark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultLight:
            "Default (Light)"
        case .defaultDark:
            "Default (Dark)"
        }
    }

    var theme: ObjCTheme {
        switch self {
        case .defaultLight:
            .default
        case .defaultDark:
            .defaultDark
        }
    }
}

private enum VerificationSample: String, CaseIterable, Identifiable {
    case header
    case implementation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .header:
            "Header"
        case .implementation:
            "Implementation"
        }
    }

    var fileKind: ObjCFileKind {
        switch self {
        case .header:
            .header
        case .implementation:
            .implementation
        }
    }

    var fileName: String {
        switch self {
        case .header:
            "SYNGreeter.h"
        case .implementation:
            "SYNGreeter.m"
        }
    }

    func resolvedFileName(reloadRevision: Int) -> String {
        guard reloadRevision > 0 else {
            return fileName
        }

        let fileExtension = (fileName as NSString).pathExtension
        let baseName = (fileName as NSString).deletingPathExtension
        return "\(baseName)-\(reloadRevision).\(fileExtension)"
    }

    var source: String {
        switch self {
        case .header:
            """
            #import <Foundation/Foundation.h>

            #define SYN_GREETER_VERSION 7

            /// Greeter interface
            @interface SYNGreeter : NSObject <NSCopying>

            @property (nonatomic, copy) NSString *name;
            @property (class, nonatomic, readonly) NSString *displayName;

            - (instancetype)initWithName:(NSString *)name;
            - (NSString *)greetingForCount:(NSInteger)count;

            @end
            """
        case .implementation:
            """
            #import "SYNGreeter.h"

            @implementation SYNGreeter

            + (NSString *)displayName {
                return @"SYN Greeter";
            }

            - (instancetype)initWithName:(NSString *)name {
                self = [super init];
                if (self != nil) {
                    _name = [name copy];
                }
                return self;
            }

            - (NSString *)greetingForCount:(NSInteger)count {
                return [NSString stringWithFormat:@"SYN-%@-%ld", self.name, (long)count];
            }

            @end
            """
        }
    }
}
