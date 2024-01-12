// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;


/// @title Crypto Bear Watch Club Pieces Interface
/// @author Kfish n Chips
/// @notice ERC721 Watch Pieces to be claimed by CBWC holders
/// @dev Claiming begins once WAVE_MANAGER starts a claim wave
/// @custom:security-contact security@kfishnchips.com
interface ICBWCPieces {
    //function tokensOfOwner(address owner) external view returns (uint256[] memory);

    /// @notice Burn existing token
    /// @dev Forge contract will call this function
    /// @param tokenIds_ The tokenIds to burn
    /// @return bool success
    function burnPieces(
        uint256[] calldata tokenIds_, 
        address owner_
    ) 
        external 
        returns (bool);
    //function ownerOf(uint256 tokenId) external view returns (address);
}
