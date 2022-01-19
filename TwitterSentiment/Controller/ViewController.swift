//
//  ViewController.swift
//  TwitterSentiment
//
//  Created by Oliver Draese on 1/17/22.
//
import os
import UIKit
import Swifter
import Charts

/// Controller implementation for the single view that this app serves.
class ViewController: UIViewController {
    @IBOutlet weak var queryTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var tweetLabel: UILabel!
    
    private let logger = Logger(subsystem: K.Log.subSys, category: K.Log.ctrl)
    
    /// Using Swifter package here to communicate with Twitter. Swifter uses the 1.1 API from Twitter and therefore the
    /// consumer credentials require elevated permissions.
    private let twitterClient = Swifter(consumerKey: K.Swifter.apiKey!, consumerSecret: K.Swifter.apiSecret!)
    
    /// Our own container class with the (by sentiment) sorted tweets
    private var allTweets: ClassifiedTweets?
    
    /// The timer is used to display one of the tweets at the bottom of the view, chaning it all 5 seconds.
    private var tweetTimer :Timer?
    
    /// The currently selected group of tweets (to be displayed via timer at bottom of the view.
    private var selectedTweets: [Tweet]? {
        didSet {
            currentTweetIndex = 0
        }
    }
    
    /// Index into the array of currentlu selected tweets.
    private var currentTweetIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        queryTextField.delegate = self
        pieChartView.legend.enabled = false
        pieChartView.holeColor = nil
        pieChartView.noDataText = ""
        pieChartView.delegate = self
    }

    /// Called whenever the text in the input field changed.#colorLiteral(
    /// The event is used here to enable/disable the search button depending if the input
    /// is empty or not.
    /// - Parameter sender: The actual text field
    @IBAction func queryEditingChanged(_ sender: UITextField) {
        var enabled = false;
        
        if let query = sender.text?.trimmingCharacters(in: .whitespaces) {
            enabled = !query.isEmpty
        }
        
        searchButton.isEnabled = enabled
    }
    
    /// Called when the search button was clicked.
    /// This handler uses the Swifter API to perform the actual search of tweets. The result is then
    /// passed through the classification model and stored for presentation in the chart and the
    /// label.
    /// - Parameter sender: Reference to the search button
    @IBAction func searchButtonClicked(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.queryTextField.resignFirstResponder()
        }
        
        if let query = queryTextField.text?.trimmingCharacters(in: .whitespaces) {
            // get the last 100 english tweets based on the input box
            twitterClient.searchTweet(using: query, lang: "en", count: K.numTweets, tweetMode: .extended) { response, searchMetadata in
                // classify and sort the returned tweets
                self.allTweets = ClassifiedTweets(twitterResponse: response)
                
                // display the new tweets.
                DispatchQueue.main.async {
                    self.visualizeResult()
                }
            } failure: { error in
                // errors are just sent to the log
                self.logger.error("\(error.localizedDescription)")
            }
        }
    }
    
    /// Helper to feed the results (counts per classification) into the piechart and showing tweets in labels.
    func visualizeResult() {
        // deselect current
        pieChartView.highlightValue(nil)
        
        if let tweets = allTweets {
            let negative = Double(tweets.negative.count)
            let neutral  = Double(tweets.neutral.count)
            let positive = Double(tweets.neutral.count)
            let format = NumberFormatter()
            format.numberStyle = .none

            // create the three data categories with the sum of tweets (in category) for piechart
            var dataEntries = [ChartDataEntry]()
            dataEntries.append(PieChartDataEntry(value: negative, label: "Negative", data: Tweet.Sentiment.negative))
            dataEntries.append(PieChartDataEntry(value: neutral, label: "Neutral", data: Tweet.Sentiment.neutral))
            dataEntries.append(PieChartDataEntry(value: positive, label: "Positive", data: Tweet.Sentiment.positive))
            
            // configure colors for the data
            let dataSet = PieChartDataSet(entries: dataEntries)
            dataSet.colors = [K.Colors.colorNegative, K.Colors.colorNeutral, K.Colors.colorPositive]
            dataSet.sliceSpace = 10
            
            // combine input for the piechart
            let pieChartData = PieChartData(dataSet: dataSet)
            let formatter = DefaultValueFormatter(formatter: format)
            pieChartData.setValueFormatter(formatter)

            pieChartView.data = pieChartData
            pieChartView.centerText = "Last \(tweets.count) tweets."
            selectedTweets = tweets.all
            
            displayNextLabel()
            
            // create a new timer that triggers all 5 seconds to display a different tweet
            tweetTimer?.invalidate()
            tweetTimer = Timer.scheduledTimer(withTimeInterval: K.timerInterval, repeats: true) { _ in
                // update the label text in the main thread
                DispatchQueue.main.async {
                    // soft transition between two label texts
                    self.displayNextLabel()
                }
            }
        } else {
            pieChartView.data = nil
            selectedTweets = nil
        }
    }
    
    /// Helper to update the label text (and color) in the bottom label with transition.
    func displayNextLabel() {
        // perform a smooth transition between the label texts
        UIView.transition(with: tweetLabel, duration: 0.5, options: .transitionCrossDissolve, animations: { [weak self] in
            if let self = self {
                if let tweetArray = self.selectedTweets {
                    if tweetArray.isEmpty {
                        self.tweetLabel.text = "None in this classification."
                        self.tweetLabel.backgroundColor = nil
                    } else {
                        let newTweet = tweetArray[self.currentTweetIndex]
                        self.currentTweetIndex += 1
                        if self.currentTweetIndex >= tweetArray.count {
                            self.currentTweetIndex = 0
                        }
                        
                        self.tweetLabel.text = newTweet.text
                        
                        // adjust label background color based on sentiment
                        switch(newTweet.sentiment) {
                        case .negative: self.tweetLabel.backgroundColor = K.Colors.colorLabelNegative
                        case .neutral: self.tweetLabel.backgroundColor = K.Colors.colorLabelNeutral
                        case .positive: self.tweetLabel.backgroundColor = K.Colors.colorLabelPositive
                        }
                    }
                }
            }
        }, completion: nil)
    }
}

// MARK: - UITextFieldDelegate (Twitter query field)
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let query = textField.text?.trimmingCharacters(in: .whitespaces) {
            if !query.isEmpty {
                searchButtonClicked(self.searchButton)
                return true
            }
        }
        
        return false
    }
}

// MARK: -  ChartViewDelegate (listening to piechart selections)
extension ViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        switch(entry.data as! Tweet.Sentiment) {
        case .negative: selectedTweets = allTweets?.negative
        case.neutral: selectedTweets = allTweets?.neutral
        case .positive: selectedTweets = allTweets?.positive
        }
        
        displayNextLabel()
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        selectedTweets = allTweets?.all
        displayNextLabel()
    }
}

