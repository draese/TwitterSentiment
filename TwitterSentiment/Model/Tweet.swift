//
//  Tweet.swift
//  TwitterSentiment
//
//  Created by Oliver Draese on 1/17/22.
//
import Foundation

/// Model class that hods the information for a single Twitter tweet.
struct Tweet {
    /// The tweet text (full, not truncated)
    let text: String
    /// Output of the sentiment classification model (negative, neutral or positive)
    let sentiment: Sentiment
    
    init(text: String, sentimentFromString: String) {
        self.text = text
        self.sentiment = Sentiment(fromString: sentimentFromString)
    }

    ///  Enumerating the possible output values of the TwitterSentimentClassifier
    enum Sentiment {
        case negative, neutral, positive
        
        /// Mapping the label to enumeration value.
        /// Minus one is becoming negative, zero neutral and one is positivie.
        init(fromString: String) {
            switch(fromString) {
            case K.ModelLabel.negative: self  = .negative
            case K.ModelLabel.neutral: self = .neutral
            case K.ModelLabel.positive: self = .positive
            default: fatalError("Unknown sentiment string: \(fromString)")
            }
        }
    }
}

