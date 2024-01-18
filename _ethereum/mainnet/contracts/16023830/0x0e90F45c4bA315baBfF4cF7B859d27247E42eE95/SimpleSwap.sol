// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SimpleToken.sol";

contract SimpleSwap is Ownable {
    
    IERC20 immutable public simpleToken;
        uint public tokensToTransfer;   
        bool public paused = false;

    constructor(address simpleTokenAddr) {
        simpleToken = IERC20(simpleTokenAddr);
        tokensToTransfer = 1 * 10 ** 18;
       }

    function swapTokens(address yourTokenAddress, uint yourTokenAmount) public {
        require(paused == false, "Contract is currently paused");
        IERC20 userToken = IERC20(yourTokenAddress);   
        bool sentTokenToUser = false;
        bool receivedTokenFromUser = false;
  
        uint allowance = IERC20(yourTokenAddress).allowance(msg.sender, address(this));
        require(allowance >= yourTokenAmount, "You need to set enough allowance for your tokens");        
        uint userTokenBalance = userToken.balanceOf(msg.sender);
        require (userTokenBalance > 0, "You do not hold any tokens from this tokencontract, please check the address again");

        receivedTokenFromUser = userToken.transferFrom(msg.sender,address(this), yourTokenAmount);
        require(receivedTokenFromUser, "Tokens could not be sent from the user");          
        sentTokenToUser = simpleToken.transfer(msg.sender, tokensToTransfer);
        require(sentTokenToUser, "SimpleToken could not be sent to the user");
    } 
 
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
   }
}