// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Strings.sol";
import "./NPass.sol";
import "./IN.sol";

/**
 * @title NWar contract
 * @author Maximonee (twitter.com/maximonee_)
 * @notice This contract allows n project holders to mint a nWar NFT for their corresponding n
 */
contract NWar is NPass {
    using Strings for uint256;

    constructor(
        string memory name,
        string memory symbol,
        bool onlyNHolders,
        uint256 maxTotalSupply,
        uint16 reservedAllowance,
        uint256 priceForNHoldersInWei,
        uint256 priceForOpenMintInWei
    )
        NPass(
            name,
            symbol,
            onlyNHolders,
            maxTotalSupply,
            reservedAllowance,
            priceForNHoldersInWei,
            priceForOpenMintInWei
        ) {}

    bool public isPresale = true;

    /**
     * @notice Allow contract owner to set if the presale period is active
     * @param _isPresale bool value indicating if the contract is open for only n holders or all
     */
    function setPresaleActive(bool _isPresale) public onlyOwner {
        isPresale = _isPresale;
    }

    function _getCurrentStagePrice() private view returns (uint256) {
        uint256 currentStagePrice = priceForNHoldersInWei;
        if (!isPresale) {
            currentStagePrice = priceForOpenMintInWei;
        }
        return currentStagePrice;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmNcCoWA17vpBsWckwgrxE6wrtptn8GLkA8sQ2iiHreAFU/";
    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param tokenId Id to be minted
     */
    function mint(uint256 tokenId) public payable override nonReentrant {
        require(!isPresale, "NPass:OPEN_MINTING_DISABLED");
        require(openMintsAvailable() > 0, "NPass:MAX_ALLOCATION_REACHED");
        require(
            (tokenId > MAX_N_TOKEN_ID && tokenId <= maxTokenId()) || n.ownerOf(tokenId) == msg.sender,
            "NPass:INVALID_ID"
        );
        require(msg.value == priceForOpenMintInWei, "NPass:INVALID_PRICE");

        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @param tokenId Id to be minted
     */
    function mintWithN(uint256 tokenId) public payable override nonReentrant {
        uint256 currentStagePrice = _getCurrentStagePrice();

        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );

        require(msg.value == currentStagePrice, "NPass:INVALID_PRICE");
        require(n.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Allow a n token holder to mint multiple tokens with an array of their n token's id
     * @param tokenIds Id(s) to be minted
     */
    function mintMultipleWithN(uint256[] calldata tokenIds) public payable virtual nonReentrant {
        uint256 numOfTokens = tokenIds.length;
        require(numOfTokens <= 100, "NPass:TOO_LARGE");
        
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + numOfTokens <= maxTotalSupply) ||
                reserveMinted + numOfTokens <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );

        uint256 currentStagePrice = _getCurrentStagePrice();
        uint256 price = tokenIds.length * currentStagePrice;

        require(msg.value == price, "NPass:INVALID_PRICE");

        for (uint256 i = 0; i < numOfTokens; i++) {
            require(n.ownerOf(tokenIds[i]) == msg.sender, "NPass:INVALID_OWNER");
        }

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(numOfTokens);
        }
        
        for (uint256 i = 0; i < numOfTokens; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
    }
}
