import UIKit

// MARK: - MovieQuizViewController

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {

    // MARK: - IBOutlet

    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Private variables
    
    private var presenter: MovieQuizPresenter!
    private var alertPresenter: AlertPresenter?
    private var isButtonsEnabled = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = MovieQuizPresenter(viewController: self)
        alertPresenter = AlertPresenterImpl(viewController: self)
        showLoadingIndicator()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Public Methods

    func showCurrentQuestion(step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
    }

    func showQuizResults(result: QuizResultsViewModel) {
        let message = presenter.makeResultMessage()

        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: message,
            buttonText: result.buttonText) { [weak self] in
               self?.presenter.restartGame()
           }
       alertPresenter?.show(alertModel: alertModel)
   }

    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }

    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        if isButtonsEnabled {
            presenter.yesButtonClicked()
            disableButtons()
        }
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        if isButtonsEnabled {
            presenter.noButtonClicked()
            disableButtons()
        }
    }
    
    private func disableButtons() {
        isButtonsEnabled = false
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    
    func enableButtons() {
        isButtonsEnabled = true
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    
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
