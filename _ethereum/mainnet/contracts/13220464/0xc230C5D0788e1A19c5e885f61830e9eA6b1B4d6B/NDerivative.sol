// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./NPass.sol";

/**
 * @title Holo(N) contract
 * @author HoloN
 * @notice This contract allows n project holders to mint Holo with your N
 */
contract HoloN is NPass {
    string public baseURI;
    bool public publicSale = false;

    constructor(string memory baseURI_)
        NPass(
            "HoloN",
            "HOLO",
            false,
            8888,
            0,
            20000000000000000,
            40000000000000000
        )
    {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPublicSale(bool _publicSale) public onlyOwner {
        publicSale = _publicSale;
    }

    /**
    Minting function
    */

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param tokenId Id to be minted
     */
    function mint(uint256 tokenId) public payable override nonReentrant {
        require(publicSale, "NPass:OPEN_MINTING_DISABLED");
        require(openMintsAvailable() > 0, "NPass:MAX_ALLOCATION_REACHED");
        require(tokenId > 0 && tokenId <= maxTotalSupply, "Token ID invalid");
        require(msg.value == priceForOpenMintInWei, "NPass:INVALID_PRICE");

        _safeMint(msg.sender, tokenId);
    }
}