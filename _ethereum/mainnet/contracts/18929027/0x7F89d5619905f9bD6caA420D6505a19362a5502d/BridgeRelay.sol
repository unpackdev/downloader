// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./SafeERC20.sol";
import "./IBridgeRelay.sol";
import "./IERC20Withdrawable.sol";
import "./IPOSBridge.sol";

/**
 * @title RootBridgeRelay
 * @author Amir Shirif, Telcoin, LLC.
 * @notice this contract is meant for forwarding ERC20 and ETH accross the polygon bridge system
 */
contract BridgeRelay is IBridgeRelay {
    using SafeERC20 for IERC20;

    // Master Safe
    address private constant OWNER_ADDRESS =
        0xE075504E14bBB4d2aA6333DB5b8EFc1e8c2AE05B;
    //ETHER address
    address public constant ETHER_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // WETH address
    IERC20 public constant WETH_ADDRESS =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //MATIC address
    IERC20 public constant MATIC_ADDRESS =
        IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
    // mainnet PoS bridge
    IPOSBridge public constant POS_BRIDGE =
        IPOSBridge(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
    // mainnet predicate
    address public constant PREDICATE_ADDRESS =
        0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

    /**
     * @notice calls Polygon POS bridge for deposit
     * @dev the contract is designed in a way where anyone can call the function without risking funds
     * @dev MATIC cannot be bridged
     * @param token address of the token that is desired to be pushed accross the bridge
     */
    function bridgeTransfer(IERC20 token) external payable override {
        if (token == MATIC_ADDRESS) {
            revert MATICUnbridgeable();
        }

        if (address(token) == ETHER_ADDRESS) {
            transferETHToBridge();
            return;
        }

        if (token == WETH_ADDRESS) {
            IERC20Withdrawable(address(WETH_ADDRESS)).withdraw(
                IERC20(WETH_ADDRESS).balanceOf(address(this))
            );

            transferETHToBridge();
            return;
        }

        transferERCToBridge(token);
    }

    /**
     * @notice pushes ETHER transfers through to the PoS bridge
     * @dev WETH will be minted to the recipient
     */
    function transferETHToBridge() internal {
        POS_BRIDGE.depositEtherFor{value: address(this).balance}(address(this));
    }

    /**
     * @notice pushes token transfers through to the PoS bridge
     * @dev this is for ERC20 tokens that are not the matic token
     * @dev only tokens that are already mapped on the bridge will succeed
     * @param token is address of the token that is desired to be pushed accross the bridge
     */
    function transferERCToBridge(IERC20 token) internal {
        token.forceApprove(PREDICATE_ADDRESS, token.balanceOf(address(this)));
        POS_BRIDGE.depositFor(
            address(this),
            address(token),
            abi.encodePacked(token.balanceOf(address(this)))
        );
        token.forceApprove(PREDICATE_ADDRESS, 0);
    }

    /**
     * @notice helps recover MATIC which cannot be bridged with POS bridge
     * @dev onlyOwner may make function call
     * @param destination address where funds are returned
     * @param amount is the amount being migrated
     */
    function erc20Rescue(address destination, uint256 amount) external {
        require(
            msg.sender == OWNER_ADDRESS,
            "BridgeRelay: caller must be owner"
        );
        MATIC_ADDRESS.safeTransfer(destination, amount);
    }

    /**
     * @notice receives ETHER
     */
    receive() external payable {}
}
