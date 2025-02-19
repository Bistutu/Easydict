//
//  CustomOpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/16.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZCustomOpenAIService)
class CustomOpenAIService: BaseOpenAIService {
    // MARK: Public

    public override func name() -> String {
        let serviceName = Defaults[super.nameKey]
        return serviceName.isEmpty ? NSLocalizedString("custom_openai", comment: "") : serviceName
    }

    public override func serviceType() -> ServiceType {
        .customOpenAI
    }

    // MARK: Internal

    override func serviceTypeWithUniqueIdentifier() -> String {
        guard !uuid.isEmpty else {
            return ServiceType.customOpenAI.rawValue
        }
        return "\(ServiceType.customOpenAI.rawValue)#\(uuid)"
    }

    override func isDuplicatable() -> Bool {
        true
    }

    override func isDeletable(_ type: EZWindowType) -> Bool {
        !uuid.isEmpty
    }

    override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showNameSection: true,
            showCustomPromptSection: true
        )
    }

    override func chatMessageDicts(_ chatQuery: ChatQueryParam) -> [ChatMessage] {
        if enableCustomPrompt {
            var chatMessages: [ChatMessage] = []
            let systemPrompt = replaceCustomPromptWithVariable(systemPrompt)
            var userPrompt = replaceCustomPromptWithVariable(userPrompt)

            if !systemPrompt.isEmpty {
                chatMessages.append(.init(role: .system, content: systemPrompt))
            }

            // If user prompt is empty, use query text as user prompt
            if userPrompt.isEmpty {
                userPrompt = queryModel.queryText
            }
            chatMessages.append(.init(role: .user, content: userPrompt))

            return chatMessages
        }
        return super.chatMessageDicts(chatQuery)
    }

    /**
     Convert custom prompt $xxx to variable.

     e.g.
     prompt: Translate the following ${{queryFromLanguage}} text into ${{queryTargetLanguage}}: ${{queryText}}
     runtime prompt: Translate the following English text into Simplified-Chinese: Hello, world

     ${{queryFromLanguage}} --> queryModel.queryFromLanguage.rawValue
     ${{queryTargetLanguage}} --> queryModel.queryTargetLanguage.rawValue
     ${{queryText}} --> queryModel.queryText
     ${{firstLanguage}} --> Configuration.shared.firstLanguage.rawValue
     */
    func replaceCustomPromptWithVariable(_ prompt: String) -> String {
        var runtimePrompt = prompt

        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{queryFromLanguage}}",
            with: queryModel.queryFromLanguage.rawValue
        )
        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{queryTargetLanguage}}",
            with: queryModel.queryTargetLanguage.rawValue
        )
        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{queryText}}",
            with: queryModel.queryText
        )
        runtimePrompt = runtimePrompt.replacingOccurrences(
            of: "${{firstLanguage}}",
            with: Configuration.shared.firstLanguage.rawValue
        )
        return runtimePrompt
    }
}
