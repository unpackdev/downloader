// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title Reclaimer
 * @author WALLEXTRUST
 * @dev Allows owner to claim ERC20 tokens ot ETH sent to this contract.
 */
abstract contract Claimer is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev send all token balance of an arbitrary erc20 token
     * in the contract to another address
     * @param token token to reclaim
     * @param _to address to send eth balance to
     */
    function claimToken(IERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }

    /**
     * @dev send all eth balance in the contract to another address
     * @param _to address to send eth balance to
     */
    function claimEther(address payable _to) external onlyOwner {
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
