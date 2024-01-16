// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC721.sol";
import "./ERC165Checker.sol";
import "./IERC1155.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./MintManager.sol";
import "./PaintToken.sol";

/**
 * Boring Security Grid NFT contract
 */
contract GridNFT is AccessControl, ReentrancyGuard, ERC721 {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    using Strings for uint256;
    using ERC165Checker for address;

    uint256 public immutable MAX_SUPPLY;

    PaintToken public paintToken;
    MintManager public mintManager;

    string public contractURI;
    address public allowTokenAddress;
    address public majorShareAddress;
    address public minorShareAddress;
    uint256 public allowTokenId;
    uint256 public mintPaintReward;

    mapping(uint256 => bool) public freeForAllMode;

    struct GridContents {
        uint256 currentBlockNumber;
    }

    uint256 public immutable GRID_WIDTH;
    uint256 public immutable MAX_PIXEL_GROUPS;
    uint256 public immutable PRICE_PER_PIXEL;
    uint256 public immutable COVERAGE_COST;

    GridContents[] gridContents;

    /** @dev Checks if token exists
     * @param _tokenId The token id to check if exists
     */
    modifier onlyExistingTokens(uint256 _tokenId) {
        require(_exists(_tokenId), "Invalid Token ID");
        _;
    }

    /** @dev Checks if sender address has admin role
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Does not have admin role");
        _;
    }

     /** @dev Checks if sender address has admin role
     */
    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Does not own token");
        _;
    }

    event GridNFTMinted(uint256 indexed id, address indexed owner);
    //Declare an Event for when canvas is written to
    event Painted(uint256 indexed tokenId, uint256[] colorIndex, uint256[] pixelGroups);

    constructor(
        uint256 gridWidth,
        uint256 pricePerPixel,
        uint256 maxSupply,
        address[] memory admins,
        address _majorShareAddress,
        address _minorShareAddress,
        MintManager _mintManager,
        PaintToken _tokenAddr
    ) public ERC721("Boring Security Grid - powered by MurAll", "GRID") {
        for (uint256 i = 0; i < admins.length; ++i) {
            _setupRole(ADMIN_ROLE, admins[i]);
        }

        majorShareAddress = _majorShareAddress;
        minorShareAddress = _minorShareAddress;

        mintManager = _mintManager;
        paintToken = _tokenAddr;

        MAX_SUPPLY = maxSupply;
        GRID_WIDTH = gridWidth;
        MAX_PIXEL_GROUPS = (gridWidth * gridWidth) / 32;
        PRICE_PER_PIXEL = pricePerPixel;
        COVERAGE_COST = (gridWidth * gridWidth) * pricePerPixel;
    }

    /**
     * @param tokenID       - The token id to set pixels on
     * @param colorIndex    - Color index defining the 256 colors the pixels reference at display time (RGB565 format, 2 bytes per color)
     * @param pixelGroups   - RGB pixels in groups of 32 (1 pixel reference every 1 byte) - should equal MAX_PIXEL_GROUPS in length
     */
    function setPixels(
        uint256 tokenID,
        uint256[] calldata colorIndex,
        uint256[] calldata pixelGroups
    ) external nonReentrant {
        if (freeForAllMode[tokenID]) {
            require(IERC1155(allowTokenAddress).balanceOf(msg.sender, allowTokenId) >= 1, "Must have token to paint");
        } else {
            require(ownerOf(tokenID) == msg.sender, "Does not own token");
        }
        require(colorIndex.length <= 16 && colorIndex.length >= 1, "colour index invalid"); // max 256 colors in groups of 16 (16 groups of 16 colors = 256 colors)
        require(pixelGroups.length == MAX_PIXEL_GROUPS, "pixel groups not correct size");

        paintToken.burnFrom(msg.sender, COVERAGE_COST);

        gridContents[tokenID].currentBlockNumber = block.number;

        emit Painted(tokenID, colorIndex, pixelGroups);
    }

    function setFreeForAllForToken(uint256 tokenID, bool freeForAll) external onlyTokenOwner(tokenID) {
        freeForAllMode[tokenID] = freeForAll;
    }

    /**
     * @notice Set the base URI for creating `tokenURI` for each NFT.
     * Only invokable by admin role.
     * @param _tokenUriBase base for the ERC721 tokenURI
     */
    function setTokenUriBase(string calldata _tokenUriBase) external onlyAdmin {
        // Set the base for metadata tokenURI
        _setBaseURI(_tokenUriBase);
    }

    /**
     * @notice Set the contract URI for marketplace data.
     * Only invokable by admin role.
     * @param _contractURI contract uri for this contract
     */
    function setContractUri(string calldata _contractURI) external onlyAdmin {
        // Set the base for metadata tokenURI
        contractURI = _contractURI;
    }

    function setMintPaintReward(uint256 _mintPaintReward) external onlyAdmin {
        mintPaintReward = _mintPaintReward;
    }

    /**
     * @notice Set the token contract address and ID for the free for all mode.
     * Only invokable by admin role.
     * @param tokenAddress the token address
     * @param tokenId the token id
     */
    function setAllowToken(address tokenAddress, uint256 tokenId) external onlyAdmin {
        // require(tokenAddress.supportsInterface(_INTERFACE_ID_ERC1155), "Token address does not support ERC1155");
        allowTokenAddress = tokenAddress;
        allowTokenId = tokenId;
    }

    function setMajorShareAddress(address _majorShareAddress) external {
        require(msg.sender == majorShareAddress, "Is not major share address");
        majorShareAddress = _majorShareAddress;
    }

    function setMinorShareAddress(address _minorShareAddress) external {
        require(msg.sender == minorShareAddress, "Is not minor share address");
        minorShareAddress = _minorShareAddress;
    }

    function mint(uint256 amount) public payable nonReentrant {
        mintManager.checkCanMintPublic(msg.sender, msg.value, amount);

        for (uint256 i = 0; i < amount; ++i) {
            mintInternal(msg.sender);
        }

        uint256 balance = paintToken.balanceOf(address(this));
        if (balance >= mintPaintReward * amount) {
            paintToken.transfer(msg.sender, mintPaintReward * amount);
        }
    }

    function mintInitial(uint256 amountToMint) public nonReentrant onlyAdmin returns (uint256) {
        mintManager.checkCanMintInitial(amountToMint);
        for (uint256 i = 0; i < amountToMint; ++i) {
            mintInternal(msg.sender);
        }
    }

    function mintInternal(address account) private {
        require(totalSupply() <= MAX_SUPPLY, "Maximum number of NFTs minted");

        // create the grid contents
        GridContents memory _gridNft = GridContents({currentBlockNumber: 0});

        // push the grid nft to the array
        gridContents.push(_gridNft);
        uint256 _id = gridContents.length - 1;

        _mint(account, _id);
        emit GridNFTMinted(_id, account);
    }

    function withdrawFunds() public {
        // 80/20 split
        uint256 balance = address(this).balance;
        uint256 adminBalance = balance / 5;
        uint256 financeBalance = balance - adminBalance;

        (bool success, ) = majorShareAddress.call{value: financeBalance}("");
        (bool success2, ) = minorShareAddress.call{value: adminBalance}("");
        require(success && success2, "Failed to transfer the funds, aborting.");
    }

    function rescueTokens(address to, address tokenAddress) public {
        require(msg.sender == majorShareAddress, "Is not major share address");
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(IERC20(tokenAddress).transfer(to, balance), "rescueTokens: Transfer failed.");
    }

    function getCurrentGridContentsBlock(uint256 _tokenId) public view returns (uint256) {
        return gridContents[_tokenId].currentBlockNumber;
    }

    fallback() external payable {}

    receive() external payable {}
}
