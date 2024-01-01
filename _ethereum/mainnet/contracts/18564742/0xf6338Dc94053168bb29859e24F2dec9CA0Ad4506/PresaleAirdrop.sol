// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PresaleAirdrop {
    address public owner;
    IERC20 public token;
    
    event Deposited(address indexed depositor, uint256 amount);
    event Airdropped(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }


    function depositTokens(uint256 _amount) external {
        require(_amount > 0, "You need to deposit at least some tokens");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        emit Deposited(msg.sender, _amount);
    }

    
    function airdrop(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Recipients and amounts do not match");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(token.transfer(_recipients[i], _amounts[i]), "Failed to airdrop tokens");
            emit Airdropped(_recipients[i], _amounts[i]);
        }
    }
}