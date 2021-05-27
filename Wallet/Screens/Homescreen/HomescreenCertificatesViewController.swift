//
/*
 * Copyright (c) 2021 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Foundation

class HomescreenCertificatesViewController: ViewController {
    // MARK: - API

    public var touchedCertificateCallback: ((UserCertificate) -> Void)?

    // MARK: - Subviews

    private let stackScrollView = StackScrollView(axis: .horizontal, spacing: 0)
    private let pageControl = UIPageControl()
    private var certificateViews: [HomescreenCertificateView] = []
    private var certificateViewVerifiers: [Verifier] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupInteraction()

        UIStateManager.shared.addObserver(self) { [weak self] state in
            guard let strongSelf = self else { return }
            strongSelf.refresh(state.certificateState.certificates)
        }
    }

    private func setup() {
        view.backgroundColor = .clear

        view.addSubview(pageControl)

        pageControl.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(Padding.large + Padding.medium)
        }

        stackScrollView.scrollView.isPagingEnabled = true
        view.addSubview(stackScrollView)

        stackScrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Padding.large - HomescreenCertificateView.inset)
            make.top.equalToSuperview()
            make.bottom.equalTo(self.pageControl.snp.top).offset(-Padding.medium)
        }

        stackScrollView.clipsToBounds = false
        stackScrollView.scrollView.clipsToBounds = false
        stackScrollView.stackView.clipsToBounds = false
        stackScrollView.scrollView.delegate = self
    }

    private func setupInteraction() {
        pageControl.addTarget(self, action: #selector(handlePageChange), for: .valueChanged)
    }

    @objc private func handlePageChange() {
        let width = stackScrollView.scrollView.frame.width

        stackScrollView.scrollView.delegate = nil
        UIView.animate(withDuration: 0.3) {
            self.stackScrollView.scrollView.setContentOffset(CGPoint(x: width * CGFloat(self.pageControl.currentPage), y: 0.0), animated: false)
        } completion: { _ in
            self.stackScrollView.scrollView.delegate = self
        }
    }

    private func refresh(_ certificates: [UserCertificate]) {
        stackScrollView.removeAllViews()

        certificateViews.removeAll()

        pageControl.numberOfPages = certificates.count
        pageControl.alpha = certificates.count <= 1 ? 0.0 : 1.0

        for c in certificates {
            let v = HomescreenCertificateView(certificate: c)
            stackScrollView.addArrangedView(v)
            certificateViews.append(v)

            v.snp.makeConstraints { make in
                make.width.equalTo(stackScrollView)
            }

            v.touchUpCallback = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.touchedCertificateCallback?(c)
            }
        }

        startChecks()
    }

    private func startChecks() {
        certificateViewVerifiers = []

        for i in certificateViews {
            let v = Verifier(qrString: i.certificate.qrCode)
            v.start { [weak i] state in
                i?.state = state
            }

            certificateViewVerifiers.append(v)
        }
    }
}

extension HomescreenCertificatesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = pageControl.currentPage
        let currentScrollPage = scrollView.currentPage

        if currentPage != currentScrollPage {
            pageControl.currentPage = currentScrollPage
        }
    }
}

extension UIScrollView {
    var currentPage: Int {
        return Int((contentOffset.x + 0.5 * frame.size.width) / frame.width)
    }
}