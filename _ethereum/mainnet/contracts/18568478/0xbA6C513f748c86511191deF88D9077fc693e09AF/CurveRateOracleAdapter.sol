/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2023 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./AggregatorInterface.sol";

/**
 * @dev
 *
 * CurveRateOracleAdapter contract, which transform Chainlink oracle latest answer to Curve 18 decimals standards.
 *
 */
contract CurveRateOracleAdapter is Ownable {

    address public oracle;

    constructor(address _oracle) Ownable() {
        oracle = _oracle;
    }

    /**
     * @dev Adjust precision of underlying 8 decimals Chainlink oracle to 18 decimals
     *
     * * @return Scaled response from underlying oracle
     */
    function latestAnswer() external view returns(int256) {
        return AggregatorInterface(oracle).latestAnswer() * 1e10;
    }

    /**
     * @dev Updates oracle, callable only by owner
     * 
     * @param _oracle    New oracle address
     */
    function updateOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }
}
