// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./EnumerableUintToUintMapUpgradeable.sol";
import "./DigitsOfUint.sol";

contract Fiat24PriceList is Initializable, AccessControlUpgradeable {
    using EnumerableUintToUintMapUpgradeable for EnumerableUintToUintMapUpgradeable.UintToUintMap;
    using DigitsOfUint for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    EnumerableUintToUintMapUpgradeable.UintToUintMap private _priceList;
    function initialize() public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
        _priceList.set(1,27993600);
        _priceList.set(2, 4665600);
        _priceList.set(3, 777600);
        _priceList.set(4, 129600);
        _priceList.set(5, 21600);
        _priceList.set(6, 3600);
        _priceList.set(7, 600);
        _priceList.set(8, 100);
    }

    function getPrice(uint256 accountNumber) external view returns(uint256) {
        if(!_priceList.contains(accountNumber.numDigits())) {
            return 0;
        } else {
            return _priceList.get(accountNumber.numDigits());
        }
    }

    function setPrice(uint256 digits, uint256 price) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");
        _priceList.set(digits, price);
    }
}
