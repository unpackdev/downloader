

pragma solidity ^0.8.0;

import "./IBoringERC20.sol";
import "./BoringERC20.sol";

contract BRRRedemption {

    address bridgedBRRR;
    address newBRRR;

    constructor(address _bridgedToken, address _newToken) {

        bridgedBRRR = _bridgedToken;
        newBRRR = _newToken;
    }

    //one-way redemption function for bridged BRRR
    function redeemTokens(uint amountIn) external {

        IBoringERC20 bridgedToken = IBoringERC20(bridgedBRRR);
        IBoringERC20 newToken = IBoringERC20(newBRRR);

        BoringERC20.safeTransferFrom(bridgedToken, msg.sender, address(this), amountIn);

        newToken.transfer(msg.sender, amountIn);
    }

}