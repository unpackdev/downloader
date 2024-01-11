// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";

import "./SignerRoleUpgradeable.sol";
import "./ERC721ProjectApproveTransferManager.sol";
import "./ProjectTokenURIManager.sol";
import "./ISimpleERC721Project.sol";

interface ISimpleFireworkPacketManager {
    function fireworkPacketProject() external view returns (address);
}

contract FireworkManager is
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

    struct FireInfo {
        uint16 fireDay;
        uint16 num;
    }

    /* ========== STATE VARIABLES ========== */
    uint256 public eventStartUnix;
    // eventEndUnix should be eventStartUnix time + 44 day + 9 hour
    uint256 public eventEndUnix;
    uint256 public totalMinted;
    uint256 public maxAdminMintTokens;
    uint256 public adminMinted;
    string public baseURI;
    ISimpleFireworkPacketManager public fireworkPacketManager;
    ISimpleERC721Project public fireworkProject;
    // tokenId => fireInfo
    mapping(uint256 => FireInfo) public tokenFireInfo;
    // fireDay => minted number
    mapping(uint16 => uint16) public fireDayNums;
    // after the event is over, we need to freeze the metadata to ipfs or ar, baseURI is frozenMetadataBaseURIs[fireDay-1]
    string[90] public frozenMetadataBaseURIs;
    bool public frozen;
    // prefix, like https://arweave.net/
    string public frozenMetadataPrefix;

    /* ========== EVENTs ========== */
    event LogSetBaseURI(string baseURI);
    event LogSetFireworkProject(address project);
    event LogSetFireworkPacketManager(address project);
    event LogFireworkMinted(address indexed user, uint256 tokenId, uint16 fireDay, uint16 num);
    event LogSetEventTimes(uint256 startTime, uint256 endTime);
    event LogSetFrozenBaseURIs(uint256 nums);
    event LogSetIsFrozenAndPrefix(bool isFrozen, string prefix);
    event LogSetMaxAdminMintTokens(uint256 maxAdminMintTokens);

    /* ========== INITIALIZER ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _fireworkProject,
        address _fireworkPacketManger,
        uint256 _eventStartUnix,
        uint256 _eventEndUnix,
        string memory _baseURI
    ) public initializer {
        __Ownable_init();
        __SignerRole_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        setFireworkProject(_fireworkProject);
        setFireworkPacketManager(_fireworkPacketManger);
        setEventTimes(_eventStartUnix, _eventEndUnix);
        setBaseURI(_baseURI);

        setMaxAdminMintTokens(360);

        totalMinted = 0;
        adminMinted = 0;
    }

    ///
    /// @notice Get the uri for a given project/tokenId
    ///
    function tokenURI(address project, uint256 tokenId) public view override returns (string memory) {
        require(project == address(fireworkProject), "FireworkManager: bad project");
        FireInfo storage fireInfo = tokenFireInfo[tokenId];
        require(fireInfo.fireDay != 0, "FireworkManager: token not exists");
        if (frozen) {
            return
                string(
                    abi.encodePacked(
                        frozenMetadataPrefix,
                        frozenMetadataBaseURIs[fireInfo.fireDay - 1],
                        "/",
                        uint256(fireInfo.num).toString()
                    )
                );
        }
        return
            string(
                abi.encodePacked(baseURI, uint256(fireInfo.fireDay).toString(), "/", uint256(fireInfo.num).toString())
            );
    }

    /// @dev called by fireworkPacketManager at #onBurn
    /// @param owner the owner of burned fireworkPacket
    /// @param fireworkPacketId should always be 1
    /// @param amount the amount of burned tokens
    /// @param fireDay the cailendar fire day
    /// @param sig should be the signature of keccak256(abi.encode(chainId, fireworkPacketProject, owner, fireworkPacketId, amount, fireDay));
    function mintFirework(
        address owner,
        uint256 fireworkPacketId,
        uint16 amount,
        uint16 fireDay,
        uint256 expireUnix,
        bytes calldata sig
    ) external nonReentrant whenNotPaused {
        // can only be called by fireworkPacketManager at #onBurn
        require(
            _msgSender() == address(fireworkPacketManager),
            "FireworkManager::mintFirework: not fireworkPacketManager"
        );
        require(block.timestamp <= expireUnix, "FireworkManager::mintFirework: tx expired");
        require(block.timestamp >= eventStartUnix, "FireworkManager::mintFirework: event not started yet");
        require(block.timestamp <= eventEndUnix, "FireworkManager::mintFirework: event has already ended");

        // 1. decode and check signature
        bytes32 messageHash = keccak256(
            abi.encode(
                block.chainid,
                fireworkPacketManager.fireworkPacketProject(),
                owner,
                fireworkPacketId,
                amount,
                fireDay,
                expireUnix
            )
        );
        require(_verifySignedMessage(messageHash, sig), "FireworkManager::mintFirework: proper signature is required");

        totalMinted += amount;
        // 3. mint and record tokenFiredDay and num
        for (uint16 i = 0; i < amount; i++) {
            uint256 fireworkId = fireworkProject.managerMint(owner, "");
            uint16 fireDayNum = fireDayNums[fireDay] + 1;
            fireDayNums[fireDay] = fireDayNum;
            tokenFireInfo[fireworkId] = FireInfo({fireDay: fireDay, num: fireDayNum});
            emit LogFireworkMinted(owner, fireworkId, fireDay, fireDayNum);
        }
    }

    function adminMint(address[] calldata recipients, uint16[] calldata fireDays) external onlyOwner {
        adminMinted += recipients.length;
        require(adminMinted <= maxAdminMintTokens, "exceeds maxAdminMintTokens");
        for (uint16 i = 0; i < recipients.length; i++) {
            uint256 fireworkId = fireworkProject.managerMint(recipients[i], "");
            uint16 fireDayNum = fireDayNums[fireDays[i]] + 1;
            fireDayNums[fireDays[i]] = fireDayNum;
            tokenFireInfo[fireworkId] = FireInfo({fireDay: fireDays[i], num: fireDayNum});
            emit LogFireworkMinted(recipients[i], fireworkId, fireDays[i], fireDayNum);
        }
    }

    function setFireworkPacketManager(address _fireworkPacketManager) public onlyOwner {
        require(_fireworkPacketManager != address(0), "bad _fireworkPacketManager");
        fireworkPacketManager = ISimpleFireworkPacketManager(_fireworkPacketManager);
        emit LogSetFireworkPacketManager(_fireworkPacketManager);
    }

    function setFireworkProject(address _project) public onlyOwner {
        require(_project != address(0), "bad project");
        fireworkProject = ISimpleERC721Project(_project);
        emit LogSetFireworkProject(_project);
    }

    function setEventTimes(uint256 _eventStartUnix, uint256 _eventEndUnix) public onlyOwner {
        eventStartUnix = _eventStartUnix;
        eventEndUnix = _eventEndUnix;
        emit LogSetEventTimes(_eventStartUnix, _eventEndUnix);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit LogSetBaseURI(_baseURI);
    }

    function setFrozenBaseURIs(string[] calldata baseURIs) external onlyOwner {
        require(baseURIs.length == 90, "bad length");
        for (uint16 i = 0; i < baseURIs.length; i++) {
            frozenMetadataBaseURIs[i] = baseURIs[i];
        }
        emit LogSetFrozenBaseURIs(baseURIs.length);
    }

    function setIsFrozenAndPrefix(bool isFrozen, string calldata prefix) external onlyOwner {
        frozen = isFrozen;
        frozenMetadataPrefix = prefix;
        emit LogSetIsFrozenAndPrefix(isFrozen, prefix);
    }

    function setMaxAdminMintTokens(uint256 tokens) public onlyOwner {
        maxAdminMintTokens = tokens;
        emit LogSetMaxAdminMintTokens(tokens);
    }

    /// @dev pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
