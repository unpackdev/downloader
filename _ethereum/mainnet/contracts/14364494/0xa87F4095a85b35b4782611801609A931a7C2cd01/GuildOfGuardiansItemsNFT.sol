// contracts/GuildOfGuardiansItemsNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Minting.sol";
import "./GuildOfGuardiansNFTCommon.sol";

contract GuildOfGuardiansItemsNFT is GuildOfGuardiansNFTCommon {
    event MintFor(
        address to,
        uint256 amount,
        uint256 tokenId,
        uint16 proto,
        uint256 serialNumber,
        string tokenURI
    );

    constructor() ERC721("Guild of Guardians Items", "GOGI") {}

    /**
     * @dev Called by IMX to mint each NFT
     *
     * @param to the address to mint to
     * @param amount not relevant for NFTs
     * @param mintingBlob all NFT details
     */
    function mintFor(
        address to,
        uint256 amount,
        bytes memory mintingBlob
    ) external override {
        (
            uint256 tokenId,
            uint16 proto,
            uint256 serialNumber,
            string memory tokenURI
        ) = Minting.deserializeMintingBlob(mintingBlob);
        _mintCommon(to, tokenId, tokenURI, proto, serialNumber);
        emit MintFor(to, amount, tokenId, proto, serialNumber, tokenURI);
    }

    /**
     * @dev Retrieve the proto, serial and special edition for a particular card represented by it's token id
     *
     * @param tokenId the id of the NFT you'd like to retrieve details for
     * @return proto The proto (type) of the specified NFT
     * @return serialNumber The serial number of the specified NFT
     */
    function getDetails(uint256 tokenId)
        public
        view
        returns (uint16 proto, uint256 serialNumber)
    {
        return (protos[tokenId], serialNumbers[tokenId]);
    }
}
