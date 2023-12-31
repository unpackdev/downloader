// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./Counters.sol";
//import "./IERC20.sol";

/**
 * @title Counters
 * @dev Provides counters that can only be incremented or decremented by one.
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: use the `current` and `decrement` functions instead.
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

/**
 * @title ERC-20 Interface
 * @dev Standard interface for ERC-20 tokens.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EtherDistributionContract {
    address public owner;
    mapping(address => uint256) private claimTimestamps;
    uint256 public claimDuration = 1 days; // 24 hours in seconds
    uint256 private minEthContract;
    uint256 public minTokenHolding;
    uint256 public minEthWithdraw;  
    address public tokenAddress; // Address of the ERC-20 token contract
    IERC20 public token; // ERC-20 token instance

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
        minEthContract = 500000000000000000;
        minTokenHolding = 4000;
        minEthWithdraw = 30000000000000000;
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    function setTokenAddress(address _newTokenAddress) external onlyOwner {
        tokenAddress = _newTokenAddress;
        token = IERC20(_newTokenAddress); // Update the ERC-20 token instance
    }

    function getMinTokenHolding() public view returns (uint256) {
        return minTokenHolding;
    }

    function setMinTokenHolding(uint256 _newMinTokenHolding) external onlyOwner {
        minTokenHolding = _newMinTokenHolding;
    }

    function getMinEth() public view returns (uint256) {
        return minEthContract;
    }

    function setMinEth(uint256 _newMinEth) external onlyOwner {
        minEthContract = _newMinEth;
    }
    
    function getMinEthWithdraw() public view returns (uint256) {
        return minEthWithdraw;
    }

    function setMinEthWithdraw(uint256 _newMinEthWithdraw) external onlyOwner {
        minEthWithdraw = _newMinEthWithdraw;
    }

    function getToken() public view returns (IERC20) {
        return token;
    }

    function getClaimDuration() public view returns (uint256) {
        return claimDuration;
    }

    function setClaimDuration(uint256 _newDuration) external onlyOwner {
        claimDuration = _newDuration;  
    }

    function claim() external {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > minEthContract, "You can't claim yet");
        require(canClaim(msg.sender), "You can't claim yet");

        uint256 userBalance = token.balanceOf(msg.sender);
        require(userBalance > minTokenHolding, "You're holding less than 4000 coins");

        uint256 totalSupply = token.totalSupply();
        uint256 percentage = (userBalance * 10000) / totalSupply;
        uint256 amountToTransfer = (contractBalance * percentage) / 10000;
        
        require(contractBalance >= minEthWithdraw , "Amount is less than the withdrawal limit");        
        require(amountToTransfer <= contractBalance, "Insufficient contract balance");

        // Mark the user as claimed
        claimTimestamps[msg.sender] = block.timestamp;

        // Transfer ether to the user
        payable(msg.sender).transfer(amountToTransfer);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

    function canClaim(address user) public view returns (bool) {
        return claimTimestamps[user] + claimDuration <= block.timestamp;
    }

    receive() external payable {
    // Ether sent to the contract's address will be stored in the contract's balance
    }
}