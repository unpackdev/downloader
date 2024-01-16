// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./ERC721ProjectApproveTransferManager.sol";
import "./SignerRoleUpgradeable.sol";
import "./ProjectTokenURIManagerUpgradeable.sol";

interface ISimpleERC721AProject {
    /**
     * @dev mint a token. Can only be called by manager.
     */
    function managerMint(address to) external returns (uint256);

    /**
     * @dev mint ${quantity} tokens. Can only be called by manager.
     */
    function managerMint(address to, uint256 quantity) external;

    /**
     * @dev mint ${quantity} tokens to each of recipients
     */
    function managerMintBatch(address[] calldata recipients, uint256 quantity) external;

    /**
     * @dev set approve transfer switch
     */
    function managerSetApproveTransfer(bool enabled) external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// TODO: review + time restrictions
contract NonSpaceManager is
    Initializable,
    OwnableUpgradeable,
    ProjectTokenURIManagerUpgradeable,
    SignerRoleUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    ISimpleERC721AProject public nonSpaceProject;
    uint256 public minted;
    uint256 public earlyEdgeMinted;
    uint256 public maxEarlyEdgeNum;
    uint256 public total;
    // record if user is minted or not
    mapping(address => bool) public mintRecords;
    /// @dev the uint256 bits value is segmented et each 8 bits(1 byte), each byte represents locked value for a specific tcqType, which restricts max locks of a single tcqType to 255 (2^8 -1)
    /// (tcqType - 1) * 8 is the offset
    //    mapping(address => uint256) public usersLockedInfo;
    string public baseURI;

    //    uint8 public constant NFTs_NEED_TO_BE_LOCKED = 6;
    //    uint8 public constant MAX_TCQ_TYPES = 5;
    //    uint8 public constant MAX_UINT8 = 255;

    event LogSetNonSpaceProject(address project);
    event LogAirdrop(address[] recipients, uint256 quantity);
    event LogEarlyEdgeMint(address indexed user);
    event LogMint(address indexed user);
    event LogSetTotal(uint256 total);
    event LogSetMaxEarlyEdgeNum(uint256 num);
    event LogSetBaseURI(string baseURI);

    /// @dev Require that the caller must be an EOA account
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    function initialize(
        address _nonSpaceProject,
        uint256 _total,
        uint256 _maxEarlyEdgeNum,
        string calldata _baseURI
    ) public initializer {
        __Ownable_init();
        __SignerRole_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        setNonSpaceProject(_nonSpaceProject);
        setTotal(_total);
        setMaxEarlyEdgeNum(_maxEarlyEdgeNum);
        setBaseURI(_baseURI);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ProjectTokenURIManagerUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ///
    /// @notice Get the uri for a given project/tokenId
    ///
    function tokenURI(address project, uint256 tokenId) public view override returns (string memory) {
        require(project == address(nonSpaceProject), "NonSpaceManager: bad project");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function left() public view returns (uint256) {
        return total - minted;
    }

    function earlyEdgeLeft() public view returns (uint256) {
        uint256 _eeLeft = maxEarlyEdgeNum - earlyEdgeMinted;
        uint256 _left = left();
        // return the smaller one
        return _eeLeft > _left ? _left : _eeLeft;
    }

    /// @dev owner airdrop NonSpace NFTs to recipients
    function airdrop(address[] calldata recipients, uint256 quantity) external onlyOwner {
        minted += quantity * recipients.length;
        require(minted <= total, "reached mint limit");
        nonSpaceProject.managerMintBatch(recipients, quantity);
        emit LogAirdrop(recipients, quantity);
    }

    /// @dev for early edge mint
    function earlyEdgeMint(bytes calldata sig) external onlyEOA whenNotPaused {
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender(), 1));
        require(_verifySignedMessage(messageHash, sig), "proper signature is required");
        require(earlyEdgeMinted < maxEarlyEdgeNum, "reached early edge mint limit!");
        earlyEdgeMinted += 1;
        _mintForQuiz(_msgSender());
        emit LogEarlyEdgeMint(_msgSender());
    }

    /// @dev for public mint
    function mint(bytes calldata sig) external onlyEOA whenNotPaused {
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender(), 2));
        require(_verifySignedMessage(messageHash, sig), "proper signature is required");
        _mintForQuiz(_msgSender());
        emit LogMint(_msgSender());
    }

    function _mintForQuiz(address user) internal {
        require(!mintRecords[user], "user already minted!");
        mintRecords[user] = true;
        require(minted < total, "reached mint limit");
        minted += 1;
        nonSpaceProject.managerMint(user, 1);
    }

    function setNonSpaceProject(address _nonSpaceProject) public onlyOwner {
        nonSpaceProject = ISimpleERC721AProject(_nonSpaceProject);
        emit LogSetNonSpaceProject(_nonSpaceProject);
    }

    function setMaxEarlyEdgeNum(uint256 _num) public onlyOwner {
        maxEarlyEdgeNum = _num;
        emit LogSetMaxEarlyEdgeNum(_num);
    }

    function setTotal(uint256 _total) public onlyOwner {
        total = _total;
        emit LogSetTotal(_total);
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit LogSetBaseURI(_baseURI);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
