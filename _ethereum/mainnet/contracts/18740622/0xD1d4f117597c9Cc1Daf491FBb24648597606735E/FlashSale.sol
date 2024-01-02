// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";

contract FlashSale {
    address public owner;
    address public multisig;
    address public usdc;
    uint256 public remainingAmount = 2000000000000;
    mapping(address => uint) public contributed;
    address[] public contributors;

    uint256 public timeStart = 1702033200;

    uint public price = 230000;

    event Contribution(address user, uint amount);
    
    constructor() {
        owner = msg.sender;
        multisig = 0x7ae230223c4803961A9F41B960cA6e31095706Ed;
        usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    
    function contribute(uint _amountUSDC) external {
        require(block.timestamp >= timeStart && block.timestamp <= (timeStart + 1 days));
        require (_amountUSDC >= 500e6, "Contribution Too Low");
        require (_amountUSDC <= 25000e6, "Contribution Too High");
        
        uint256 lndxAmount = _amountUSDC / price * 1e6;
        require((remainingAmount - lndxAmount) >=0, "LNDX limit exceeded");
        IERC20(usdc).transferFrom(msg.sender, address(this), _amountUSDC);
        
        remainingAmount -= lndxAmount;
        contributed[msg.sender] += _amountUSDC;
        contributors.push(msg.sender); // may be duplicate addresses
        emit Contribution(msg.sender, _amountUSDC);
    }

   
    function updateToken(address _usdc) external {
        require(msg.sender == owner, "only owner has access");
        usdc = _usdc;
    }

    // multisig functions
    function updateMultisig(address _multisig) external {
        require(msg.sender == multisig, "only multisig has access");
        multisig = _multisig;
    }

     function updateStartDate(uint256 _timeStart) external {
        require (timeStart > block.timestamp, "Sale have been already started");
        require (_timeStart > block.timestamp, "Time start should be in the future");
        require(msg.sender == multisig || msg.sender == owner, "only multisig and owner has access");
        timeStart = _timeStart;
    }

    function claimToken(IERC20 _token) external {
        require(msg.sender == multisig || msg.sender == owner, "only multisig and owner has access");
        uint balance = _token.balanceOf(address(this));
        _token.transfer(multisig, balance);
    }

    function claimETH() external {
        require(msg.sender == multisig || msg.sender == owner, "only multisig and owner has access");
        payable(multisig).transfer(address(this).balance);
    }

}