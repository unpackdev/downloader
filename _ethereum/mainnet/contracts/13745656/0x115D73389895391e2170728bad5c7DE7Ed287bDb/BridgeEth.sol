// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract BridgeEth is Ownable {
    
    IERC20 public stackAddress;
    uint public nonce;
    uint public minimumDeposit;
    mapping(address => bool) public bridged;
    mapping(uint => bool) public processedNonces;
    bool public paused;
    
   
    enum Step { Deposit, Withdraw }
    event Transfer(
        address from,
        address to,
        uint amount,
        uint date,
        uint nonce,
        Step indexed step
    );

    constructor (address _stackAddress) {
        stackAddress = IERC20(_stackAddress);
        paused = false;
    }

    function deposit (uint amount) external {
        require(paused == false, 'bridging is paused');
        require(amount >= minimumDeposit, 'minimum deposit not reached');
        stackAddress.transferFrom(msg.sender, address(this), amount);
        emit Transfer(
            msg.sender,
            address(this),
            amount,
            block.timestamp,
            nonce,
            Step.Deposit
        );
        nonce++;
    }
    
    function withdraw (address to, uint amount, uint otherChainNonce) external onlyOwner {
        require(processedNonces[otherChainNonce] == false, 'transfer already processed');
        processedNonces[otherChainNonce] = true;
        stackAddress.transfer(to, amount);
        emit Transfer(
            msg.sender,
            to,
            amount,
            block.timestamp,
            otherChainNonce,
            Step.Withdraw
        );
    }

    function setMinimumBurn(uint _minimumDeposit) external onlyOwner {
        minimumDeposit = _minimumDeposit;
    }

    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
  }

}

