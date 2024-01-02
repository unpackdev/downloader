// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

// import "./IERC165.sol";

/**
* @dev Required interface of an ERC2981 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-2981[EIP].
*   Note: the ERC-165 identifier for this interface is 0x2a55205a.
*/
interface IERC2981 /* is IERC165 */ {
  // **************************************
  // *****           ERRORS           *****
  // **************************************
    /// @dev Thrown when the desired royalty rate is higher than 10,000
    error IERC2981_INVALID_ROYALTIES();
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /// @dev Called with the sale price to determine how much royalty is owed and to whom.
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
    external view returns (address receiver, uint256 royaltyAmount);
  // **************************************
}
