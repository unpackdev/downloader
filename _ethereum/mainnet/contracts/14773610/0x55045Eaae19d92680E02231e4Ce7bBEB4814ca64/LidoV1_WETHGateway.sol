// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
pragma abicoder v1;

import "./IERC20.sol";
import "./IstETH.sol";
import "./IWETH.sol";

// EXCEPTIONS
import "./IErrors.sol";

interface ILidoV1GatewayErrors {
    error NotExpectingETHException();
}

/// @title ConvexV1ClaimZapAdapter adapter
/// @dev Implements logic for claiming all tokens for creditAccount
contract LidoV1Gateway is ILidoV1GatewayErrors {
    // Original pool contract
    IstETH public immutable stETH;
    IWETH public immutable weth;

    // Special flag to avoid accepting ETH outside of submit()
    bool internal expectingETH;

    /// @dev Constructor
    /// @param _weth WETH token address
    /// @param _stETH Address of staked ETH contract
    constructor(address _weth, address _stETH) {
        if (_weth == address(0) || _stETH == address(0))
            revert ZeroAddressException();

        stETH = IstETH(_stETH);
        weth = IWETH(_weth);
    }

    function submit(uint256 amount, address _referral)
        external
        returns (uint256 value)
    {
        IERC20(address(weth)).transferFrom(msg.sender, address(this), amount);
        _safeWithdrawWETH(amount);
        value = stETH.submit{value: amount}(_referral);
        stETH.transfer(msg.sender, stETH.balanceOf(address(this)));
    }

    function _safeWithdrawWETH(uint256 amount) internal {
        expectingETH = true;
        weth.withdraw(amount);
        expectingETH = false;
    }

    receive() external payable {
        if (!expectingETH) {
            revert NotExpectingETHException();
        }
    }
}
