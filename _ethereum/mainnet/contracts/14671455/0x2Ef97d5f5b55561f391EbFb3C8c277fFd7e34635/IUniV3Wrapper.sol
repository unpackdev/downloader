//SPDX-License-Identifier: Unlicense

import "./IERC721.sol";
import "./IFlashNFTReceiver.sol";

pragma solidity ^0.8.9;

interface IUniV3Wrapper is IFlashNFTReceiver, IERC721 {
  /// @notice Exposes Uniswap V3 fee extraction function
  /// @param tokenId The ID of the nft
  /// @param recipient The address where the collected fees will be sent to
  function extractUniswapFees(uint256 tokenId, address recipient) external;
}
