// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * @title ERC20TokenRecover
 * @author Henk ter Harmsel
 * @dev Allows owner to recover any ERC20 or ETH sent into the contract
 * based on https://github.com/vittominacori/eth-token-recover by Vittorio Minacori
 */
contract ERC20TokenRecover is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice function that transfers an token amount from this contract to the owner when accidentally sent
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20Upgradeable(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    /**
     * @notice function that transfers an eth amount from this contract to the owner when accidentally sent
     * @param amount Number of eth to be sent
     */
    function recoverETH(uint256 amount) public virtual onlyOwner {
        (bool sent, ) = owner().call{value: amount}('');
        require(sent, 'ERC20TokenRecover: SENDING_ETHER_FAILED');
    }
}
