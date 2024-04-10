//
//  UICollectionView+MPExtension.swift
//
//  Created by Валентин Панчишен on 09.04.2024.
//  Copyright © 2024 Валентин Панчишен. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    
import UIKit

extension MPExtensionWrapper where Base: UICollectionView {
    func register<T: UICollectionViewCell>(_ type: T.Type) {
        base.register(type, forCellWithReuseIdentifier: type.mp.className)
    }
    
    func register<T: UICollectionReusableView>(_ type: T.Type) {
        base.register(type, forSupplementaryViewOfKind: type.mp.className, withReuseIdentifier: type.mp.className)
    }
    
    func cell<T: UICollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        base.dequeueReusableCell(withReuseIdentifier: type.mp.className, for: indexPath).mp.as(type)!
    }
    
    func cellItem<T: UICollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T? {
        base.cellForItem(at: indexPath)?.mp.as(type)
    }
    
    func isLastCellIn(indexPath: IndexPath) -> Bool {
        indexPath.item == (base.numberOfItems(inSection: indexPath.section) - 1)
    }
}
