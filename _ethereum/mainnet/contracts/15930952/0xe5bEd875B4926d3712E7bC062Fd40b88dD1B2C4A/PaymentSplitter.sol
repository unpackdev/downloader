// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";

import "./IMMContract.sol";

contract PaymentSplitter is
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    event PaymentReceived(address from, uint256 amount);

    // contract name
    string public name;

    // recipients address
    address[] public payees;

    // recipients percentages
    uint256[] public shares;

    // max basis point
    uint128 private constant MAX_BPS = 10000;

    // template type and version
    bytes32 private constant MODULE_TYPE = bytes32("PaymentSplitter");
    uint256 private constant VERSION = 2;

    function initialize(
        address owner,
        address trustedForwarder,
        string memory _name,
        address[] memory _payees,
        uint256[] memory _shares
    ) public initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init(trustedForwarder);
        _setOwnership(owner);

        name = _name;
        payees = _payees;
        shares = _shares;
    }

    // Returns the module type of the template.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    // Returns the version of the template.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    function payeesCount() public view returns (uint256) {
        return payees.length;
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        uint256 count = payeesCount();
        for (uint256 i; i < count; i++) {
            _withdraw(payees[i], (balance * shares[i]) / MAX_BPS);
        }
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    function _setOwnership(address owner) internal onlyInitializing {
        _transferOwnership(owner);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
