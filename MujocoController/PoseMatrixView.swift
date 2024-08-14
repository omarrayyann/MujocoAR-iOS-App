import UIKit

class PoseMatrixView: UIView {

    private var matrixLabels: [[UILabel]] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMatrix()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMatrix()
    }

    private func setupMatrix() {
        let outerStackView = UIStackView()
        outerStackView.axis = .horizontal
        outerStackView.alignment = .fill
        outerStackView.spacing = 8


        let matrixStackView = UIStackView()
        matrixStackView.axis = .vertical
        matrixStackView.distribution = .fillEqually
        matrixStackView.alignment = .fill
        matrixStackView.spacing = 8

        for _ in 0..<4 {
            var rowLabels: [UILabel] = []
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.alignment = .fill
            rowStackView.spacing = 8

            for _ in 0..<4 {
                let label = UILabel()
                label.textAlignment = .center
                label.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular) // Use monospaced font
                label.text = "0.0" // Default text
                rowLabels.append(label)
                rowStackView.addArrangedSubview(label)
            }

            matrixLabels.append(rowLabels)
            matrixStackView.addArrangedSubview(rowStackView)
        }

        outerStackView.addArrangedSubview(matrixStackView)

        

        addSubview(outerStackView)
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            outerStackView.topAnchor.constraint(equalTo: self.topAnchor),
            outerStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            outerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            outerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    func updateMatrix(with values: [[Float]]) {
        for (i, row) in values.enumerated() {
            for (j, value) in row.enumerated() {
                matrixLabels[i][j].text = String(format: "%.2f", value)
            }
        }
    }
}
