// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./PoWERC20.sol";

contract PoWERC20Factory {
    event PoWERC20Created(address newContractAddress);

    address[] public allContracts;

    function createPoWERC20(
        string memory name,
        string memory symbol,
        uint256 _initialSupply,
        uint8 _decimals,
        uint256 _difficulty,
        uint256 _miningLimit,
        uint256 _initialLimitPerMint
    ) public returns (address) {
        PoWERC20 newContract = new PoWERC20(
            name,
            symbol,
            _initialSupply,
            _decimals,
            _difficulty,
            _miningLimit,
            _initialLimitPerMint
        );
        allContracts.push(address(newContract));
        emit PoWERC20Created(address(newContract));
        return address(newContract);
    }

    function getTotalCreatedContracts() public view returns (uint256) {
        return allContracts.length;
    }

    function getAllContracts() public view returns (address[] memory) {
        return allContracts;
    }
}
