// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface INFTBadge721Token  {   
    /**
     * @dev Mint Badge NFT to the user.
     */
    function mintBadgeNFTToUser(address _to, uint256 _tokenId, string memory _tokenURI) external returns(bool);   
}
