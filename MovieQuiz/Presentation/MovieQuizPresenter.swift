import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
   
    // MARK: - Private Properties
    
    private var questionFactory: QuestionFactory?
    private weak var viewController: MovieQuizViewController?
    private var statisticService: StatisticService?  // Сервис для сохранения статистики
    private var currentQuestion: QuizQuestion?  // Текущий вопрос
    
    private var currentQuestionIndex = 0  // Индекс текущего вопроса
    private var correctAnswers = 0  // Количество правильных ответов
    private let questionsAmount: Int = 10  // Общее количество вопросов

    // MARK: - Initialization
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        
        // Инициализация сервиса статистики
        statisticService = StatisticServiceImpl()
        
        // Инициализация QuestionFactory и загрузка данных
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        
        // Показ индикатора загрузки
        viewController.showLoadingIndicator()
    }

    // MARK: - Public Methods
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        // Весь код для обработки получения нового вопроса остается здесь, т.к. теперь MovieQuizPresenter является QuestionFactoryDelegate
        guard let question = question else {
            return
        }

        // Сохраняем текущий вопрос и обновляем UI
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.showCurrentQuestion(step: viewModel)
        }
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
        viewController?.enableButtons()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    // Конвертирование модели вопроса в модель представления
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }

    func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {return}
        if isYes{
            correctAnswers += 1
        }
        
        self.proceedWithAnswer(isCorrect: isYes == currentQuestion.correctAnswer)
    }
    // MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
    
    private func proceedToNextQuestionOrResults() {
        if self.isLastQuestion() {
            let text = correctAnswers == self.questionsAmount ?
            "Поздравляем, вы ответили на 10 из 10!" :
            "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"

            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
                viewController?.showQuizResults(result: viewModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
            viewController?.enableButtons()
        }
    }
    
    func makeResultMessage() -> String {
//         Проверяем, что есть доступ к статистике и лучшая игра
        guard let statisticService = statisticService, let BestGame = statisticService.bestGame else {
            assertionFailure("error message")
            return ""
        }
        
        // Формируем строки для сообщения с результатами
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)\\\(questionsAmount)"
        let bestGameInfoLine = "Рекорд: \(BestGame.correct)/\(BestGame.total)"
        + " (\(BestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"

        // Объединяем все строки в одну с переносами строк
        let resultMessage = [
            currentGameResultLine,
            totalPlaysCountLine,
            bestGameInfoLine,
            averageAccuracyLine
        ].joined(separator: "\n")

        return resultMessage
    }
    
    // Отображение результата ответа на вопрос
    func proceedWithAnswer(isCorrect: Bool) {

        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.proceedToNextQuestionOrResults()
        }
    }
}

