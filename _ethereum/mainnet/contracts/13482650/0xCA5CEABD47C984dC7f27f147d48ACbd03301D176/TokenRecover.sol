// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IBEP20.sol";

import "./Ownable.sol";

/**
 * @title TokenRecover
 * @dev Allow to recover any BEP20 sent into the contract for error
 */
contract TokenRecover is Ownable {

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverBEP20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IBEP20(tokenAddress).transfer(owner(), tokenAmount);
    }
}
