// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./UpfireToken.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract UpfireSwap is Ownable {
    bool public rateFrozen;
    uint256 public rate;
    IERC20 public UFR;
    UpfireToken public UPR;

    event SwapRate(uint256 amount);
    event Swap(address account, uint256 input, uint256 output);

    constructor(IERC20 _UFR, UpfireToken _UPR) public {
        UFR = _UFR;
        UPR = _UPR;
        rate = 10;
    }

    function setSwapRate(uint256 newRate) public onlyOwner {
        require(!rateFrozen, "SwapRate is frozen");
        require(newRate > 0, "SwapRate must more than 0");
        rate = newRate;
        emit SwapRate(newRate);
    }

    function freezeSwapRate() public onlyOwner {
        rateFrozen = true;
    }

    function swap(uint256 amount) public {
        require(UFR.transferFrom(msg.sender, address(this), amount) == true, "Transfer error");
        uint256 outputAmount = amount * rate;
        UPR.mint(msg.sender, outputAmount);
        emit Swap(msg.sender, amount, outputAmount);
    }

    function withdrawUFR(address receiver, uint256 amount) public onlyOwner {
        require(UFR.transfer(receiver, amount) == true, "Withdraw error");
    }
}