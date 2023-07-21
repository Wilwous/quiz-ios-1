import UIKit

// MARK: - MovieQuizViewController

final class MovieQuizViewController: UIViewController {

    // MARK: - IBOutlet

    @IBOutlet private weak var noButton: UIButton!  // Кнопка "Нет"
    @IBOutlet private weak var yesButton: UIButton!  // Кнопка "Да"
    @IBOutlet private weak var imageView: UIImageView!  // Изображение вопроса
    @IBOutlet private weak var textLabel: UILabel!  // Текст вопроса
    @IBOutlet private weak var counterLabel: UILabel!  // Счетчик текущего вопроса
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!  // Индикатор загрузки

    // MARK: - Private variables
    
    private var presenter: MovieQuizPresenter!
    private var alertPresenter: AlertPresenter?  // Презентер для отображения алертов
    private var isButtonsEnabled = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MovieQuizPresenter(viewController: self)
        
        // Инициализация презентера алертов
        alertPresenter = AlertPresenterImpl(viewController: self)
        
        // Показ индикатора загрузки
        showLoadingIndicator()
        activityIndicator.hidesWhenStopped = true  // Скрытие индикатора загрузки при остановке
        activityIndicator.startAnimating()  // Запуск анимации индикатора загрузки
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent  // Установка стиля статус-бара
    }
    
    // MARK: - Public Methods
    
    // Отображение текущего вопроса
    func showCurrentQuestion(step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
    }

    // Отображение результатов квиза
    func showQuizResults(result: QuizResultsViewModel) {
        let message = presenter.makeResultMessage()

        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: message,
            buttonText: result.buttonText) { [weak self] in
               self?.presenter.restartGame()
           }
       alertPresenter?.show(alertModel: alertModel)  // Отображение алерта с результатами
   }

    // Подсветка рамки изображения вопроса в зависимости от правильности ответа
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }

    // Показ индикатора загрузки
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    // Скрытие индикатора загрузки
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    // Обработчик нажатия кнопки "Да"
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        if isButtonsEnabled {
            presenter.yesButtonClicked()
            disableButtons()
        }
    }
    
    // Обработчик нажатия кнопки "Нет"
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        if isButtonsEnabled {
            presenter.noButtonClicked()
            disableButtons()
        }
    }
    
    // Отключение кнопок для предотвращения повторного нажатия до завершения вопроса
    private func disableButtons() {
        isButtonsEnabled = false
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    
    // Включение кнопок после завершения текущего вопроса
    func enableButtons() {
        isButtonsEnabled = true
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    
    // Отображение ошибки сети
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        let alertModel = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }

            self.presenter.restartGame()
            self.presenter.switchToNextQuestion()
            self.showLoadingIndicator()
        }

        alertPresenter?.show(alertModel: alertModel)
    }
    
    func didFailToLoadImage(with error: Error) {
        presenter.didFailToLoadImage(with: error)
    }
}
