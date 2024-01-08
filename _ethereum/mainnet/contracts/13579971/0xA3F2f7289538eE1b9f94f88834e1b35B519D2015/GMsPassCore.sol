// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/**
 * @title GMsPassCore contract
 * @author wildmouse
 * @notice This contract provides basic functionalities to allow minting using the GMsPass
 * @dev This contract should be used only for testing or testnet deployments
 */
abstract contract GMsPassCore is ERC721, ReentrancyGuard, Ownable {
    uint256 public constant MAX_MULTI_MINT_AMOUNT = 32;
    uint256 public constant GMS_SUPPLY_AMOUNT = 10000;
    uint256 public constant MAX_GMs_TOKEN_ID = 9999;
    uint256 public constant METADATA_INDEX = 3799;

    IERC721 public immutable generativemasks;
    bool public immutable onlyGMsHolders;
    uint16 public immutable reservedAllowance;
    uint16 public reserveMinted;
    uint256 public immutable maxTotalSupply;
    uint256 public immutable priceForGMsHoldersInWei;
    uint256 public immutable priceForOpenMintInWei;
    uint256 public mintedCount;

    /**
     * @notice Construct an GMsPassCore instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param generativemasks_ Address of your GMs instance (only for testing)
     * @param onlyGMsHolders_ True if only GMs tokens holders can mint this token
     * @param maxTotalSupply_ Maximum number of tokens that can ever be minted
     * @param reservedAllowance_ Number of tokens reserved for GMs token holders
     * @param priceForGMsHoldersInWei_ Price GMs token holders need to pay to mint
     * @param priceForOpenMintInWei_ Price open minter need to pay to mint
     */
    constructor(
        string memory name,
        string memory symbol,
        IERC721 generativemasks_,
        bool onlyGMsHolders_,
        uint256 maxTotalSupply_,
        uint16 reservedAllowance_,
        uint256 priceForGMsHoldersInWei_,
        uint256 priceForOpenMintInWei_
    ) ERC721(name, symbol) {
        require(maxTotalSupply_ > 0, "GMsPass:INVALID_SUPPLY");
        require(!onlyGMsHolders_ || (onlyGMsHolders_ && maxTotalSupply_ <= GMS_SUPPLY_AMOUNT), "GMsPass:INVALID_SUPPLY");
        require(maxTotalSupply_ >= reservedAllowance_, "GMsPass:INVALID_ALLOWANCE");
        // If restricted to generativemasks token holders we limit max total supply
        generativemasks = generativemasks_;
        onlyGMsHolders = onlyGMsHolders_;
        maxTotalSupply = maxTotalSupply_;
        reservedAllowance = reservedAllowance_;
        priceForGMsHoldersInWei = priceForGMsHoldersInWei_;
        priceForOpenMintInWei = priceForOpenMintInWei_;
    }

    function getTokenIdFromMaskNumber(uint256 maskNumber) public pure returns (uint256) {
        require(maskNumber <= MAX_GMs_TOKEN_ID, "GMsPass:INVALID_NUMBER");
        return ((maskNumber + GMS_SUPPLY_AMOUNT) - METADATA_INDEX) % GMS_SUPPLY_AMOUNT;
    }

    function getTokenIdListFromMaskNumbers(uint256[] calldata maskNumbers) public pure returns (uint256[] memory) {
        uint256[] memory tokenIdList = new uint256[](maskNumbers.length);

        for (uint256 i = 0; i < maskNumbers.length; i++) {
            require(maskNumbers[i] <= MAX_GMs_TOKEN_ID, "GMsPass:INVALID_NUMBER");
            tokenIdList[i] = getTokenIdFromMaskNumber(maskNumbers[i]);
        }

        return tokenIdList;
    }

    /**
     * @notice Allow a GMs token holder to bulk mint tokens with id of their GMs tokens' id
     * @param maskNumbers numbers to be converted to token ids to be minted
     */
    function multiMintWithGMsMaskNumbers(uint256[] calldata maskNumbers) public payable virtual {
        multiMintWithGMsTokenIds(getTokenIdListFromMaskNumbers(maskNumbers));
    }

    /**
     * @notice Allow a GMs token holder to mint a token with one of their GMs token's id
     * @param maskNumber number to be converted to token id to be minted
     */
    function mintWithGMsMaskNumber(uint256 maskNumber) public payable virtual {
        mintWithGMsTokenId(getTokenIdFromMaskNumber(maskNumber));
    }

    /**
     * @notice Allow a GMs token holder to bulk mint tokens with id of their GMs tokens' id
     * @param tokenIds Ids to be minted
     */
    function multiMintWithGMsTokenIds(uint256[] memory tokenIds) public payable virtual nonReentrant {
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= MAX_MULTI_MINT_AMOUNT, "GMsPass:TOO_LARGE");
        require(
        // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && mintedCount + maxTokensToMint <= maxTotalSupply) ||
            reserveMinted + maxTokensToMint <= reservedAllowance,
            "GMsPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value == priceForGMsHoldersInWei * maxTokensToMint, "GMsPass:INVALID_PRICE");
        // To avoid wasting gas we want to check all preconditions beforehand
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(tokenIds[i] <= MAX_GMs_TOKEN_ID, "GMsPass:INVALID_ID");
            require(generativemasks.ownerOf(tokenIds[i]) == msg.sender, "GMsPass:INVALID_OWNER");
        }

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(maxTokensToMint);
        }
        mintedCount += maxTokensToMint;
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @notice Allow a GMs token holder to mint a token with one of their GMs token's id
     * @param tokenId Id to be minted
     */
    function mintWithGMsTokenId(uint256 tokenId) public payable virtual nonReentrant {
        require(
        // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && mintedCount < maxTotalSupply) || reserveMinted < reservedAllowance,
            "GMsPass:MAX_ALLOCATION_REACHED"
        );
        require(tokenId <= MAX_GMs_TOKEN_ID, "GMsPass:INVALID_ID");
        require(generativemasks.ownerOf(tokenId) == msg.sender, "GMsPass:INVALID_OWNER");
        require(msg.value == priceForGMsHoldersInWei, "GMsPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }
        mintedCount++;
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         GMs token holders can use this function without using the GMs token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param tokenId Id to be minted
     */
    function mint(uint256 tokenId) public payable virtual nonReentrant {
        require(!onlyGMsHolders, "GMsPass:OPEN_MINTING_DISABLED");
        require(openMintsAvailable() > 0, "GMsPass:MAX_ALLOCATION_REACHED");
        require(
            (tokenId > MAX_GMs_TOKEN_ID && tokenId <= maxTokenId()) || generativemasks.ownerOf(tokenId) == msg.sender,
            "GMsPass:INVALID_ID"
        );
        require(msg.value == priceForOpenMintInWei, "GMsPass:INVALID_PRICE");
        mintedCount++;
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @notice Calculate the maximum token id that can ever be minted
     * @return Maximum token id
     */
    function maxTokenId() public view returns (uint256) {
        uint256 maxOpenMints = maxTotalSupply - reservedAllowance;
        return MAX_GMs_TOKEN_ID + maxOpenMints;
    }

    /**
     * @notice Calculate the currently available number of reserved tokens for GMs token holders
     * @return Reserved mint available
     */
    function gmsHoldersMintsAvailable() external view returns (uint256) {
        return reservedAllowance - reserveMinted;
    }

    /**
     * @notice Calculate the currently available number of open mints
     * @return Open mint available
     */
    function openMintsAvailable() public view returns (uint256) {
        uint256 maxOpenMints = maxTotalSupply - reservedAllowance;
        uint256 currentOpenMints = mintedCount - reserveMinted;
        return maxOpenMints - currentOpenMints;
    }

    /**
     * @notice Allows owner to withdraw amount
     */
    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
