// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract SpotlightAversano is ERC721, Ownable {
    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");

        _;
    }

    uint256 public totalSupply = 0;
    string private baseURI =
        "https://time.mypinata.cloud/ipfs/QmSf4Wxp1QNRcSR94JhLPgA7WyF9QDWHziUSKDT83miwS7";
    bool private isFrozen = false;

    constructor() ERC721("SpotlightAversano", "SLA") {}

    // ONLY OWNER

    /**
     * @dev Sets the base URI that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        baseURI = _uri;
    }

    /**
     * @dev gives tokens to the given addresses
     */
    function devMintTokensToAddresses(address[] memory _addresses)
        external
        onlyOwner
        contractIsNotFrozen
    {
        uint256 tmpTotalMintedTokens = totalSupply;
        totalSupply += _addresses.length;

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    // END ONLY OWNER

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return baseURI;
    }
}
