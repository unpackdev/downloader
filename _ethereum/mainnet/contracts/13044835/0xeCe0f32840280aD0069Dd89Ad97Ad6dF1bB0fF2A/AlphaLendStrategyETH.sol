// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/* solhint-disable no-empty-blocks */

import "./AlphaLendStrategy.sol";
import "./IToken.sol";

/// @title Deposit ETH in Alpha and earn interest.
contract AlphaLendStrategyETH is AlphaLendStrategy {
    string public constant NAME = "Alpha-Lend-Strategy-ETH";
    string public constant VERSION = "3.0.0";
    TokenLike internal constant WETH_TOKEN = TokenLike(WETH);

    // ibETHv2 = 0xeEa3311250FE4c3268F8E684f7C87A82fF183Ec1
    constructor(address _pool, address _swapManager)
        AlphaLendStrategy(_pool, _swapManager, 0xeEa3311250FE4c3268F8E684f7C87A82fF183Ec1)
    {}

    receive() external payable {
        require((_msgSender() == address(safeBox)) || (_msgSender() == WETH), "invalid-eth-sender");
    }

    function _setupCheck(address _pool) internal view override {
        require(address(IVesperPool(_pool).token()) == WETH, "u-token-mismatch");
    }

    function claimUTokenReward(uint256 amount, bytes32[] memory proof) external override onlyKeeper {
        safeBox.claim(amount, proof);
        uint256 uBalance = address(this).balance;
        WETH_TOKEN.deposit{value: uBalance}();
        IVesperPool(pool).reportEarning(uBalance, 0, 0);
    }

    /// @notice Deposit collateral in Alpha
    function _reinvest() internal override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            WETH_TOKEN.withdraw(_collateralBalance);
            safeBox.deposit{value: _collateralBalance}();
        }
    }

    function _afterDownstreamWithdrawal() internal override {
        WETH_TOKEN.deposit{value: address(this).balance}();
    }
}
