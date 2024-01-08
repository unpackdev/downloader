// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./LPToken.sol";

// @title core application logic for vault
// @notice to be inherited by the implementation contract for added functionality
// @dev deposit/ withdraw hooks and calculation must be overridden
abstract contract XPNVault {
    using SafeERC20 for IERC20;

    // @notice LP tokens should track Enzyme shares 1-1 through deposit and withdraw
    LPToken public lptoken;

    event Deposit(address indexed _depositor, uint256 _amount);
    event Withdraw(
        address indexed _withdrawer,
        address[] _payoutAssets,
        uint256[] _payoutAmount
    );

    constructor(string memory _lpname, string memory _lpsymbol) {
        lptoken = new LPToken(_lpname, _lpsymbol);
    }

    // @notice deposit denominated asset into the contract
    // @param _amount amount to be deposited
    // @dev denominated asset must be approved first
    // @return minted amount of LP tokens minted
    function _deposit(uint256 _amount) internal returns (uint256 minted) {
        IERC20 denomAsset = IERC20(_getDenomAssetAddress());
        require(_amount > 0, "Vault: _amount cant be zero");
        uint256 before = denomAsset.balanceOf(_getSharesAddress());
        require(
            denomAsset.balanceOf(msg.sender) >= _amount,
            "Vault: not enough balance to deposit"
        );
        denomAsset.safeTransferFrom(msg.sender, address(this), _amount);
        minted = _depositHook(_amount);
        require(
            denomAsset.balanceOf(_getSharesAddress()) >= (before + _amount),
            "Vault: incorrect balance after deposit"
        );
        lptoken.mint(msg.sender, minted);
        emit Deposit(msg.sender, _amount);
        return minted;
    }

    // @notice redeem LP token share for denominated asset
    // @notice currently withdraw basket of tokens to user
    // @param _amount amount of LP token to be redeemed
    // @dev LP token must be approved first
    // @return payoutAssets array of the asset to payout
    // @return payoutAmounts array of the amount to payout
    function _withdraw(uint256 _amount)
        internal
        returns (address[] memory payoutAssets, uint256[] memory payoutAmounts)
    {
        require(_amount > 0, "Vault: _amount cant be zero");
        require(
            lptoken.balanceOf(msg.sender) >= _amount,
            "Vault: not enough lptoken to withdraw"
        );
        lptoken.burn(msg.sender, _amount); // burn user's lp balance without intermediate transferFrom
        (payoutAssets, payoutAmounts) = _withdrawHook(_amount);
        bool result = _doWithdraw(msg.sender, payoutAssets, payoutAmounts);
        require(result, "Vault: unsuccessful transfer to withdrawer");
        return (payoutAssets, payoutAmounts);
    }

    // @notice redeem enzyme transaction fee enzyme vault to admin address
    // @param _feeManager address of the enzyme fee manager contract
    // @param _fees array of fee contract addresses
    // @return payoutAssets array of the asset to payout
    // @return payoutAmounts array of the amount to payout
    // @dev fees are in the form of enzyme shares inflation, the difference in total shares supply and withdraw
    function _redeemFees(address _feeManager, address[] calldata _fees)
        internal
        returns (address[] memory payoutAssets, uint256[] memory payoutAmounts)
    {
        _redeemFeesHook(_feeManager, _fees);
        address shares = _getSharesAddress();
        // the redeemFeesHook is expected to inflate the enzyme shares of the enzyme vault manager (this contract)

        // at this point, the exponent vault holds shares of its users as well as shares representing accrued fees.
        // the difference between this contract's enzyme shares and exponent vault tokens represents
        // the amount of fees owed to exponent vault's admin
        uint256 collectedFees = IERC20(shares).balanceOf(address(this)) -
            lptoken.totalSupply();
        require(collectedFees > 0, "_redeemFees: no fee shares available");
        (payoutAssets, payoutAmounts) = _withdrawHook(collectedFees);
        bool result = _doWithdraw(
            _getAdminAddress(),
            payoutAssets,
            payoutAmounts
        );
        require(result, "Vault: unsuccessful redemption");
    }

    // @dev transfer each asset back to recipient, this is one additional transfer for each asset on top of Enzyme's
    function _doWithdraw(
        address recipient,
        address[] memory payoutAssets,
        uint256[] memory payoutAmounts
    ) private returns (bool) {
        for (uint8 i = 0; i < payoutAssets.length; i++) {
            IERC20(payoutAssets[i]).safeTransfer(recipient, payoutAmounts[i]);
        }
        // won't verify that that payout assets is calculated correctly due to gas cost of tracking multiple payouts
        emit Withdraw(recipient, payoutAssets, payoutAmounts);
        return true;
    }

    // @notice internal functions to be overriden by implementor contract

    // @notice deposit asset into enzyme contract, returns the amount of minted shares
    function _depositHook(uint256 _amount) internal virtual returns (uint256) {}

    // @notice get the enzyme shares address
    function _getSharesAddress() internal view virtual returns (address) {}

    // @notice get the denominated asset address
    function _getDenomAssetAddress() internal virtual returns (address) {}

    // @notice get the admin address
    function _getAdminAddress() internal virtual returns (address) {}

    // @notice withdraw assets from enzyme contract
    function _withdrawHook(uint256 _amount)
        internal
        virtual
        returns (address[] memory, uint256[] memory)
    {}

    // @notice redeem fees from enzyme
    function _redeemFeesHook(address _feeManager, address[] memory _fees)
        internal
        virtual
    {}
}
