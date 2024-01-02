// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// ERC20 Interface
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract NEFTokenReceiver {
    IERC20 public nefToken;
    address public owner;

    address private constant NEF_TOKEN = 0xDa6593dBF7604744972B1B6C6124cB6981b3c833; 

    event buyPokerChipsEvent(address indexed user, uint256 amount, uint256 chips, uint256 key);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensTransferred(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // The address of the NEF token contract and setting the owner
    constructor() {
        nefToken = IERC20(NEF_TOKEN);
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // Accept NEF tokens from a user
    function buyPokerChips(uint256 amount, uint256 chips, uint256 key) external {
        // Transfer the NEF tokens from the sender to this contract
        bool sent = nefToken.transferFrom(msg.sender, address(this), amount);
        require(sent, "Token transfer failed");
        
        emit buyPokerChipsEvent(msg.sender, amount, chips, key);
    }

    // Check the balance of NEF tokens held by this contract
    function getNEFBalance() public view returns (uint256) {
        return nefToken.balanceOf(address(this));
    }

    // Transfer NEF tokens to another address
    function transferNEFTokens(address to, uint256 amount) external onlyOwner {
        require(nefToken.transfer(to, amount), "Transfer failed");
        emit TokensTransferred(to, amount);
    }

    // Transfer ownership to a new address
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}