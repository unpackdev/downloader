// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721.sol";
import "./IERC1155.sol";
import "./AdminControl.sol";

contract DegenGiveaways is AdminControl {
    uint private salt;
    address[] public degenHolders;
    address[] private giveawayHolders;

    // Used for setting all degen holders
    function setDegenHolders(address[] memory holders) public adminRequired {
        degenHolders = holders;
    }

    // Used for setting specific holder if more are minted
    function addSpecificDegenHolder(address holder) public adminRequired {
        degenHolders.push(holder);
    }

    // Used for replacing specific holder if token is sold
    function replaceSpecificDegenHolder(uint previousHolderIndex, address newHolder) public adminRequired {
        degenHolders[previousHolderIndex] = newHolder;
    }

    // Use for one-off giveaway
    function giveaway1155(address tokenAddress, uint tokenId, uint howMany) public {
        address winner = randomHolder();
        try IERC1155(tokenAddress).safeTransferFrom(msg.sender, winner, tokenId, howMany, "") {
        } catch (bytes memory) {
            revert("Giveaway failed.");
        }
    }

    // Use for one-off giveaway
    function giveaway721(address tokenAddress, uint tokenId) public {
        address winner = randomHolder();
        try IERC721(tokenAddress).transferFrom(msg.sender, winner, tokenId) {
        } catch (bytes memory) {
            revert("Giveaway failed.");
        }
    }

    // Use for group giveaway
    function giveaway721s(address[] memory tokenAddresses, uint[] memory tokenIds, bool withReplacement) public {
        address[] memory winners = randomHolderSet(tokenIds.length, withReplacement);
        for (uint i = 0; i < winners.length; i++) {
            try IERC721(tokenAddresses[i]).transferFrom(msg.sender, winners[i], tokenIds[i]) {
            } catch (bytes memory) {
                revert("Giveaway failed.");
            }
        }
    }

    // Use for group giveaway
    function giveaway1155s(address[] memory tokenAddresses, uint[] memory tokenIds, uint[] memory howMany, bool withReplacement) public {
        address[] memory winners = randomHolderSet(tokenIds.length, withReplacement);
        for (uint i = 0; i < winners.length; i++) {
            try IERC1155(tokenAddresses[i]).safeTransferFrom(msg.sender, winners[i], tokenIds[i], howMany[i], "") {
            } catch (bytes memory) {
                revert("Giveaway failed.");
            }
        }
    }

    // Gets a random holder
    function randomHolder() private returns (address) {
      salt++;
      uint holderIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % degenHolders.length;
      return degenHolders[holderIndex];
    }

    // Gets random set of holders. If withReplacement is true, winners can win multiple times
    function randomHolderSet(uint howMany, bool withReplacement) private returns (address[] memory) {
      address[] memory winners = new address[](howMany);
      if (withReplacement) {
        for (uint i = 0; i < howMany; i++) {
            salt++;
            uint holderIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % degenHolders.length;
            winners[i] = degenHolders[holderIndex];
        }
      } else {
        giveawayHolders = degenHolders;
        for (uint i = 0; i < howMany; i++) {
            salt++;
            uint holderIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % giveawayHolders.length;
            winners[i] = giveawayHolders[holderIndex];
            remove(holderIndex);
        }
      }
      return winners;
    }

    // Helper function to remove from array
    function remove(uint256 index) internal {
        require(giveawayHolders.length > index, "Out of bounds");
        // move all elements to the left, starting from the `index + 1`
        for (uint256 i = index; i < giveawayHolders.length - 1; i++) {
            giveawayHolders[i] = giveawayHolders[i+1];
        }
        giveawayHolders.pop(); // delete the last item
    }

}
