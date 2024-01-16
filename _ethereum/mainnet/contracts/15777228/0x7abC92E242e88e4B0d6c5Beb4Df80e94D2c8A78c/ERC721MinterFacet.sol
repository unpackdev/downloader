// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC721.sol";

import "./IERC721Mint.sol";
import "./Modifiers.sol";

import "./UInt256Set.sol";
import "./ERC721ALib.sol";

contract ERC721MinterFacet is Modifiers, IERC721Mint {

    using ERC721ALib for ERC721AContract;
    using UInt256Set for UInt256Set.Set;

    event ERC721Minted(address indexed to, uint256 indexed tokenId, bytes data);
    event ERC721BatchMinted(address indexed to, uint256[] indexed tokenIds, bytes data);

    /// @notice mint tokens of specified amount to the specified address
    function mint(
        uint256 quantity,
        bytes memory data
    ) external override onlyOwner returns (uint256) {
        ERC721ALib.erc721aStorage().erc721Contract._mint(
            address(this),
            address(this),
            quantity,
            data,
            true
        );
        emit ERC721Minted(address(this), quantity, data);
        return ERC721ALib.erc721aStorage().erc721Contract._currentIndex - 1;
    }

    /// @notice mint tokens of specified amount to the specified address
    /// @param receiver the mint target
    function mintTo(
        address receiver,
        uint256 quantity,
        bytes memory data
    ) external override onlyOwner returns (uint256 tokenId) {
        ERC721ALib.erc721aStorage().erc721Contract._mint(
            address(this),
            receiver,
            quantity,   
            data,
            true
        );
        emit ERC721Minted(receiver, quantity, data);
        return ERC721ALib.erc721aStorage().erc721Contract._currentIndex - 1;
    }

}
