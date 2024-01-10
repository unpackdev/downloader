// SPDX-License-Identifier: MIT

/// @title  Commit-reveal seeder
/// @notice Implements a gas-conscious NFT metadata seed commit-reveal scheme that is brute-force resistant.
/// @dev Seed is established and reveals after a commit has been made in a block subsequent to the mint block. Seeds are not directly committed to storage in their final form.
/// @dev Requires tokenIds are serially in ascending order (but not required to start at zero)
/// @dev Take note that mint gas costs will be slightly irregular and should be overestimated by UI
/// @dev The final blockhash is manually established by calling _commitFinalBlockHash()

/*   To use:
 *
 *   Inherit CRSeeder from base NFT contract
 *   Call _commitTokens(_currentIndex) if using ERC721A or _commitTokens(totalSupply() + 1) in other cases, *prior* to _mint/_safeMint
 *   After max supply is reached out, call _commitFinalBlockHash
 *
 *   To read the seed, call _rawSeedForTokenId(tokenId)
 */

pragma solidity ^0.8.0;

contract CommitRevealSeeder {
   /// @notice Array of blockhashes required to generate a pseudorandom seed
   /// @dev Only stored once per block. Blockhashes reduced to 8 bytes (from 32) for tighter packing and gas savings.
   bytes8[] public blockhashData;

   /// @notice Struct type for storing the map from a given token to the blockhash used to generate that token's pseudorandom seed.
   /// @dev Packs tighter than a mapping, saving gas costs upon mint.
   struct TokenMap {
      uint16 startingTokenId;
      uint16 blockhashIndex;
   }

   /// @notice Array of TokenMaps
   /// @dev Only the first token in each mint transaction is assigned an entry
   TokenMap[] public tokenMap;

   /// @notice Creates new tokenMap entry and commits new blockhash if one has not been set for the current block
   /// @param _startingTokenId, the first tokenId to be minted in a transaction
   function _commitTokens(uint256 _startingTokenId) internal {
      _commitBlockHash();
      _commitTokenMap(_startingTokenId);
   }

   /// @notice Commits blockhash of the previous block to storage as the next item in blockhashData[]
   /// @dev Only sets once per block
   /// @dev The first commit on the contract is not used for any token.
   function _commitBlockHash() private {
      if (blockhashData.length == 0 || blockhashData[blockhashData.length - 1] != bytes8(blockhash(block.number - 1))) {
         blockhashData.push(bytes8(blockhash(block.number - 1)));
      }
   }

   /// @notice Commits a new tokenId and blockhashData index to tokenMap.
   /// @param _startingTokenId, the first tokenId to be minted in a given transaction
   function _commitTokenMap(uint256 _startingTokenId) private {
      require(
         tokenMap.length == 0 || uint16(_startingTokenId) > tokenMap[tokenMap.length - 1].startingTokenId,
         "tokenIds must be comitted in ascending order"
      );
      tokenMap.push(TokenMap({startingTokenId: uint16(_startingTokenId), blockhashIndex: uint16(blockhashData.length)}));
   }

   /// @notice Determines the blockhashData[] index to use for a given tokenId
   /// @param tokenId, desired tokenId
   /// @return uint16 blockhashData array index that contains the applicable blockhash data
   /// @dev Only the first tokenId for each transaction is committed to storage; the blockhash for all other tokenIds is inferred.
   /// @dev The first tokenId used in the contract will always return 1.
   /// @dev This function is inefficient and is intended only to be used in read operations. For larger collections, consider implementing a binary search.
   function _tokenIdToBlockhashIndex(uint256 tokenId) internal view returns (uint16) {
      //when there has only been a single commit, return 1 to avoid an underflow in the search loop
      if (tokenMap.length == 1) return 1;

      for (uint256 i; i <= tokenMap.length - 2; i++) {
         if (tokenId >= tokenMap[i].startingTokenId && tokenId < tokenMap[i + 1].startingTokenId) return tokenMap[i].blockhashIndex;
      }
      //if the tokenId exceeds the last item tested in the loop, return the final index
      return tokenMap[tokenMap.length - 1].blockhashIndex;
   }

   /// @notice Determines the seed for a given tokenId.
   /// @param tokenId, the desired tokenId
   /// @return uint256 raw pseudorandom seed (or zero, if not yet established).
   /// @dev In order to save storage costs, seeds are not directly stored on chain after reveal but are instead generated deterministically in read calls
   /// @dev Requires one blockhash to have been comitted following mint, otherwise no seed exists
   /// @dev Permits theoretical collisions because seeds are not directly stored and not processed to prevent duplicates
   function _rawSeedForTokenId(uint256 tokenId) internal view returns (uint256) {
      uint256 blockhashIndex = _tokenIdToBlockhashIndex(tokenId); //Grab the location of the blockhashData to be used for this token
      if ((blockhashData.length - 1) >= blockhashIndex) {
         //ensures there has been at least one commit (+1 block) after mint
         return uint256(keccak256(abi.encodePacked(address(this), tokenId, blockhashData[blockhashIndex])));
      } else {
         //blockhash not yet established
         return 0;
      }
   }

   /// @notice Establishes the final blockhash after the mint completes, since reveals require at least one blockhash to be established;
   /// @dev Should not be called by end users for security
   function _commitFinalBlockHash() internal {
      require(blockhashData[blockhashData.length - 1] != bytes8(blockhash(block.number - 1)), "Wait one block");
      _commitBlockHash();
   }
}
