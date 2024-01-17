// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";

contract ExchangeOperatorAddresses is Ownable {
    // mapping of operator addresses to exchanges represented by a uint256 integer
    mapping(address => uint256) public operatorAddresses;
    // allows for specifying an external smart contract address that will be used to check exchange operator addresses
    address public externalAddressListContract;

    constructor() {
    }

    function addBlocklistAddresses(uint256 exchange, address[] calldata blocklistAddresses) public onlyOwner {
        for (uint256 i = 0; i < blocklistAddresses.length; i++) {
            operatorAddresses[blocklistAddresses[i]] = exchange;
        }
    }

    function updateExternalAddressListContract(address _externalAddressListContractAddress) public onlyOwner {
        externalAddressListContract = _externalAddressListContractAddress;
    }

    function operatorAddressToExchange(address operatorAddress) public view returns (uint256) {
        if (externalAddressListContract != address(0)) {
            return IExchangeOperatorAddressList(externalAddressListContract).operatorAddressToExchange(operatorAddress);
        } else {
            return operatorAddresses[operatorAddress];
        }
    }
}

interface IExchangeOperatorAddressList {
    function operatorAddressToExchange(address operatorAddress) external view returns (uint256);
}