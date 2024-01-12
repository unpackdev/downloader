//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Swapper is Ownable {
    using SafeERC20 for IERC20;
     
    address private inToken;
    address private outToken;
    uint256 private ratio;
    address private receiver;

    constructor(address _inToken, address _outToken, uint256 _ratio, address _receiver) {
        inToken = _inToken;
        outToken = _outToken;
        ratio = _ratio;
        receiver = _receiver;
    }


    function exchange(uint256 amount) public {
        address sender = msg.sender;
        uint256 outAmount = amount / ratio;
        require(IERC20(outToken).balanceOf(address(this)) >= outAmount, "not enough outToken to handle the migration");
        require(IERC20(inToken).balanceOf(sender) >= amount, "sender does not have enough inToken");
        IERC20(inToken).safeTransferFrom(sender, receiver, amount);
        IERC20(outToken).safeTransfer(sender, outAmount);
    } 

    function withdrawAll() public onlyOwner {
        IERC20(outToken).safeTransfer(msg.sender, IERC20(outToken).balanceOf(address(this)));
    }
}