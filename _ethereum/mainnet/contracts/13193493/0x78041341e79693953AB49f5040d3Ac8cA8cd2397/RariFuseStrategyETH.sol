// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./RariFuseStrategy.sol";
import "./IToken.sol";

// solhint-disable no-empty-blocks
/// @title Deposit ETH in a Rari Fuse Pool and earn interest.
contract RariFuseStrategyETH is RariFuseStrategy {
    constructor(
        address _pool,
        address _swapManager,
        uint256 _fusePoolId
    ) RariFuseStrategy(_pool, _swapManager, _fusePoolId) {}

    /// @dev Only receive ETH from either cToken or WETH
    receive() external payable {
        require(msg.sender == address(cToken) || msg.sender == WETH, "not-allowed-to-send-ether");
    }

    function migrateFusePool(uint256 _newPoolId) external override onlyKeeper {
        address _newCToken = _cTokenByUnderlying(_newPoolId, address(0));
        require(address(cToken) != _newCToken, "same-fuse-pool");
        require(cToken.redeem(cToken.balanceOf(address(this))) == 0, "withdraw-from-fuse-pool-failed");
        CToken(_newCToken).mint{value: address(this).balance}();
        emit FusePoolChanged(_newPoolId, address(cToken), _newCToken);
        cToken = CToken(_newCToken);
        receiptToken = _newCToken;
    }

    /**
     * @dev This hook get called after collateral is redeemed from a Rari Fuse Pool
     * Vesper deals in WETH as collateral so convert ETH to WETH
     */
    function _afterRedeem() internal override {
        TokenLike(WETH).deposit{value: address(this).balance}();
    }

    /**
     * @dev During reinvest we have WETH as collateral but Rari Fuse accepts ETH.
     * Withdraw ETH from WETH before calling mint in Rari Fuse Pool.
     */
    function _reinvest() internal override {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        if (_collateralBalance != 0) {
            TokenLike(WETH).withdraw(_collateralBalance);
            cToken.mint{value: _collateralBalance}();
        }
    }
}
