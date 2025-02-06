import Foundation

@objcMembers
@objc(EZSiliconFlowService)
public class SiliconFlowService: BaseSiliconFlowService {
    override func serviceType() -> ServiceType {
        return .siliconFlow
    }
    
    override func model() -> String {
        return "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
    }
    
    override func endpoint() -> String {
        return "https://api.siliconflow.cn/v1/chat/completions"
    }
    
    override func apiKey() -> String {
        return Configuration.shared.siliconFlowAPIKey
    }
    
    override func queryType(text: String, from: Language, to: Language) -> QueryType {
        return .translate
    }
} 