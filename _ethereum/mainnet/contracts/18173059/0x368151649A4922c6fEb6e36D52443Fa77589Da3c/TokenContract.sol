// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract UmchainToken is ERC20, Ownable, Pausable {
    // Define the total supply for the token
    uint256 public constant INITIAL_SUPPLY = 444000000 * (10 ** 18);

    // Mapping to store authorized contract addresses
    mapping(address => bool) public authorizedContracts;

    // Event to log when a contract address is added
    event ContractAddressAdded(address indexed contractAddress);

    // Constructor function which initializes the token using the ERC20 standard from OpenZeppelin and assigns all initial tokens to the contract deployer
    constructor() ERC20("Umchain", "UMCT") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // Function to add a new smart contract address, can only be called by the owner of the contract
    function addNewContractAddress(address newContract) public onlyOwner {
        authorizedContracts[newContract] = true;
        emit ContractAddressAdded(newContract);
    }

    // Function to pause the contract, stopping all token transfers; can only be called by the owner
    function pause() public onlyOwner {
        _pause();
    }

    // Function to unpause the contract, allowing token transfers to resume; can only be called by the owner
    function unpause() public onlyOwner {
        _unpause();
    }

    // Internal function that runs before any token transfer, checking whether the contract is paused and blocking the transfer if it is
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
