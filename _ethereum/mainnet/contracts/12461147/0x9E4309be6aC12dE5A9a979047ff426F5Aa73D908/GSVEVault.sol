// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

/**
* @dev This smart contract is a "vault"
* it holds onto the fees that the protocol has gathered
* and any GSVE that is to be rewarded from protocol iteraction
*/
contract GSVEVault is Ownable{
    function transferToken(address token, address recipient, uint256 amount) public onlyOwner{
        IERC20(token).transfer(recipient, amount);
    }
}
