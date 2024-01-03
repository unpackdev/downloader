pragma solidity ^0.6.12;
import "./SafeMath.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
interface IRL3R is IERC20 {
    function burn ( uint256 amount ) external;
}

contract TokenMigrator {
    using SafeMath for uint256;

    address tokenToSwapFrom = 0xf771733a465441437EcF64FF410e261516c7c5F3;
    address tokenToSwapTo = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;//Change this to actual token to swap to when deploy
    IRL3R RL3R = IRL3R(tokenToSwapFrom);

    function swapTokens(uint256 tokensToSwap) public {
        //Transfer tokens from user to contract
        TransferHelper.safeTransferFrom(tokenToSwapFrom,tx.origin,address(this),tokensToSwap);
        //Transfer same amount of tokens from contract to user of new token
        TransferHelper.safeTransferFrom(tokenToSwapTo,address(this),tx.origin,tokensToSwap);
        //Burn the tokens we have left after swapping
        RL3R.burn(tokensToSwap);
    }

}