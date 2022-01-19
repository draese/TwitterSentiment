//
//  ClassifiedTweets.swift
//  TwitterSentiment
//
//  Created by Oliver Draese on 1/17/22.
//
import os
import Foundation
import Swifter
import CoreML

/// Model class to hold the (by sentimented sorted) tweets.
/// A single instance of this "container" is created after receiving all the tweets from Twitter
/// and running them through the NLP classifier to get their sentiment. This container essentially
/// just stoes the tweets in separate arrays for each of the sentiments
struct ClassifiedTweets {
    /// all tweets that were classified as negative
    let negative: [Tweet]
    
    /// all tweets that were classified as neutral
    let neutral: [Tweet]
    
    /// all tweets that were classified as positive
    let positive: [Tweet]
    
    /// The total count of all tweets (sum of all categories)
    var count: Int {
        return negative.count + neutral.count + positive.count
    }
    
    /// All the tweets, independent of their classification, in shuffled order.
    var all: [Tweet] {
        var ret = [Tweet](negative)
        ret.append(contentsOf: neutral)
        ret.append(contentsOf: positive)
        
        return ret.shuffled()
    }
    
    private let logger = Logger(subsystem: K.Log.subSys, category: K.Log.ml)
    
    /// Creates a new container instance based on Swifter's fetched Tweet list.
    /// - Parameter twitterResponse: The Swifter output of the Twitter search query
    init(twitterResponse: JSON) {
        let classifier = try! TwitterSentimentClassifier(contentsOf: TwitterSentimentClassifier.urlOfModelInThisBundle)

        var neg = [Tweet]()
        var neu = [Tweet]()
        var pos = [Tweet]()

        // map each input tweet into a target array by the classifier's output
        if let source = twitterResponse.array {
            // prepare batch-scoring input by mapping tweet text into classifier input
            let batchInput = source.map { tweet in TwitterSentimentClassifierInput(text: tweet[K.Swifter.fullTextKey].string ?? "") }

            do {
                // batch-score the whole input set of tweets
                let classifierOutput = try classifier.predictions(inputs: batchInput)
                
                // wrap the classifier output into our own Tweet model class instances
                for i in 0 ..< classifierOutput.count {
                    let mappedTweet = Tweet(text: batchInput[i].text , sentimentFromString: classifierOutput[i].label)
                    
                    switch(mappedTweet.sentiment) {
                    case .negative: neg.append(mappedTweet)
                    case .neutral: neu.append(mappedTweet)
                    case .positive: pos.append(mappedTweet)
                    }
                }
            } catch {
                logger.error("Failed to classify tweets: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        logger.debug("Mapped \(neg.count, privacy: .public) negative, \(neu.count, privacy: .public) neutral and \(pos.count, privacy: .public) tweets.")
        negative = neg
        neutral = neu
        positive = pos
    }
}
