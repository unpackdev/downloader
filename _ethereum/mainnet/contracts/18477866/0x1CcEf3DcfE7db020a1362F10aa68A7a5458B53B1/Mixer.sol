// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeMath.sol";
import "./IWallet.sol";

contract Mixer {
    using SafeMath for uint;

    address public walletA;
    address public walletB;
    uint public divRate;
    uint public delayTime;
    uint public startTime;
    bool public isSplited = false;
    bool public isDelayed = false;

    constructor(
        address _walletA, 
        address _walletB, 
        uint _divRate,
        uint _delayTime
    ) {
        walletA = _walletA;
        walletB = _walletB;
        divRate = _divRate;
        delayTime = _delayTime;

        startTime = block.timestamp;
    }

    function split() external {
        require(isSplited == false, "Already called");
        uint amount = address(this).balance;
        require(amount > 0, "Token amount must be not zero");
        
        // uint amountA = amount.mul(divRate).div(1000);
        // uint amountB = amount.sub(amountA);
        isSplited = true;

        payable(walletA).transfer(amount);
        // payable(walletB).transfer(amountB);
        IWallet(walletA).transfer();
    }

    function delay() external {
        require(block.timestamp > startTime + delayTime, "Already did");
        require(isDelayed == false, "Already called");
        isDelayed = true;

        IWallet(walletB).transfer();
    }

    receive() external payable {}
    // // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(address _user) external {
        uint amount = address(this).balance;
        payable(_user).transfer(amount);
    }
}
