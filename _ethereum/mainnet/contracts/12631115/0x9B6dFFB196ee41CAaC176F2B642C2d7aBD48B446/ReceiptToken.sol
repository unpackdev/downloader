// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

// This contract is used for printing receipt tokens
// Whenever someone joins a pool, a receipt token will be printed for that person
contract ReceiptToken is ERC20, Ownable {
    ERC20 public underlyingToken;
    address public underlyingStrategy;

    constructor(address underlyingAddress, address strategy)
        ERC20(
            string(abi.encodePacked("pAT-", ERC20(underlyingAddress).name())),
            string(abi.encodePacked("pAT-", ERC20(underlyingAddress).symbol()))
        )
    {
        underlyingToken = ERC20(underlyingAddress);
        underlyingStrategy = strategy;
    }

    /**
     * @notice Mint new receipt tokens to some user
     * @param to Address of the user that gets the receipt tokens
     * @param amount Amount of receipt tokens that will get minted
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn receipt tokens from some user
     * @param from Address of the user that gets the receipt tokens burne
     * @param amount Amount of receipt tokens that will get burned
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
