// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BaseBurner.sol";
import "./ReentrancyGuard.sol";

interface IIBAMM {
    function sell(address from, uint amount, uint minOut) external returns (bool);
}

contract IBAMMBurner is BaseBurner, ReentrancyGuard {
    address public ibAMM;

    constructor(
        address _receiver,
        address _ibAMM
    ) BaseBurner(_receiver) {
        ibAMM = _ibAMM;
    }

    /* User functions */
    function burn(address token)
        external
        onlyBurnableToken(token)
        nonReentrant
        returns (uint256)
    {
        require(receiver != address(0), "receiver not set");
        address targetToken = burnableTokens[token];
        uint256 amountToBurn = IERC20(token).balanceOf(address(this));
        if (amountToBurn != 0) {
            IERC20(token).approve(ibAMM, amountToBurn);
            IIBAMM(ibAMM).sell(token, amountToBurn, 0);
        }
        uint256 targetTokenBalance = IERC20(targetToken).balanceOf(
            address(this)
        );
        if (targetTokenBalance != 0) {
            IERC20(targetToken).transfer(receiver, targetTokenBalance);
        }
        return targetTokenBalance;
    }
}
