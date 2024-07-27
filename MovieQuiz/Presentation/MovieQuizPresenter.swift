import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    // MARK: - Private Properties
    
    private var questionFactory: QuestionFactory!
    private weak var viewController: MovieQuizViewControllerProtocol?
    private var alertPresenter: AlertPresenter
    private let statisticService: StatisticService!
    private var currentQuestion: QuizQuestion?
    
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    
    // MARK: - Initialization
    
    init(viewController: MovieQuizViewControllerProtocol, alertPresenter: AlertPresenter) {
        self.viewController = viewController
        self.alertPresenter = alertPresenter
        statisticService = StatisticServiceImpl()
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.showCurrentQuestion(step: viewModel)
        }
    }
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
    
    func didFailToLoadImage(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let message = error.localizedDescription
            self.viewController?.showNetworkError(message: message)
        }
    }
    
    // MARK: - Public Methods
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        questionFactory?.requestNextQuestion()
        viewController?.setButtonsEnabled(true)
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    private func setButtonsEnabled(_ isEnabled: Bool) {
        viewController?.setButtonsEnabled(isEnabled)
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else { return }
        let isCorrectAnswer = isYes == currentQuestion.correctAnswer
        
        if isCorrectAnswer {
            correctAnswers += 1
        }
        
        proceedWithAnswer(isCorrect: isCorrectAnswer)
    }
    
    func showQuizResultsAlert() {
        let text = makeResultMessage()
        
        alertPresenter.show(alertModel: AlertModel(
            title: "Этот раунд окончен!",
            message: text,
            buttonText: "Сыграть ещё раз"
        ) {
            self.correctAnswers = 0
            self.currentQuestionIndex = 0
            self.restartGame()
        })
    }
    
    private func proceedToNextQuestionOrResults() {
        if isLastQuestion() {
            let text = correctAnswers == questionsAmount ?
            "Поздравляем, вы ответили на 10 из 10!" :
            "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            viewController?.showQuizResults(result: viewModel)
            correctAnswers = 0
            currentQuestionIndex = 0
            showQuizResultsAlert()
        } else {
            switchToNextQuestion()
            questionFactory?.requestNextQuestion()
            setButtonsEnabled(true)
        }
    }
    
    private func makeResultMessage() -> String {
        guard let statisticService = statisticService else {
            return "Ошибка: статистика недоступна"
        }
        
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        guard let bestGame = statisticService.bestGame else {
            return "Ошибка: лучшая игра недоступна"
        }
        
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)/\(questionsAmount)"
        let bestGameInfoLine = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
        
        let resultMessage = [
            currentGameResultLine,
            totalPlaysCountLine,
            bestGameInfoLine,
            averageAccuracyLine
        ].joined(separator: "\n")
        
        return resultMessage
    }
    
    func proceedWithAnswer(isCorrect: Bool) {
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.proceedToNextQuestionOrResults()
        }
    }
}

