// SPDX-License-Identifier: GPL-3.0

/// @title Fast Food Nouns Staker & L2 Oracle

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░████████████░░░░░░░░░░░ *
 * ░░░░░░██████░█░███░░░░░░░░░░░ *
 * ░░░░███████░█░█░██████░░░░░░░ *
 * ░░░████████░░░░░██████░░░░░░░ *
 * ░░░████████████████████████░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./FxBaseRootTunnel.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";

contract FastFoodStaker is Ownable, IERC721Receiver, FxBaseRootTunnel {
  
    // If a token is staked, this value will be set. Otherwise it'll be 0x0
    address[1000] public stakedOwners;

    // L1 Fast Food Nouns contract address
    ERC721 public tokenContract = ERC721(0xFbA74f771FCEE22f2FFEC7A66EC14207C7075a32);

    // Both params are Polygon tunnel contracts
    constructor(address _checkpointManager, address _fxRoot) FxBaseRootTunnel(_checkpointManager, _fxRoot) {}

    /**
     * @notice Stake a Fast Food Noun when it is sent via `safeTransferFrom`
     * @dev DO NOT use `transferFrom` to send NFTs. They will get stuck in the contract.
     */
    function onERC721Received(
        address operator, // account who called transfer
        address from, // previous NFT owner
        uint256 tokenId,
        bytes memory data
    ) external override returns (bytes4) {
        // Only accept Fast Food Nouns tokens
        require(msg.sender == address(tokenContract), "Invalid token");

        _stake(tokenId, from);

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
     * @notice Let user unstake their token.
     */
    function unstake(uint256 tokenId) external {
        require(msg.sender == stakedOwners[tokenId], "Not your token");

        _unstake(tokenId);

        // Return the token to owner
        tokenContract.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @notice Stake and send data to L2.
     */
    function _stake(uint256 tokenId, address owner) private {
        // Token received, set as staked
        stakedOwners[tokenId] = owner;

        // Encode and send data to Polyon. 1 == 'staked', 0 == 'unstaked'
        _sendMessageToChild(abi.encode(tokenId, 1, owner));
    }

    /**
     * @notice Unstake and send data to L2.
     */
    function _unstake(uint256 tokenId) private {
        // Token withdrawn, set as unstaked
        stakedOwners[tokenId] = address(0);

        // Encode and send data to Polyon. 1 == 'staked', 0 == 'unstaked'
        _sendMessageToChild(abi.encode(tokenId, 0, address(0)));
    }

    /**
     * @notice Required part of FxBaseRootTunnel interface, but we don't need it.
     */
    function _processMessageFromChild(bytes memory data) internal override {}

    /**
     * @notice So we can update more than once.
     */
    function setFxChildTunnelAddress(address _fxChildTunnel) external onlyOwner {
        fxChildTunnel = _fxChildTunnel;
    }
 
}