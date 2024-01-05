//SPDX-License-Identifier: MIT
/*
* MIT License
* ===========
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.6.2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ITreasury.sol";
import "./ISwapRouter.sol";


contract Treasury is Ownable, ITreasury {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public override defaultToken;
    SwapRouter public swapRouter;
    address public ecoFund;
    address public gov;
    address internal govSetter;

    mapping(address => uint256) public ecoFundAmts;

    // 1% = 100
    uint256 public constant MAX_FUND_PERCENTAGE = 1500; // 15%
    uint256 public constant PERCENTAGE_PRECISION = 10000; // 100%
    uint256 public fundPercentage = 500; // 5%
    
    
    constructor(SwapRouter _swapRouter, IERC20 _defaultToken, address _ecoFund) public {
        swapRouter = _swapRouter;
        defaultToken = _defaultToken;
        ecoFund = _ecoFund;
        govSetter = msg.sender;
    }

    function setGov(address _gov) external {
        require(msg.sender == govSetter, "not authorized");
        gov = _gov;
        govSetter = address(0);
    }

    function setSwapRouter(SwapRouter _swapRouter) external onlyOwner {
        swapRouter = _swapRouter;
    }

    function setEcoFund(address _ecoFund) external onlyOwner {
        ecoFund = _ecoFund;
    }

    function setFundPercentage(uint256 _fundPercentage) external onlyOwner {
        require(_fundPercentage <= MAX_FUND_PERCENTAGE, "exceed max percent");
        fundPercentage = _fundPercentage;
    }

    function balanceOf(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this)).sub(ecoFundAmts[address(token)]);
    }

    function deposit(IERC20 token, uint256 amount) external override {
        // portion allocated to ecoFund
        ecoFundAmts[address(token)] = amount.mul(fundPercentage).div(PERCENTAGE_PRECISION);
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    // only default token withdrawals allowed
    function withdraw(uint256 amount, address withdrawAddress) external override {
        require(msg.sender == gov, "caller not gov");
        require(balanceOf(defaultToken) >= amount, "insufficient funds");
        defaultToken.safeTransfer(withdrawAddress, amount);
    }

    function convertToDefaultToken(address[] calldata routeDetails, uint256 amount) external {
        require(routeDetails[0] != address(defaultToken), "src can't be defaultToken");
        require(routeDetails[routeDetails.length - 1] == address(defaultToken), "dest not defaultToken");
        IERC20 srcToken = IERC20(routeDetails[0]);
        require(balanceOf(srcToken) >= amount, "insufficient funds");
        if (srcToken.allowance(address(this), address(swapRouter)) <= amount) {
            srcToken.safeApprove(address(swapRouter), uint256(-1));
        }
        uint[] memory swappedAmounts = swapRouter.swapExactTokensForTokens(
            amount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );
        require(swappedAmounts.length != 0, "Swap failed");
    }

    function withdrawEcoFund(IERC20 token, uint256 amount) external {
        ecoFundAmts[address(token)] = ecoFundAmts[address(token)].sub(amount);
        token.safeTransfer(ecoFund, amount);
    }
}