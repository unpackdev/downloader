//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC1155Holder.sol";
import "./ERC721Holder.sol";

/// @title Token Holder
/// @notice This is a helper contract.
/// @author Piotr "pibu" Buda
abstract contract TokenHolder is ERC1155Holder, ERC721Holder {

}
