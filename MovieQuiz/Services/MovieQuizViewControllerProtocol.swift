//
//  MovieQuizViewControllerProtocol.swift
//  MovieQuiz
//
//  Created by Антон Павлов on 21.07.2023.
//

import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func showCurrentQuestion(step: QuizStepViewModel)
    func showQuizResults(result: QuizResultsViewModel)
    
    func highlightImageBorder(isCorrectAnswer: Bool)
    
    func showLoadingIndicator()
    func hideLoadingIndicator()
    
    func showNetworkError(message: String)
    
    func setButtonsEnabled(_ isEnabled: Bool)
}
