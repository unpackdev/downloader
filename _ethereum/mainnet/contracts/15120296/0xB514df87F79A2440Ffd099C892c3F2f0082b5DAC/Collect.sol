// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";
interface ERC721 /* is ERC165 */ {
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract Collet is Ownable {
    function collet(
        ERC721 nft,
        uint256[] memory tokenIds,
        address receiver
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address from = nft.ownerOf(tokenIds[i]);
            nft.safeTransferFrom(from, receiver, tokenIds[i]);
        }
    }

    function withdraw(
        ERC721 nft,
        uint256[] memory tokenIds,
        address receiver
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), receiver, tokenIds[i]);
        }
    }
}
