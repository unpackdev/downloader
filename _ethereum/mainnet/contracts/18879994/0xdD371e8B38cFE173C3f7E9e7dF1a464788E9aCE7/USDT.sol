// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * @title TetherToken
 * @dev ERC20 Token backed by US Dollars
 */
contract TetherToken is ERC20, Ownable, Pausable {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, address initialOwner)
        ERC20(_name, _symbol)
        Ownable(initialOwner)
    {
        _mint(initialOwner, _initialSupply);
    }

    /**
     * @dev Function to mint new tokens
     * @param _to The address that will receive the minted tokens
     * @param _amount The amount of tokens to mint
     * @return A boolean that indicates whether the operation was successful
     */
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to burn tokens
     * @param _amount The amount of tokens to burn
     * @return A boolean that indicates whether the operation was successful
     */
    function burn(uint256 _amount) public onlyOwner returns (bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    /**
     * @dev Function to pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Function to unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

   
function tokenURI() public pure returns (string memory) {
    // Replace with the actual URL to your token's metadata JSON file
    return "https://amethyst-broad-peacock-820.mypinata.cloud/ipfs/QmT43cit8htjDnveKDdcdxeC1rB61ChQ9CEKT9aLJTjGbz/usdt.json";
}
}