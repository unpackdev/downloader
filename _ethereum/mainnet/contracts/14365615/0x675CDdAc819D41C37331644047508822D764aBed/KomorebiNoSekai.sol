// SPDX-License-Identifier: Apache-2.0
// 人類の反撃はこれからだ。
// jinrui no hangeki wa kore kara da.

// Source code heavily inspired from deployed contract instance of Azuki collection
// https://etherscan.io/address/0xed5af388653567af2f388e6224dc7c4b3241c544#code
// The source code in the github does not have some important features.
// This is why we used directly the code from the deployed version.
pragma solidity >=0.8.12;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

import "./ERC721A.sol";
import "./VRFConsumerBase.sol";

/// @title KomorebiNoSekai NFT collection
/// @author 0xmanga-eth
contract KomorebiNoSekai is Ownable, ERC721A, ReentrancyGuard, VRFConsumerBase {
    using SafeMath for uint256;

    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;

    address public constant AZUKI_ADDRESS = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;

    string constant ERROR_NOT_ENOUGH_LINK = "not enough LINK";

    // Furaribi (ふらり火, Furaribi) are the ghost of those murdered
    // in cold blood by an angry samurai.
    // They get their namesake from them wandering
    // aimlessly around the edges of lakes and rivers.
    uint8 public constant FURARIBI_SIDE = 1;

    // ナイト Naito (from english: "Knight")
    // ライト Raito (from english: "Light")
    // They fight against Furaribi spirits to protect humans.
    uint8 public constant NAITO_RAITO_SIDE = 2;

    struct SaleConfig {
        uint32 whitelistSaleStartTime;
        uint32 saleStartTime;
        uint64 mintlistPrice;
        uint64 price;
    }

    struct Gift {
        address collectionAddress;
        uint256[] ids;
    }

    // The sale configuration
    SaleConfig public saleConfig;
    // Whitelisted addresses
    mapping(address => uint8) public _allowList;
    // Whitelisted NFT collections
    address[] public _whitelistedCollections;
    // Per user assigned side
    mapping(address => uint8) private _side;

    // The winner NFT id
    uint256 public giftsWinnerTokenId;
    // The winner of the gifts
    address public giftsWinnerAddress;
    // The list of NFT gifts
    Gift[] public gifts;
    // The chainlink request id for VRF
    bytes32 selectRandomGiftWinnerRequestId;

    // Chainlink configuration
    address _vrfCoordinator;
    address _linkToken;
    bytes32 _vrfKeyHash;
    uint256 _vrfFee;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForDevs_,
        address vrfCoordinator_,
        address linkToken_,
        bytes32 vrfKeyHash_,
        uint256 vrfFee_
    ) ERC721A("Komorebi No Sekai", "KNS", maxBatchSize_, collectionSize_) VRFConsumerBase(vrfCoordinator_, linkToken_) {
        maxPerAddressDuringMint = maxBatchSize_;
        amountForDevs = amountForDevs_;
        _vrfCoordinator = vrfCoordinator_;
        _linkToken = linkToken_;
        _vrfKeyHash = vrfKeyHash_;
        _vrfFee = vrfFee_;
    }

    /// @notice Buy a quantity of NFTs during the whitelisted sale.
    /// @dev Throws if user is not whitelisted.
    function allowlistMint() external payable callerIsUser {
        uint256 price = uint256(saleConfig.mintlistPrice);
        uint256 whitelistSaleStartTime = uint256(saleConfig.whitelistSaleStartTime);
        assignSideIfNoSide(msg.sender);
        require(getCurrentTime() >= whitelistSaleStartTime, "allowlist sale has not begun yet");
        require(price != 0, "allowlist sale has not begun yet");
        require(isWhitelisted(msg.sender), "not eligible for allowlist mint");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        if (_allowList[msg.sender] > 0) {
            _allowList[msg.sender]--;
        }
        _safeMint(msg.sender, 1);
        refundIfOver(price);
    }

    /// @notice Buy a quantity of NFTs during the public primary sale.
    /// @param quantity The number of items to mint.
    function saleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(config.price);
        uint256 saleStartTime = uint256(config.saleStartTime);
        assignSideIfNoSide(msg.sender);
        require(isPublicSaleOn(price, saleStartTime), "public sale has not begun yet");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }

    /// @notice Mint NFTs for dev team.
    /// @dev For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= amountForDevs, "too many already minted before dev mint");
        require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    /// @notice Refund the difference if user sent more than the specified price.
    /// @param price The correct price.
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /// @notice Return whether or not the public sale is live.
    /// @param priceWei The price set in WEI.
    /// @param saleStartTime The start time set.
    /// @return true if public sale is live, false otherwise.
    function isPublicSaleOn(uint256 priceWei, uint256 saleStartTime) public view returns (bool) {
        return priceWei != 0 && getCurrentTime() >= saleStartTime;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /// @notice Add addresses to allow list.
    /// @param addresses The account addresses to whitelist.
    /// @param numAllowedToMint The number of allowed NFTs to mint per address.
    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    // // metadata URI
    string private _baseTokenURI;

    /// @notice Return the current base URI.
    /// @return The current base URI.
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set the base URI for the collection.
    /// @dev Can be used to handle a reveal separately.
    /// @param baseURI The new base URI.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Withdraw ETH from the contract.
    /// @dev Only owner can call this function.
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    /// @notice Return the number of minted NFTs for a given address.
    /// @param owner The address of the owner.
    /// @return The number of minted NFTs.
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice Get ownership data.
    /// @param tokenId The token id.
    /// @return The `TokenOwnership` structure data associated to the token id.
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    /// @notice Return the current time.
    /// @dev Can be extended for testing purpose.
    /// @return The current timestamp.
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice Set whitelist sale start time.
    /// @param whitelistSaleStartTime_ The start time as a timestamp.
    function setWhitelistSaleStartTime(uint32 whitelistSaleStartTime_) external onlyOwner {
        SaleConfig storage config = saleConfig;
        config.whitelistSaleStartTime = whitelistSaleStartTime_;
    }

    /// @notice Set public sale start time.
    /// @param saleStartTime_ The start time as a timestamp.
    function setSaleStartTime(uint32 saleStartTime_) external onlyOwner {
        SaleConfig storage config = saleConfig;
        config.saleStartTime = saleStartTime_;
    }

    /// @notice Set current price for whitelisted sale.
    /// @param mintlistPrice_ The price in WEI.
    function setMintlistPrice(uint64 mintlistPrice_) external onlyOwner {
        SaleConfig storage config = saleConfig;
        config.mintlistPrice = mintlistPrice_;
    }

    /// @notice Set current price for public sale.
    /// @param price_ The price in WEI.
    function setPrice(uint64 price_) external onlyOwner {
        SaleConfig storage config = saleConfig;
        config.price = price_;
    }

    /// @notice Return the side of `msg.sender`.
    /// @return The side.
    function getMySide() public view returns (uint8) {
        return getSide(msg.sender);
    }

    /// @notice Return the side of a specified address.
    /// @return The side.
    function getSide(address account) public view returns (uint8) {
        return _side[account];
    }

    /// @notice Return whether or not the specified address is assigned to a side.
    /// @return true if assigned, false otherwise.
    function hasSide(address account) public view returns (bool) {
        return _side[account] != 0;
    }

    /// @notice Assign a side to the specified address if not assigned yet.
    /// @param account The address to assign a side to.
    function assignSideIfNoSide(address account) internal {
        if (!hasSide(account)) {
            assignSide(account);
        }
    }

    /// @notice Assign a side to the specified address.
    /// @dev Throws if address has already a side assigned.
    /// @param account The address to assign a side to.
    function assignSide(address account) internal {
        require(!hasSide(account), "Account already assigned to a side");
        uint8 side;
        uint256 seed = uint256(getSeed());
        if (uint8(seed) % 2 == 0) {
            side = FURARIBI_SIDE;
        } else {
            side = NAITO_RAITO_SIDE;
        }
        _side[account] = side;
    }

    /// @notice Assign a side to `msg.sender`
    function assignMeASide() external {
        assignSideIfNoSide(msg.sender);
    }

    /// @notice Compute a new seed to serve for simple and non sensitive pseudo random use cases.
    /// @return The seed to use.
    function getSeed() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.basefee, gasleft(), msg.sender, totalSupply()));
    }

    /// @notice Whitelist holders of specific collection NFTs.
    /// @param collectionAddress The address of the collection.
    function whitelistHoldersOfCollection(address collectionAddress) external onlyOwner {
        _whitelistedCollections.push(collectionAddress);
    }

    /// @notice Whitelist holders of Azuki NFTs.
    function whitelistAzukiHolders() external onlyOwner {
        _whitelistedCollections.push(AZUKI_ADDRESS);
    }

    /// @notice Return whether or not the specified account is whitelisted.
    /// @param account The address to check.
    /// @return true if whitelisted, false otherwise.
    function isWhitelisted(address account) internal view returns (bool) {
        if (_allowList[account] > 0) {
            return true;
        }
        for (uint256 i = 0; i < _whitelistedCollections.length; i++) {
            IERC721 nftCollection = IERC721(_whitelistedCollections[i]);
            if (nftCollection.balanceOf(account) > 0) {
                return true;
            }
        }
        return false;
    }

    /// @notice Send NFT gifts to the selected winner.
    /// @dev Throws if the winner is not selected yet.
    function sendGiftsToWinner() external onlyIfWinnerSelected onlyOwner {
        for (uint256 i = 0; i < gifts.length; i++) {
            Gift memory gift = gifts[i];
            IERC721 collection = IERC721(gift.collectionAddress);
            uint256[] memory ids = gift.ids;
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                collection.safeTransferFrom(address(this), giftsWinnerAddress, id);
            }
        }
    }

    modifier onlyIfWinnerSelected() {
        require(giftsWinnerAddress != address(0x0), "winner must be selected");
        _;
    }

    /// @notice Select a random winner using Chainlink VRF.
    function selectRandomWinnerForGifts() external onlyOwner {
        require(giftsWinnerAddress == address(0x0), "winner already selected");
        selectRandomGiftWinnerRequestId = requestRandomness(_vrfKeyHash, _vrfFee);
    }

    /// @notice Withdraw Link
    /// @dev See chainlink documentation.
    function withdrawLink() external onlyOwner {
        IERC20 erc20 = IERC20(_linkToken);
        uint256 linkBalance = LINK.balanceOf(address(this));
        if (linkBalance > 0) {
            erc20.transfer(owner(), linkBalance);
        }
    }

    modifier requireFeeForLinkRequest() {
        require(LINK.balanceOf(address(this)) >= _vrfFee, ERROR_NOT_ENOUGH_LINK);
        _;
    }

    /// @dev See `VRFConsumerBase` documentation.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (requestId == selectRandomGiftWinnerRequestId && giftsWinnerAddress == address(0x0)) {
            giftsWinnerTokenId = randomness.mod(totalSupply());
            giftsWinnerAddress = ownerOf(giftsWinnerTokenId);
        }
    }

    /// @notice Add gift to the list of gifts.
    /// @param collectionAddress Address of the NFT collection.
    /// @param ids The list of token ids.
    function addGift(address collectionAddress, uint256[] calldata ids) external {
        gifts.push(Gift(collectionAddress, ids));
    }

    /// @notice Update VRF fee.
    function updateVRFFee(uint256 fee) external onlyOwner {
        _vrfFee = fee;
    }
}
