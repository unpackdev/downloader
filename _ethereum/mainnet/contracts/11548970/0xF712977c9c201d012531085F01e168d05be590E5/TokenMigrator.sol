// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./TransferHelper.sol";

interface IToken is IERC20{
    function burn ( uint256 amount ) external;
}

contract TokenMigratorCustomizable is Ownable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bool BurnOnSwap = true;
    bool SwapPaused = true;

    uint256 public totalSwapped = 0;

    IToken public OriginToken = IToken(address(0));
    IToken public DestToken = IToken(address(0));

    constructor(address origin,address dest) public{
        OriginToken = IToken(origin);
        DestToken = IToken(dest);
    }

    function SetOriginToken(address token) public onlyOwner{
        OriginToken = IToken(token);
    }

    function SetSwapToken(address token) public onlyOwner{
        DestToken = IToken(token);
    }

    function setBurn(bool fBurn) public onlyOwner{
        BurnOnSwap = fBurn;
    }

    function swapTokens(uint256 tokensToSwap) public {
        require((!SwapPaused || _msgSender() == owner()),"Swap is paused");
        //Transfer tokens from user to contract
        OriginToken.transferFrom(msg.sender,address(this),tokensToSwap);
        require(getTokenBalance(address(OriginToken)) == tokensToSwap,"Dont have enough tokens sent");

        //Transfer same amount of tokens from contract to user of new token
        DestToken.transfer(msg.sender,tokensToSwap);
        if(BurnOnSwap){
            //Burn the tokens we have left after swapping
            OriginToken.burn(tokensToSwap);
        }
        //Update total swapped figure
        totalSwapped = totalSwapped.add(tokensToSwap);
    }

    function unpauseSwap() public onlyOwner {
        SwapPaused = false;
    }

    function pauseSwap() public onlyOwner {
        SwapPaused = true;
    }

    function recoverERC20(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, getTokenBalance(tokenAddress));
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}