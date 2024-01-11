// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721.sol";
import "./IERC1155.sol";

interface IAshCC {
    function addPoints(uint tokenId, uint numPoints) external;
}

/**
 * ASH CC Giveaways :)
 */
contract AshCCGiveaways {
    uint private salt;
    address private _ashCC;
    address private _ashCCCore;

    constructor(address ashCCCore, address ashCC) {
      _ashCCCore = ashCCCore;
      _ashCC = ashCC;
    }

    function giveaway1155(address tokenAddress, uint tokenId, uint howMany) public {
        require(IERC1155(tokenAddress).isApprovedForAll(msg.sender, address(this)), "Token not approved for giveaway");

        address winner = randomHolder();
        try IERC1155(tokenAddress).safeTransferFrom(msg.sender, winner, tokenId, howMany, "") {
        } catch (bytes memory) {
            revert("Giveaway failed.");
        }
    }

    function giveaway721(address tokenAddress, uint tokenId) public {
        try IERC721(tokenAddress).getApproved(tokenId) returns (address approvedAddress) {
            require(approvedAddress == address(this), "Token not approved for giveaway");
        } catch (bytes memory) {
            revert("Giveaway failed.");
        }

        address winner = randomHolder();
        try IERC721(tokenAddress).transferFrom(msg.sender, winner, tokenId) {
        } catch (bytes memory) {
            revert("Giveaway failed.");
        }
    }

    function randomHolder() private returns (address) {
      salt++;
      uint tokenId = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % 25;
      IAshCC(_ashCC).addPoints(tokenId, 10);
      return IERC721(_ashCCCore).ownerOf(tokenId);
    }

}
