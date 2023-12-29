// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Ownable {
    // Only use HD Managed wallet for this owner address.
    // This ensures enhanced security and key management.
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}

contract NativeBridgeFromEthereum is Ownable {
    IERC20 private _APM = IERC20(0xC8C424B91D8ce0137bAB4B832B7F7D154156BA6c);

    // Events for logging
    event SentToRAPM(address indexed sender, uint256 amount);
    event RetrievedFromRAPM(address indexed to, uint256 amount);
    event EmergencyERC20Recovered(address indexed token, uint256 amount);

    // Getter for the APM address
    function getAPMAddress() public view returns (address) {
        return address(_APM);
    }

    // Function to transfer ETH to the RAPM chain
    // Note: Reentrancy attack protection is not necessary here as
    // it is handled by external validation nodes.
    function sendToRAPM(uint256 amount) public {
        uint256 allowance = _APM.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient allowance. Please approve tokens before transferring.");

        require(_APM.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit SentToRAPM(msg.sender, amount);
    }

    // Function to return assets from RAPM to the Ethereum chain
    function retrieveFromRAPM(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address: zero address");
        require(_APM.transfer(to, amount), "Transfer failed");
        emit RetrievedFromRAPM(to, amount);
    }

    // Function to recover ERC20 tokens
    function emergencyRecoverERC20(IERC20 token, uint256 amount) public onlyOwner {
        require(address(token) != address(0), "Invalid token: zero address");
        require(token.transfer(msg.sender, amount), "Recovery failed");
        emit EmergencyERC20Recovered(address(token), amount);
    }
}