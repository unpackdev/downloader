// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeCastUpgradeable.sol";

import "./SignerRoleUpgradeable.sol";
import "./ERC1155ProjectBurnableManager.sol";
import "./ProjectTokenURIManager.sol";
import "./ISimpleERC721Project.sol";
import "./ISimpleERC1155Project.sol";

interface IFireworkManager {
    function mintFirework(
        address owner,
        uint256 fireworkPacketId,
        uint16 amount,
        uint16 fireDay,
        uint256 expireUnix,
        bytes calldata data
    ) external;
}

contract FireworkPacketManager is
    ERC1155ProjectBurnableManager,
    ProjectTokenURIManager,
    Initializable,
    OwnableUpgradeable,
    SignerRoleUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */
    uint256 public maxTokens;
    uint256 public totalMinted;
    uint256 public phaseGapEndTime;
    uint256 public phaseRound1EndTime;
    uint256 public phaseRound2EndTime;
    uint256 public phasePublicEndTime;
    uint256 public constant fireworkPacketId = 1; // tokenId for ERC1155
    // round1 mint limit - formed by 3 tiers: tier1 holders, tier2 friends, tier3 AL
    uint16 public tier1MintLimit;
    uint16 public tier2MintLimit;
    uint16 public tier3MintLimit;
    // round2 mint limit
    uint16 public round2MintLimit;
    // public mint limit
    uint16 public publicMintLimit;
    uint256 public normalPrice;

    string public fireworkPacketURI;
    ISimpleERC1155Project public fireworkPacketProject;
    IFireworkManager public fireworkManager;
    // allow list user => minted, for both round1 and round2
    mapping(address => uint16) public allowListMinted;
    // user => minted
    mapping(address => uint16) public publicMinted;

    /* ========== EVENTs ========== */
    event LogSetFireworkPacketURI(string fireworkPacketURI);
    event LogSetMaxTokens(uint256 maxTokens);
    event LogSetFireworkManager(address project);
    event LogSetFireworkPacketProject(address project);
    event LogSetMintTimes(
        uint256 phaseGapEndTime,
        uint256 phaseRound1EndTime,
        uint256 phaseRound2EndTime,
        uint256 phasePublicEndTime
    );

    event LogFireworkPacketMinted(address indexed user, uint256 fireworkPacketId, uint16 amount);
    event LogAdminMinted(address[] recipients, uint16 amount);
    event LogSetMintLimitAndPrice(
        uint16 tier1MintLimit,
        uint16 tier2MintLimit,
        uint16 tier3MintLimit,
        uint16 round2MintLimit,
        uint16 publicMintLimit,
        uint256 price
    );
    /* ========== MODIFIERS ========== */

    /// @dev Require that the caller must be an EOA account
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    /* ========== INITIALIZER ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _fireworkPacketProject,
        uint256 _phaseGapEndTime,
        uint256 _phaseRound1EndTime,
        uint256 _phaseRound2EndTime,
        uint256 _publicEndTime,
        uint256 _maxTokens,
        string memory _fireworkPacketURI
    ) public initializer {
        __Ownable_init();
        __SignerRole_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        // set variables
        setFireworkPacketProject(_fireworkPacketProject);
        setMintTimes(_phaseGapEndTime, _phaseRound1EndTime, _phaseRound2EndTime, _publicEndTime);
        setMaxTokens(_maxTokens);
        setFireworkPacketURI(_fireworkPacketURI);
        totalMinted = 0;

        setMintLimitAndPrice(2, 2, 1, 1, 1, 0.18 ether);
    }

    ///
    /// @notice Get the uri for a given project/tokenId
    ///
    function tokenURI(address project, uint256 tokenId) public view override returns (string memory) {
        require(project == address(fireworkPacketProject), "FireworkPacketManager: bad project");
        require(tokenId == fireworkPacketId, "FireworkPacketManager: bad tokenId");
        return fireworkPacketURI;
    }

    function round1MintLimitAndPrice(uint16 tier) public view returns (uint16, uint256) {
        if (tier == 1) {
            return (tier1MintLimit, normalPrice / 2);
        } else if (tier == 2) {
            return (tier2MintLimit, normalPrice);
        } else {
            return (tier3MintLimit, normalPrice);
        }
    }

    /// @notice available tokens
    function availableTokens() public view returns (uint256) {
        return maxTokens - totalMinted;
    }

    // round1: holders and AL
    function round1Mint(
        uint16 num,
        uint16 tier,
        bytes calldata sig
    ) external payable onlyEOA nonReentrant whenNotPaused {
        // 1. check status first
        require(block.timestamp >= phaseGapEndTime, "not started yet");
        require(block.timestamp < phaseRound1EndTime, "round1 mint already ended");
        require(num > 0, "bad num");
        require(tier > 0 && tier <= 3, "bad tier");

        // 1 in the sigMessage is for round1
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender(), 1, num, tier));
        require(_verifySignedMessage(messageHash, sig), "proper signature is required");

        totalMinted += num;
        require(totalMinted <= maxTokens, "exceeds maxTokens");

        // 2. check minted and value
        uint16 alreadyMinted = allowListMinted[_msgSender()];
        (uint16 mintLimit, uint256 mintPrice) = round1MintLimitAndPrice(tier);
        require(alreadyMinted + num <= mintLimit, "reached purchase limit");
        allowListMinted[_msgSender()] = alreadyMinted + num;
        require(msg.value >= num * mintPrice, "ETH value too low");

        // 3. mint tokens
        _doMint(_msgSender(), num);
    }

    // round2: ticket minters
    function round2Mint(uint16 num, bytes calldata sig) external payable onlyEOA nonReentrant whenNotPaused {
        // 1. check status first
        require(block.timestamp >= phaseRound1EndTime, "not started yet");
        require(block.timestamp < phaseRound2EndTime, "round2 mint already ended");
        require(num > 0, "bad num");

        // 2 in the sigMessage is for round2
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender(), 2, num));
        require(_verifySignedMessage(messageHash, sig), "proper signature is required");

        totalMinted += num;
        require(totalMinted <= maxTokens, "exceeds maxTokens");

        // 2. check minted and value
        uint16 alreadyMinted = allowListMinted[_msgSender()];
        require(alreadyMinted + num <= round2MintLimit, "reached purchase limit");
        allowListMinted[_msgSender()] = alreadyMinted + num;
        require(msg.value >= num * normalPrice, "ETH value too low");

        // 3. mint tokens
        _doMint(_msgSender(), num);
    }

    function publicMint(uint16 num, bytes calldata sig) external payable onlyEOA nonReentrant whenNotPaused {
        // 1. check status
        _publicMintCheck(num);
        // 2. check sig, 3 in the sigMessage is for #publicMint
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender(), 3, num));
        require(_verifySignedMessage(messageHash, sig), "proper signature is required");

        // 3. mint tokens
        address[] memory to = new address[](1);
        to[0] = _msgSender();
        fireworkPacketProject.managerMintBatch(
            to,
            _asSingletonArray(fireworkPacketId),
            _asSingletonArray(num),
            abi.encode(0)
        );
        emit LogFireworkPacketMinted(_msgSender(), fireworkPacketId, num);
    }

    function adminMint(address[] calldata recipients, uint16 amount) external onlyOwner {
        totalMinted += recipients.length * amount;
        require(totalMinted <= maxTokens, "FireworkPacketManager: exceeds max tokens");
        fireworkPacketProject.managerMintBatch(
            recipients,
            _asSingletonArray(fireworkPacketId),
            _asSingletonArray(amount),
            abi.encode(0)
        );
        emit LogAdminMinted(recipients, amount);
    }

    /// @dev used in phase3, if any packets left, user may use this function to buy packet and burn it for firework at a single tx.
    /// may not be used
    function publicMintAndFire(uint16 num, bytes calldata data) external payable onlyEOA nonReentrant whenNotPaused {
        _publicMintCheck(num);
        (uint16 fireDay, uint256 expireUnix, bytes memory sig) = abi.decode(data, (uint16, uint256, bytes));

        // sig and time check will be done in #mintFirework
        fireworkManager.mintFirework(_msgSender(), fireworkPacketId, num, fireDay, expireUnix, sig);
    }

    /**
     * @dev callback handler for burn events
     */
    function onBurn(
        address owner,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override {
        require(_msgSender() == address(fireworkPacketProject), "FireworkPacketManager: not fireworkPacketProject");
        require(tokenIds.length == 1, "FireworkPacketManager: tokenIds.length not 1");
        (uint16 fireDay, uint256 expireUnix, bytes memory sig) = abi.decode(data, (uint16, uint256, bytes));
        // sig and time check will be done in #mintFirework
        fireworkManager.mintFirework(
            owner,
            tokenIds[0],
            SafeCastUpgradeable.toUint16(amounts[0]),
            fireDay,
            expireUnix,
            sig
        );
    }

    function setMintLimitAndPrice(
        uint16 _tier1MintLimit,
        uint16 _tier2MintLimit,
        uint16 _tier3MintLimit,
        uint16 _round2MintLimit,
        uint16 _publicMintLimit,
        uint256 price
    ) public onlyOwner {
        tier1MintLimit = _tier1MintLimit;
        tier2MintLimit = _tier2MintLimit;
        tier3MintLimit = _tier3MintLimit;
        round2MintLimit = _round2MintLimit;
        publicMintLimit = _publicMintLimit;
        normalPrice = price;
        emit LogSetMintLimitAndPrice(
            _tier1MintLimit,
            _tier2MintLimit,
            _tier3MintLimit,
            _round2MintLimit,
            _publicMintLimit,
            price
        );
    }

    function setFireworkManager(address _fireworkManager) public onlyOwner {
        require(_fireworkManager != address(0), "bad project");
        fireworkManager = IFireworkManager(_fireworkManager);
        emit LogSetFireworkManager(_fireworkManager);
    }

    function setFireworkPacketProject(address _project) public onlyOwner {
        require(_project != address(0), "bad project");
        fireworkPacketProject = ISimpleERC1155Project(_project);
        emit LogSetFireworkPacketProject(_project);
    }

    function setMintTimes(
        uint256 _phaseGapEndTime,
        uint256 _phaseRound1EndTime,
        uint256 _phaseRound2EndTime,
        uint256 _publicEndTime
    ) public onlyOwner {
        require(_phaseGapEndTime < _phaseRound1EndTime, "bad round1/2 times");
        require(_phaseRound1EndTime < _phaseRound2EndTime, "bad round2/public times");
        require(_publicEndTime == 0 || _phaseRound2EndTime < _publicEndTime, "bad public/end times");
        phaseGapEndTime = _phaseGapEndTime;
        phaseRound1EndTime = _phaseRound1EndTime;
        phaseRound2EndTime = _phaseRound2EndTime;
        phasePublicEndTime = _publicEndTime;
        emit LogSetMintTimes(_phaseGapEndTime, _phaseRound1EndTime, _phaseRound2EndTime, _publicEndTime);
    }

    function setFireworkPacketURI(string memory _fireworkPacketURI) public onlyOwner {
        fireworkPacketURI = _fireworkPacketURI;
        emit LogSetFireworkPacketURI(_fireworkPacketURI);
    }

    function setMaxTokens(uint256 _maxTokens) public onlyOwner {
        maxTokens = _maxTokens;
        emit LogSetMaxTokens(_maxTokens);
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _doMint(address mintTo, uint16 num) internal {
        address[] memory to = new address[](1);
        to[0] = mintTo;
        fireworkPacketProject.managerMintBatch(
            to,
            _asSingletonArray(fireworkPacketId),
            _asSingletonArray(num),
            abi.encode(0)
        );
        emit LogFireworkPacketMinted(mintTo, fireworkPacketId, num);
    }

    // check for public mint
    function _publicMintCheck(uint16 num) internal {
        // 1. check status first
        require(block.timestamp >= phaseRound2EndTime, "not started yet");
        require(phasePublicEndTime == 0 || block.timestamp <= phasePublicEndTime, "already ended");
        require(num > 0, "bad num");
        // 1.1 if user minted to limit
        uint16 minted = publicMinted[_msgSender()];
        require(minted + num <= publicMintLimit, "cannot purchase that much");
        publicMinted[_msgSender()] = minted + num;

        // 1.2 if reached global limit
        totalMinted += num;
        require(totalMinted <= maxTokens, "exceeds maxTokens");
        // 2. check value
        require(msg.value >= num * normalPrice, "ETH value too low");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155ProjectBurnableManager, ProjectTokenURIManager)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawTo(address payable _to, uint256 amount) public onlyOwner {
        AddressUpgradeable.sendValue(_to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
