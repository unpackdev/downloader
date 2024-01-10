//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC1155Mint.sol";
import "./IERC1155Burn.sol";

/// @dev extended by the multitoken
interface IMultiToken is IERC1155Mint, IERC1155Burn {

    function symbolOf(uint256 _tokenId) external view returns (string memory);
    function nameOf(uint256 _tokenId) external view returns (string memory);

}
