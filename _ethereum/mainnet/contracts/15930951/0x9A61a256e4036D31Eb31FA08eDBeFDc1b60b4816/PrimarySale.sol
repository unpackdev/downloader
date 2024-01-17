// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract PrimarySale is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // recipients addresses
    address[] public paymentAddresses;

    // recipients percentages
    uint256[] public paymentPercentages;

    // max basis point
    uint128 private constant MAX_BPS = 10000;

    function __PrimarySale_init(
        address[] memory _payees,
        uint256[] memory _shares
    ) internal onlyInitializing {
        paymentAddresses = _payees;
        paymentPercentages = _shares;
    }

    function paymentAddressesCount() external view returns (uint256) {
        return paymentAddresses.length;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;

        for (uint256 i; i < paymentAddresses.length; i++) {
            _withdraw(
                paymentAddresses[i],
                (contractBalance * paymentPercentages[i]) / MAX_BPS
            );
        }
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Withdrawal failed");
    }
}
