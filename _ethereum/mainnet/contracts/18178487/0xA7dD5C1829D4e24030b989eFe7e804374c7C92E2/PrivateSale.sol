// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./IERC20Upgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./PrivateSaleManagement.sol";
import "./IPrivateSale.sol";

contract PrivateSale is IPrivateSale, PrivateSaleManagement {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using AddressUpgradeable for address payable;

    mapping(address => uint256) public deposits;

    /// @notice Deposit ETH into the contract
    /// @dev Only callable by addresses in the whitelist
    function deposit() public payable {
        if (!_whitelist.contains(msg.sender)) {
            revert NotWhitelisted();
        }

        if (msg.value == 0) {
            revert InvalidAmount();
        }

        if ((deposits[msg.sender] + msg.value) > _whitelist.get(msg.sender)) {
            revert CapExceeded();
        }

        deposits[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH from the contract
    /// @param to The address to send the ETH to
    /// @param amount The amount of ETH to send
    /// @dev Only callable by addresses with the OWNER_ROLE
    function withdraw(address to, uint256 amount) public {
        if (!hasRole(FUNDS_OWNER_ROLE, msg.sender)) {
            revert NotOwner();
        }

        if (amount > address(this).balance) {
            revert InvalidAmount();
        }

        payable(to).sendValue(amount);

        emit Withdraw(msg.sender, to, amount);
    }

    /// @notice Withdraw any ERC20 from the contract
    /// @param to The address to send the tokens to
    /// @dev Only callable by addresses with the OWNER_ROLE
    function sweepTokens(address token, address to) public {
        if (!hasRole(FUNDS_OWNER_ROLE, msg.sender)) {
            revert NotOwner();
        }

        IERC20Upgradeable(token).transfer(to, IERC20Upgradeable(token).balanceOf(address(this)));
    }
}
