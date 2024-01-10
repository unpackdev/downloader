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

import "./SignerRoleUpgradeable.sol";
import "./ERC721ProjectApproveTransferManager.sol";
import "./ProjectTokenURIManager.sol";
import "./ISimpleERC721Project.sol";

contract FireworkTicketManager is
    ERC721ProjectApproveTransferManager,
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

    uint256 public totalMinted;
    uint256 public claimStartTime;
    uint256 public claimEndTime;
    bool public transferable;
    bool public uriIdentity;
    string public baseURI;
    ISimpleERC721Project public ticketProject;

    /* ========== EVENTs ========== */
    event LogSetClaimTimes(uint256 claimStartTime, uint256 claimEndTime);
    event LogSetBaseURI(string baseURI);
    event LogSetTransferable(bool transferable);
    event LogSetProject(address project);
    event LogTicketClaimed(address indexed user, uint256 tokenId);
    event LogSetUriIdentity(bool identity);
    event LogAdminMint(address[] receivers);

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
        address _ticketProject,
        uint256 _claimStartTime,
        uint256 _claimEndTime,
        string memory _baseURI
    ) public initializer {
        __Ownable_init();
        __SignerRole_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        setTicketProject(_ticketProject);
        setClaimTimes(_claimStartTime, _claimEndTime);
        setBaseURI(_baseURI);
        // default not transferable
        setTransferable(false);
        setUriIdentity(true);
        totalMinted = 0;
    }

    /* ========== VIEW FUNCTIONS ========== */

    ///
    /// @notice Get the uri for a given project/tokenId
    ///
    function tokenURI(address project, uint256 tokenId) public view override returns (string memory) {
        require(project == address(ticketProject), "FireworkTicketManager: bad project");
        if (uriIdentity) {
            return baseURI;
        }
        return string(abi.encodePacked(baseURI, uint256(tokenId).toString()));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice claim one ticket NFT, Needs a proper signature of allowed signer to verify purchase.
    /// @param  sig bytes signature
    function claim(bytes calldata sig) external onlyEOA nonReentrant whenNotPaused {
        // 1. check status first, saving gas if is sold out or over
        require(block.timestamp >= claimStartTime, "event not started yet");
        require(block.timestamp <= claimEndTime, "event has already ended");
        // 2. check if already claimed. check before signature to save gas if reach limit
        require(ticketProject.balanceOf(_msgSender()) == 0, "you have already claimed");

        // 3. check signature
        bytes32 messageHash = keccak256(abi.encode(block.chainid, address(this), _msgSender()));
        require(_verifySignedMessage(messageHash, sig), "proper signature is required");

        // 4. change totalMinted
        totalMinted += 1;
        // 5. mint token to the buyer, uri is empty because it's controlled by #FireworkTicketManager.tokenURI function
        uint256 tokenId = ticketProject.managerMint(_msgSender(), "");
        // 6. record event
        emit LogTicketClaimed(_msgSender(), tokenId);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function adminMint(address[] calldata receivers) external onlyOwner returns (uint256[] memory tokenIds) {
        string[] memory uris = new string[](receivers.length);
        emit LogAdminMint(receivers);
        return ticketProject.managerMintBatch(receivers, uris);
    }

    /**
     * @dev Set whether or not the project will check the manager for approval of token transfer
     */
    function setApproveTransfer(address project, bool enabled) external override onlyOwner {
        require(project == address(ticketProject), "bad project");
        ticketProject.managerSetApproveTransfer(enabled);
    }

    /**
     * @dev Called by project contract to approve a transfer
     */
    function approveTransfer(
        address from,
        address to,
        uint256 /* tokenId */
    ) external view override returns (bool) {
        // approve mint and burn
        if (from == address(0) || to == address(0)) {
            return true;
        }
        return transferable;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        require(bytes(_baseURI).length != 0, "bad _baseURI");
        baseURI = _baseURI;
        emit LogSetBaseURI(_baseURI);
    }

    function setTicketProject(address _project) public onlyOwner {
        require(_project != address(0), "bad project");
        ticketProject = ISimpleERC721Project(_project);
        emit LogSetProject(_project);
    }

    function setClaimTimes(uint256 _claimStartTime, uint256 _claimEndTime) public onlyOwner {
        require(_claimStartTime < _claimEndTime, "bad time");
        claimStartTime = _claimStartTime;
        claimEndTime = _claimEndTime;
        emit LogSetClaimTimes(_claimStartTime, _claimEndTime);
    }

    function setTransferable(bool _transferable) public onlyOwner {
        transferable = _transferable;
        emit LogSetTransferable(_transferable);
    }

    function setUriIdentity(bool _identity) public onlyOwner {
        uriIdentity = _identity;
        emit LogSetUriIdentity(_identity);
    }

    /// @dev pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ProjectApproveTransferManager, ProjectTokenURIManager)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
