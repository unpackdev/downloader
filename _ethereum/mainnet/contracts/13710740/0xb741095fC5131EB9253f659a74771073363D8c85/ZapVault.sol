// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./Ownable.sol";

contract ZapVault is Initializable, Ownable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool private initialized;
    IERC20Upgradeable zapToken;

    function initializeVault(address token) public initializer {
        require(!initialized, 'Vault: Instance has already been initialized');

        owner = msg.sender;

        initialized = true;

        zapToken = IERC20Upgradeable(token);
    }

    function vaultBalance() public view returns (uint256) {
        return zapToken.balanceOf(address(this));
    }

    function withdraw(uint256 value) public onlyOwner {
        require(
            zapToken.balanceOf(address(this)) >= value,
            'Vault: Withdraw amount is insufficient.'
        );

        zapToken.safeTransfer(msg.sender, value);
    }
}
