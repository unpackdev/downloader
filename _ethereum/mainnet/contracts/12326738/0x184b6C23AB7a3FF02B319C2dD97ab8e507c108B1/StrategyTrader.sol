// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";

import "./ISynthetix.sol";
import "./IUni.sol";
import "./ICurve.sol";

import "./IERC20.sol";

contract StrategyTrader is Ownable {
    address public constant synthetix = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address public constant uni = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant curveEURS = 0x0Ce6a5fF5217e38315f87032CF90686C96627CAA;
    address public constant curveSUSD = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;

    address public constant EURS = 0xdB25f211AB05b1c97D595516F45794528a807ad8; 
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address public constant SEUR = 0xD71eCFF9342A5Ced620049e616c5035F1dB98620;

    bytes32 public constant SUSDkey = 0x7355534400000000000000000000000000000000000000000000000000000000;
    bytes32 public constant SEURkey = 0x7345555200000000000000000000000000000000000000000000000000000000;

    constructor() public {
        IERC20(SEUR).approve(curveEURS, type(uint256).max);
        IERC20(EURS).approve(uni, type(uint256).max);
        IERC20(USDC).approve(curveSUSD, type(uint256).max);
    }

    function execute(
        uint256 SEURtoTrade,
        uint256 minEURrate,
        uint256 minSEURout
    )
        external
        onlyOwner
    {
        uint256 initialSeurBalance = IERC20(SEUR).balanceOf(address(this));

        ICurve(curveEURS).exchange(1, 0, SEURtoTrade, 0); // SEUR => EURS
        address[] memory path = new address[](2);
        path[0] = EURS;
        path[1] = USDC;

        IUni(uni).swapExactTokensForTokens(IERC20(EURS).balanceOf(address(this)), minEURrate * IERC20(EURS).balanceOf(address(this)) / 100, path, address(this), 9999999999);
        ICurve(curveSUSD).exchange(1, 3, IERC20(USDC).balanceOf(address(this)), 0); // USDC => SUSD
        ISynthetix(synthetix).exchange(SUSDkey, IERC20(SUSD).balanceOf(address(this)), SEURkey);

        require(minSEURout <= initialSeurBalance - IERC20(SEUR).balanceOf(address(this)), "Not Enough");
    }

    function harvest(address to) external onlyOwner {
        IERC20(SEUR).transfer(to, IERC20(SEUR).balanceOf(address(this)));
    }
}