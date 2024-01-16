// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./SignerRoleUpgradeable.sol";
import "./WithTreasuryUpgradeable.sol";
import "./ProjectTokenURIManager.sol";

interface ISimpleERC721AProject {
    /**
     * @dev mint a token. Can only be called by manager.
     */
    function managerMint(address to) external returns (uint256);

    /**
     * @dev mint ${quantity} tokens. Can only be called by manager.
     */
    function managerMint(address to, uint256 quantity) external;
}

/// @title Interface for NFT buy-now in a fixed price.
/// @notice This is the interface for fixed price NFT buy-now.
contract AdminBuyNowManager is
    Initializable,
    ProjectTokenURIManager,
    WithTreasuryUpgradeable,
    SignerRoleUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    /* ========== STRUCTS ========== */
    struct BuyNowInfo {
        uint64 startTime;
        uint64 endTime;
        uint64 edition;
        uint64 purchaseLimit;
        uint256 price;
        ISimpleERC721AProject project;
        string baseURI;
    }

    struct EditionInfo {
        uint256 buyNowId;
        uint64 printEdition;
    }

    /* ========== STATE VARIABLES ========== */

    uint256 public nextId;
    /// @dev buyNowId => BuyNowInfo
    mapping(uint256 => BuyNowInfo) public buyNowInfos;
    /// @dev buyer => (buyNowId => purchaseCount)
    mapping(address => mapping(uint256 => uint256)) public buyerRecords;
    /// @dev buyNowId => purchaseCount
    mapping(uint256 => uint64) public saleCounts;
    /// @dev buyNowId => (position => edition)
    mapping(uint256 => mapping(uint64 => uint64)) private randomMatrix;
    /// @dev project => (tokenId => EditionInfo)
    mapping(address => mapping(uint256 => EditionInfo)) public projectTokenIdToEditionInfo;

    /* ========== EVENTs ========== */

    event BuyNowCreated(uint256 indexed buyNowId, BuyNowInfo info);
    event BuyNowUpdated(uint256 indexed buyNowId, BuyNowInfo info);
    event BuyNowBaseURIUpdated(uint256 indexed buyNowId, string baseURI);
    event AdminCancelBuyNow(uint256 indexed buyNowId, string reason);
    event Bought(
        uint256 indexed buyNowId,
        address indexed buyer,
        address project,
        uint256 tokenId,
        uint64 printEdition
    );
    event LogMintTo(
        uint256 indexed buyNowId,
        address indexed buyer,
        address project,
        uint256 tokenId,
        uint64 printEdition,
        bool recordNumber
    );

    /* ========== MODIFIERS ========== */

    /// @dev Require that the caller must be an EOA account if not whitelisted.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    modifier onlyValidConfig(BuyNowInfo calldata buyNowInfo) {
        require(
            buyNowInfo.endTime == 0 || buyNowInfo.endTime > buyNowInfo.startTime,
            "endTime should > startTime or = 0"
        );
        require(buyNowInfo.edition > 0, "bad edition");
        require(address(buyNowInfo.project).isContract(), "bad project address");
        require(bytes(buyNowInfo.baseURI).length > 0, "bad baseURI");
        _;
    }

    /* ========== INITIALIZER ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address treasuryAddress) public initializer {
        __Ownable_init();
        __WithTreasury_init();
        __SignerRole_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        setTreasury(payable(treasuryAddress));
        nextId = 1;
    }

    /* ========== VIEW FUNCTIONS ========== */
    /// @notice available tokens of a specific buyNow
    function availableTokens(uint256 buyNowId) public view returns (uint64) {
        return buyNowInfos[buyNowId].edition - saleCounts[buyNowId];
    }

    ///
    /// @notice Get the uri for a given project/tokenId
    ///
    function tokenURI(address project, uint256 tokenId) public view override returns (string memory) {
        EditionInfo storage editionInfo = projectTokenIdToEditionInfo[project][tokenId];

        require(editionInfo.printEdition > 0, "AdminBuyNowManager: nonexistent token");

        return
            string(
                abi.encodePacked(
                    buyNowInfos[editionInfo.buyNowId].baseURI,
                    uint256(editionInfo.printEdition).toString()
                )
            );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice buy one NFT token of specific artwork. Needs a proper signature of allowed signer to verify purchase.
    /// @param  _buyNowId uint256 the id of the buyNow artwork
    /// @param  v uint8 v of the signature
    /// @param  r bytes32 r of the signature
    /// @param  s bytes32 s of the signature
    function buyNow(
        uint256 _buyNowId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable onlyEOA nonReentrant whenNotPaused {
        // 1. check status first, saving gas if is sold out or over
        BuyNowInfo storage buyNowInfo = buyNowInfos[_buyNowId];
        require(buyNowInfo.edition > 0, "ProjectBuyNowManager: not on sale");
        require(buyNowInfo.edition > saleCounts[_buyNowId], "ProjectBuyNowManager: sold out");
        require(buyNowInfo.startTime <= block.timestamp, "ProjectBuyNowManager: not started yet");
        require(
            buyNowInfo.endTime == 0 || buyNowInfo.endTime >= block.timestamp,
            "ProjectBuyNowManager: already ended"
        );
        require(buyNowInfo.price == msg.value, "ProjectBuyNowManager: ETH amount should match price");

        // 2. check purchase limit, and increase buyer record. check before signature to save gas if reach limit
        uint256 alreadyBought = buyerRecords[_msgSender()][_buyNowId]++;
        require(
            buyNowInfo.purchaseLimit == 0 || alreadyBought < buyNowInfo.purchaseLimit,
            "ProjectBuyNowManager: you have reached purchase limit"
        );

        // 3. check signature
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender(), _buyNowId));
        require(_verifySignedMessage(messageHash, v, r, s), "ProjectBuyNowManager: proper signature is required");

        // 4. get random print edition
        uint64 randomPrintEdition = _getPrintEdition(_buyNowId, buyNowInfo.edition, saleCounts[_buyNowId]);
        saleCounts[_buyNowId]++;

        _sendETHToTreasury(buyNowInfo.price);

        // 5. mint token to the buyer, uri is empty because it's controlled by #ProjectBuyNowManager.tokenURI function
        uint256 tokenId = buyNowInfo.project.managerMint(_msgSender());
        // 6. record edition info
        projectTokenIdToEditionInfo[address(buyNowInfo.project)][tokenId] = EditionInfo({
            buyNowId: _buyNowId,
            printEdition: randomPrintEdition
        });

        emit Bought(_buyNowId, _msgSender(), address(buyNowInfo.project), tokenId, randomPrintEdition);
    }

    // for MoonPay NFT checkout or admin mint AP
    function mintTo(
        uint256 _buyNowId,
        address to,
        bool recordNumber
    ) external onlySigner whenNotPaused {
        // 1. check status first, saving gas if is sold out or over
        BuyNowInfo storage buyNowInfo = buyNowInfos[_buyNowId];
        require(buyNowInfo.edition > 0, "ProjectBuyNowManager: not on sale");
        uint64 sold = saleCounts[_buyNowId];
        require(buyNowInfo.edition > sold, "ProjectBuyNowManager: sold out");
        require(buyNowInfo.startTime <= block.timestamp, "ProjectBuyNowManager: not started yet");
        require(
            buyNowInfo.endTime == 0 || buyNowInfo.endTime >= block.timestamp,
            "ProjectBuyNowManager: already ended"
        );

        // 2. check purchase limit, and increase buyer record. check before signature to save gas if reach limit
        if (recordNumber) {
            uint256 alreadyBought = buyerRecords[to][_buyNowId]++;
            require(
                buyNowInfo.purchaseLimit == 0 || alreadyBought < buyNowInfo.purchaseLimit,
                "ProjectBuyNowManager: you have reached purchase limit"
            );
        }

        // 3. get random print edition
        uint64 randomPrintEdition = _getPrintEdition(_buyNowId, buyNowInfo.edition, sold);
        saleCounts[_buyNowId] = sold + 1;

        // 4. mint token to the buyer, uri is empty because it's controlled by #ProjectBuyNowManager.tokenURI function
        uint256 tokenId = buyNowInfo.project.managerMint(to);

        // 5. record edition info
        projectTokenIdToEditionInfo[address(buyNowInfo.project)][tokenId] = EditionInfo({
            buyNowId: _buyNowId,
            printEdition: randomPrintEdition
        });

        // MoonPay buyNow
        if (recordNumber) {
            emit Bought(_buyNowId, to, address(buyNowInfo.project), tokenId, randomPrintEdition);
        }
        emit LogMintTo(_buyNowId, to, address(buyNowInfo.project), tokenId, randomPrintEdition, recordNumber);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice admin setup a buy-now artwork
    function createBuyNow(BuyNowInfo calldata info) external onlyValidConfig(info) onlyOwner {
        uint256 buyNowId = _getNextAndIncrementId();
        buyNowInfos[buyNowId] = info;
        emit BuyNowCreated(buyNowId, info);
    }

    /// @notice admin can update buy now info if not started already
    function updateBuyNow(uint256 _buyNowId, BuyNowInfo calldata newInfo) external onlyValidConfig(newInfo) onlyOwner {
        BuyNowInfo storage info = buyNowInfos[_buyNowId];
        require(info.edition > 0, "no buyNow info");
        buyNowInfos[_buyNowId] = newInfo;
        emit BuyNowUpdated(_buyNowId, newInfo);
    }

    function updateBuyNowBaseURI(uint256 _buyNowId, string calldata _baseURI) external onlyOwner {
        buyNowInfos[_buyNowId].baseURI = _baseURI;
        emit BuyNowBaseURIUpdated(_buyNowId, _baseURI);
    }

    /**
     * @notice Allows TR Lab to cancel a buyNow. If it's not started yet, it can be canceled directly.
     * If it's already started, the reason must be provided.
     * This should only be used for extreme cases such as DMCA takedown requests.
     */
    function adminCancelBuyNow(uint256 _buyNowId, string calldata reason) external onlyOwner {
        BuyNowInfo storage info = buyNowInfos[_buyNowId];
        require(info.edition > 0, "no buyNow info");
        require(block.timestamp < info.startTime || bytes(reason).length > 0, "Include a reason for this cancellation");
        delete buyNowInfos[_buyNowId];
        emit AdminCancelBuyNow(_buyNowId, reason);
    }

    /// @dev pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    function _getNextAndIncrementId() internal returns (uint256) {
        return nextId++;
    }

    /**
     * @dev Returns a random printEdition
     *
     *  a variety of Fisher-Yates Shuffle: https://bost.ocks.org/mike/shuffle/
     *  imagine we have a array of *total* numbers, from 0 to *total - 1*.
     *  initially, each index and it's value are the same, meaning index 0 is 0, index 1 is 1, and so on.
     *  each shuffle iteration swaps a random number with the tail of the array, changing one of the mapping relationship of index to value.
     *  randomMatrix[_buyNowId] is a mapping to record the relationship of index to value.
     * Code used as reference:
     * https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol
     */
    function _getPrintEdition(
        uint256 _buyNowId,
        uint64 _totalEdition,
        uint64 _mintedEdition
    ) private returns (uint64) {
        // 1. maxIndex shrinks every function call, should make sure _mintedEdition increases by one
        uint64 maxIndex = _totalEdition - _mintedEdition - 1;
        // 2. get a random index in the range of [0, maxIndex]
        uint64 randomIndex = _getRandomNumber(maxIndex + 1, _mintedEdition);
        mapping(uint64 => uint64) storage tokenMatrix = randomMatrix[_buyNowId];

        // the random value we need at the randomIndex
        uint64 printEdition = tokenMatrix[randomIndex];

        // 3. check if the random index is selected before
        if (tokenMatrix[randomIndex] == 0) {
            // if the random index is not selected, the value at this position is the same as the position index itself
            printEdition = randomIndex;
        }

        // 4. find the value at tail of the shrunk array.
        // if maxIndex is selected before, use the value at maxIndex's position.
        uint64 tailValue = tokenMatrix[maxIndex];
        // if maxIndex is not selected, the value is maxIndex it self
        if (tailValue == 0) {
            tailValue = maxIndex;
        }
        // 5. swap the tail value to the randomIndex position.
        // because we record the random printEdition already, we do not care about the tail of the array.
        // so only move the tail to randomIndex, no need to move the printEdition to tail.
        tokenMatrix[randomIndex] = tailValue;

        // print edition starts from 1
        return printEdition + 1;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint64 _upper, uint64 _mintedEdition) private view returns (uint64) {
        uint64 random = uint64(
            uint256(
                keccak256(abi.encodePacked(_mintedEdition, blockhash(block.number - 1), block.coinbase, _msgSender()))
            )
        );

        return random % _upper;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
