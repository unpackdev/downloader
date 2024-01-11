// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";

import "./SignerRoleUpgradeable.sol";
import "./ProjectTokenURIManager.sol";
import "./ISimpleERC721Project.sol";

contract ImagineThisManager is
    ProjectTokenURIManager,
    Initializable,
    OwnableUpgradeable,
    SignerRoleUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /* ========== STATE VARIABLES ========== */
    ISimpleERC721Project public fireworkProject;
    ISimpleERC721Project public imgProject;
    uint8 public maxReserveTokens;
    uint8 public burnAmount;
    uint256 public startTime;
    uint256 public softEndTime;
    uint256 public hardEndTime;
    uint256 public extensionDuration;
    string public baseURI;

    uint8 public adminMinted;
    /* ========== EVENTs ========== */
    event LogSetBaseURI(string baseURI);
    event LogSetMaxReserveTokens(uint8 maxTokensReserve);
    event LogSetBurnAmount(uint8 burnAmount);
    event LogSetFireworkProject(address project);
    event LogSetImgProject(address project);
    event LogRedeem(address owner, uint256 tokenId, uint256[] fireworkTokenIds);
    event LogAdminMint(address owner, uint256 tokenId);
    event LogSetTimeConfig(uint256 startTime, uint256 softEndTime, uint256 hardEndTime, uint256 expansionDuration);

    /// @dev Require that the caller must be an EOA account
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    /* ========== INITIALIZER ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _fireworkProject,
        address _imgProject,
        uint8 _maxReserveTokens,
        uint8 _burnAmount,
        uint256 _startTime,
        uint256 _softEndTime,
        uint256 _hardEndTime,
        uint256 _extensionDuration,
        string memory _baseURI
    ) public initializer {
        __Ownable_init();
        __SignerRole_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        setFireworkProject(_fireworkProject);
        setImgProject(_imgProject);
        setMaxReserveTokens(_maxReserveTokens);
        setBurnAmount(_burnAmount);
        setTimeConfig(_startTime, _softEndTime, _hardEndTime, _extensionDuration);
        setBaseURI(_baseURI);
    }

    ///
    /// @notice Get the uri for a given project/tokenId
    ///
    function tokenURI(address project, uint256 tokenId) public view override returns (string memory) {
        require(project == address(imgProject), "imgManager: bad project");
        return string(abi.encodePacked(baseURI, toString(tokenId)));
    }

    function redeem(uint256[] calldata fireworkTokenIds, bytes calldata sig)
        external
        onlyEOA
        nonReentrant
        whenNotPaused
    {
        // 1. check time
        require(block.timestamp >= startTime, "not started yet");
        uint256 _softEndTime = softEndTime;
        require(block.timestamp <= _softEndTime, "event already ended");
        if (_softEndTime - block.timestamp < extensionDuration && _softEndTime < hardEndTime) {
            _softEndTime = block.timestamp + extensionDuration;
            // extend soft end one more hour or to hard cap
            softEndTime = _softEndTime > hardEndTime ? hardEndTime : _softEndTime;
        }
        // 3. check signature
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender(), fireworkTokenIds));
        require(_verifySignedMessage(messageHash, sig), "proper signature is required");
        require(fireworkTokenIds.length == burnAmount, "bad fireworkTokenIds.length");
        fireworkProject.managerBurnBatch(_msgSender(), fireworkTokenIds);

        // 4. mint IMG NFT
        uint256 tokenId = imgProject.managerMint(_msgSender(), "");
        emit LogRedeem(_msgSender(), tokenId, fireworkTokenIds);
    }

    function adminMint(uint8 amount, address to) external onlyOwner {
        require(amount > 0, "bad amount");
        require(to != address(0), "bad to");
        uint8 newAdminMinted = adminMinted + amount;
        require(newAdminMinted <= maxReserveTokens, "all tokens minted");
        adminMinted = newAdminMinted;
        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = imgProject.managerMint(to, "");
            emit LogAdminMint(to, tokenId);
        }
    }

    function setFireworkProject(address _project) public onlyOwner {
        require(_project != address(0), "bad project");
        fireworkProject = ISimpleERC721Project(_project);
        emit LogSetFireworkProject(_project);
    }

    function setImgProject(address _project) public onlyOwner {
        require(_project != address(0), "bad project");
        imgProject = ISimpleERC721Project(_project);
        emit LogSetImgProject(_project);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit LogSetBaseURI(_baseURI);
    }

    function setMaxReserveTokens(uint8 _maxReserveTokens) public onlyOwner {
        maxReserveTokens = _maxReserveTokens;
        emit LogSetMaxReserveTokens(_maxReserveTokens);
    }

    function setBurnAmount(uint8 _burnAmount) public onlyOwner {
        burnAmount = _burnAmount;
        emit LogSetBurnAmount(_burnAmount);
    }

    function setTimeConfig(
        uint256 _startTime,
        uint256 _softEndTime,
        uint256 _hardEndTime,
        uint256 _expansionDuration
    ) public onlyOwner {
        startTime = _startTime;
        softEndTime = _softEndTime;
        hardEndTime = _hardEndTime;
        extensionDuration = _expansionDuration;
        emit LogSetTimeConfig(_startTime, _softEndTime, _hardEndTime, _expansionDuration);
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = _to.call{value: amount}("");
        require(success, "unable to send value, recipient may have reverted");
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
