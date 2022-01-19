//
//  Constants.swift
//  TwitterSentiment
//
//  Created by Oliver Draese on 1/17/22.
//
import Foundation
import UIKit

/// Helper struct to bundle all constants together.
struct K {
    /// Used to connect to Twitter, using Swifter API
    /// You have to create 
    struct Swifter {
        static let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String
        static let apiSecret = Bundle.main.infoDictionary?["API_SECRET"] as? String
        static let fullTextKey = "full_text"
    }
    
    /// Constants, related to Logger configuration.
    struct Log {
        static let subSys = "zone.forty-two.TwitterSentiment"
        static let ctrl = "controller"
        static let ml = "ml"
    }
    
    /// Defining the possible label values of TwitterSentimentClassifier.
    struct ModelLabel {
        static let negative = "-1"
        static let neutral = "0"
        static let positive = "1"
    }
    
    /// Colors, used in the view.
    struct Colors {
        static let colorNegative: UIColor = #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1)
        static let colorNeutral: UIColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        static let colorPositive: UIColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        static let colorLabelNegative: UIColor = colorNegative.withAlphaComponent(0.5)
        static let colorLabelNeutral: UIColor = colorNeutral.withAlphaComponent(0.5)
        static let colorLabelPositive: UIColor = colorPositive.withAlphaComponent(0.35)
    }
    
    /// Time between two label text transitions
    static let timerInterval = 5.0
    
    /// The number of tweets to request from Twitter
    static let numTweets = 100
}
