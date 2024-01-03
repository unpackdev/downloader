pragma solidity ^0.6.12;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./TransferHelper.sol";

interface IRL3R is IERC20{
    function burn ( uint256 amount ) external;
}

contract TokenMigratorCustomizable is Ownable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bool BurnOnSwap = true;
    bool SwapPaused = true;

    uint256 public totalSwapped = 0;

    IRL3R public RL3R = IRL3R(address(0));
    IRL3R public RLR = IRL3R(address(0));

    function SetOriginToken(address token) public onlyOwner{
        RL3R = IRL3R(token);
    }

    function SetSwapToken(address token) public onlyOwner{
        RLR = IRL3R(token);
    }

    function setBurn(bool fBurn) public onlyOwner{
        BurnOnSwap = fBurn;
    }

    function swapTokens(uint256 tokensToSwap) public {
        require((!SwapPaused || _msgSender() == owner()),"Swap is paused");
        //Transfer tokens from user to contract
        RL3R.transferFrom(msg.sender,address(this),tokensToSwap);
        require(getTokenBalance(address(RL3R)) == tokensToSwap,"Dont have enough tokens sent");

        //Transfer same amount of tokens from contract to user of new token
        RLR.transfer(msg.sender,tokensToSwap);
        if(BurnOnSwap){
            //Burn the tokens we have left after swapping
            RL3R.burn(tokensToSwap);
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