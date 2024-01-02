// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

// import "./IERC721.sol";

/**
* @dev Required interface of an ERC721 compliant contract, optional enumeration extension, as defined in the
* https://eips.ethereum.org/EIPS/eip-721[EIP].
*   Note: the ERC-165 identifier for this interface is 0x780e9d63.
*/
interface IERC721Enumerable /* is IERC721 */ {
  // **************************************
  // *****           ERRORS           *****
  // **************************************
    /// @dev Thrown when trying to get the token at an index that doesn"t exist.
    /// 
    /// @param index the inexistant index
    error IERC721Enumerable_INDEX_OUT_OF_BOUNDS(uint256 index);
    /// @dev Thrown when trying to get the token owned by `tokenOwner` at an index that doesn"t exist.
    /// 
    /// @param index the inexistant index
    error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS(uint256 index);
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /// @dev Enumerate valid NFTs
    ///   Throws if `index_` >= {totalSupply()}.
    function tokenByIndex(uint256 index_) external view returns (uint256);
    /// @dev Enumerate NFTs assigned to an owner
    ///   Throws if `index_` >= {balanceOf(owner_)} or if `owner_` is the zero address, representing invalid NFTs.
    function tokenOfOwnerByIndex(address owner_, uint256 index_) external view returns (uint256);
    /// @dev Count NFTs tracked by this contract
    function totalSupply() external view returns (uint256);
  // **************************************
}
