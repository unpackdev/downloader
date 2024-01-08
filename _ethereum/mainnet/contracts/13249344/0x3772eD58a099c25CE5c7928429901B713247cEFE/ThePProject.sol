//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./NPass.sol";
import "./IN.sol";
import "./IOpenPalette.sol";

/**
 * @title ThePProject
 * @author Inspired by @KnavETH
 */
contract ThePProject is NPass {
    using Strings for uint256;

    IOpenPalette public immutable openPalette;

    string public baseURI;
    bool public publicSale = false;
    bool public preSale = false;

    constructor(string memory baseURI_) NPass("ThePProject", "P", false, 8888, 0, 25000000000000000, 50000000000000000) {
        baseURI = baseURI_;
        openPalette = IOpenPalette(0x1308c158e60D7C4565e369Df2A86eBD853EeF2FB);
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

    function setPreSale(bool _preSale) public onlyOwner {
        preSale = _preSale;
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
    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param tokenIds Ids to be minted
     */
    function multiMintWithOpenPalette(uint256[] calldata tokenIds) public payable nonReentrant {
        uint256 maxTokensToMint = tokenIds.length;
        require(preSale, "NPass:MINTING_DISABLED");
        require(maxTokensToMint <= MAX_MULTI_MINT_AMOUNT_FOR_HOLDERS, "NPass:TOO_LARGE");
        require(
        // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + maxTokensToMint <= maxTotalSupply) ||
            reserveMinted + maxTokensToMint <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value == priceForNHoldersInWei * maxTokensToMint, "NPass:INVALID_PRICE");
        // To avoid wasting gas we want to check all preconditions beforehand
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(openPalette.ownerOf(tokenIds[i]) == msg.sender, "NPass:INVALID_OWNER");
        }

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(maxTokensToMint);
        }
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @param tokenId Id to be minted
     */
    function mintWithOpenPalette(uint256 tokenId) public payable nonReentrant {
        require(preSale, "NPass:MINTING_DISABLED");
        require(
        // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(openPalette.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");
        require(msg.value == priceForNHoldersInWei, "NPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }
        _safeMint(msg.sender, tokenId);
    }

    function multiMint(uint256[] calldata tokenIds) public payable nonReentrant {
        require(publicSale, "NPass:OPEN_MINTING_DISABLED");
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= MAX_MULTI_MINT_AMOUNT, "NPass:TOO_LARGE");
        require(
        // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + maxTokensToMint <= maxTotalSupply) ||
            reserveMinted + maxTokensToMint <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value == priceForOpenMintInWei * maxTokensToMint, "NPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(maxTokensToMint);
        }
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param tokenIds Ids to be minted
     */
    function multiMintWithN(uint256[] calldata tokenIds) public payable override nonReentrant {
        require(preSale, "NPass:MINTING_DISABLED");
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= MAX_MULTI_MINT_AMOUNT_FOR_HOLDERS, "NPass:TOO_LARGE");
        require(
        // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + maxTokensToMint <= maxTotalSupply) ||
            reserveMinted + maxTokensToMint <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value == priceForNHoldersInWei * maxTokensToMint, "NPass:INVALID_PRICE");
        // To avoid wasting gas we want to check all preconditions beforehand
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(n.ownerOf(tokenIds[i]) == msg.sender, "NPass:INVALID_OWNER");
        }

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(maxTokensToMint);
        }
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @param tokenId Id to be minted
     */
    function mintWithN(uint256 tokenId) public payable override nonReentrant {
        require(preSale, "NPass:MINTING_DISABLED");
        require(
        // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(n.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");
        require(msg.value == priceForNHoldersInWei, "NPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }
        _safeMint(msg.sender, tokenId);
    }

    function contractURI() public pure returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmPLng18aBmAZBeKSeZgzyYDDA46jj95shX6dYomNCjDfA";
    }
}
