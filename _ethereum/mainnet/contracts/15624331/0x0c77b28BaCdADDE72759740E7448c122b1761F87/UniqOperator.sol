// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IUniqOperator.sol";

contract UniqOperator is Ownable, IUniqOperator {
    mapping(uint256 => mapping(address => bool)) public override isOperator;
    address[] public override uniqAddresses;
    event setOperator(
        uint256 indexed operatorType,
        address indexed addr,
        bool indexed status
    );

    constructor(address treasuryAddress) {
        uniqAddresses.push(treasuryAddress);
    }

    function editStatusesForOperators(
        address[] memory addresses,
        bool[] memory statuses,
        uint256[] memory operatorTypes
    ) external onlyOwner {
        uint256 len = addresses.length;
        require(
            len == statuses.length && len == operatorTypes.length,
            "Len err"
        );
        for (uint256 i = 0; i < len; i++) {
            isOperator[operatorTypes[i]][addresses[i]] = statuses[i];
            emit setOperator(operatorTypes[i], addresses[i], statuses[i]);
        }
    }

    function lenOfAddresses() external view returns (uint256) {
        return uniqAddresses.length;
    }

    function setAddressForIndex(uint256 index, address newAddress)
        external
        onlyOwner
    {
        if (index >= uniqAddresses.length) {
            uniqAddresses.push(newAddress);
            return;
        }
        uniqAddresses[index] = newAddress;
    }
}
