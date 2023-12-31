// SPDX-License-Identifier: MIT

// Define the minimal interface for ERC20 tokens.
// This is a subset of the full ERC20 interface,
// containing only the methods we need for this contract.
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.19;

contract ethBridge {

    // Events
    // Event emitted when a deposit is made
    event Deposit(address indexed _from, bytes indexed seed, uint _value);

    // Event emitted when a user withdraws funds
    event userWithdraws(address indexed _to, uint _value,bytes seed);
    

    // State variables
    // Address of the contract owner
    address public owner;

    // Constructor
    // Initializes the contract setting the contract deployer as the owner
    // and setting the initial auth address.
    constructor() {
        owner = msg.sender;
    }

    // Mappings
    // Mapping to keep track of used seeds
    mapping(bytes => bool) public isSeedUsed;

    // Mapping to keep track of deposits made by specific users
    mapping(address => uint) public userDeposits;

    // Function to deposit funds into the contract
    function deposit(bytes calldata seed) public payable {
        // Ensure that the user is sending ether with the transaction
        require(msg.value > 0, "Must send ether with transaction");
        
        // Ensure that the seed hasn't been used before
        require(!isSeedUsed[seed], "Seed already exists");
        
        // Update the user's deposit amount
        userDeposits[msg.sender] += msg.value;

        // Update the seed status
        isSeedUsed[seed] = true;

        // Emit the Deposit event
        emit Deposit(msg.sender, seed, msg.value);
    }


    // Function to allow the contract owner to withdraw all funds from the contract
    function withdrawAll() public {
        // Ensure only the owner can call this function
        require(msg.sender == owner, "Only the contract owner can withdraw all funds");

        // Transfer all funds in the contract to the owner
        payable(owner).transfer(address(this).balance);
    }



    // Function to withdraw ERC20 tokens from the contract.
    // Can be called only by the owner.
    // _tokenAddress: The ERC20 token contract address.
    // _to: The address where the tokens will be sent.
    // _amount: The amount of tokens to send.
    function withdrawTokens(address _tokenAddress, address _to, uint256 _amount) public  {
        // Ensure only the owner can call this function
        require(msg.sender == owner, "Only the contract owner can set the auth address");
        // Validate the _to address and the _amount.
        require(_to != address(0), "Invalid address");
        require(_amount > 0, "Amount must be greater than 0");

        // Create an instance of the ERC20 token contract.
        IERC20 token = IERC20(_tokenAddress);

        // Check the contract's token balance.
        uint256 contractBalance = token.balanceOf(address(this));
        
        // Make sure the contract has enough tokens.
        require(contractBalance >= _amount, "Not enough tokens in contract");

        // Perform the token transfer.
        bool success = token.transfer(_to, _amount);

        // Make sure the transfer was successful.
        require(success, "Token transfer failed");
    }


    // function to transfer ownership of the contract
    function transferOwnership(address _newOwner) external  {
        // Ensure only the owner can call this function
        require(msg.sender == owner, "Only the contract owner can set the auth address");
        owner = _newOwner;
    }
}