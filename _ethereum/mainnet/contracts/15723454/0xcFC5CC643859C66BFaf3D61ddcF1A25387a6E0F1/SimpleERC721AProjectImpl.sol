// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";

import "./ERC721AProjectUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./IERC721ProjectApproveTransferManager.sol";
import "./IERC721ProjectBurnableManager.sol";
import "./IProjectTokenURIManager.sol";

// TODO: review more carefully
/// simple version of ERC721Project, Minting and token URI can only be controlled by manager
contract SimpleERC721AProjectImpl is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ERC721AUpgradeable,
    UUPSUpgradeable
{
    address public manager;
    bool public managerApproveTransfer; // if manager controls transfer or not
    string public contractURI; // for opensea collection
    string public _theBaseURI;

    event LogSetManager(address indexed previousManager, address indexed newManager);
    event LogManagerApproveTransferUpdated(address indexed manager, bool enabled);
    event LogSetContractURI(string uri);
    event LogSetBaseURI(string uri);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(manager == msg.sender, "caller is not the manager");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _name, string memory _symbol) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __ERC2981_init();
        __ERC721A_init(_name, _symbol);
        __UUPSUpgradeable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev set manager. This simple project can only be controlled by a single manager at a specific time range.
     * only manager can mint tokens and control token uris
     */
    function setManager(address _manager) external onlyOwner {
        address oldManager = manager;
        if (oldManager != _manager) {
            manager = _manager;
            emit LogSetManager(oldManager, _manager);
            // clear transfer approval since manager changed
            if (managerApproveTransfer) {
                managerApproveTransfer = false;
                emit LogManagerApproveTransferUpdated(msg.sender, false);
            }
        }
    }

    /**
     * @dev Manger switch transfer approval
     */
    function managerSetApproveTransfer(bool enabled) external onlyManager {
        require(
            !enabled ||
                ERC165CheckerUpgradeable.supportsInterface(
                    msg.sender,
                    type(IERC721ProjectApproveTransferManager).interfaceId
                ),
            "Manager must implement IERC721ProjectApproveTransferManager"
        );
        if (managerApproveTransfer != enabled) {
            managerApproveTransfer = enabled;
            emit LogManagerApproveTransferUpdated(msg.sender, enabled);
        }
    }

    /**
     * @dev totalSupply
     */
    function totalSupply() public view returns (uint256) {
        return erc721ATotalSupply();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override {
        _approveTransfer(from, to, tokenId);
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @dev See {IERC721ProjectCore-managerMint}.
     */
    function managerMint(address to) external nonReentrant onlyManager returns (uint256 id) {
        id = _nextTokenId();
        _safeMint(to, 1);
    }

    /**
     * @dev See {IERC721ProjectCore-managerMint}.
     */
    function managerMint(address to, uint256 quantity) external nonReentrant onlyManager {
        _safeMint(to, quantity);
    }

    /**
     * @dev mint ${quantity} tokens to each of recipients
     */
    function managerMintBatch(address[] calldata recipients, uint256 quantity) external nonReentrant onlyManager {
        unchecked {
            for (uint16 i = 0; i < recipients.length; i++) {
                _safeMint(recipients[i], quantity);
            }
        }
    }

    /**
     * @dev See {IERC721ProjectCore-burn}.
     */
    function burn(uint256 tokenId) public nonReentrant {
        address owner = ownerOf(tokenId);
        address approvedAddress = _tokenApprovals[tokenId];

        bool isApprovedOrOwner = (_msgSender() == owner ||
            isApprovedForAll(owner, _msgSender()) ||
            approvedAddress == _msgSender());
        require(isApprovedOrOwner, "Caller is not owner nor approved");
        _burn(tokenId);
        _postBurn(owner, tokenId);
    }

    /**
     * Post-burning callback and metadata cleanup
     */
    function _postBurn(address owner, uint256 tokenId) internal {
        // Callback to originating manager if needed
        if (
            manager != address(0) &&
            ERC165CheckerUpgradeable.supportsInterface(manager, type(IERC721ProjectBurnableManager).interfaceId)
        ) {
            IERC721ProjectBurnableManager(manager).onBurn(owner, tokenId);
        }
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (managerApproveTransfer) {
            require(
                IERC721ProjectApproveTransferManager(manager).approveTransfer(from, to, tokenId),
                "SimpleERC721AProject: Manager approval failure"
            );
        }
    }

    /**
     * @dev See {IProjectCore-setDefaultRoyalties}.
     */
    function setDefaultRoyalty(address receiver, uint256 royaltyBPs) external onlyOwner {
        _setDefaultRoyalty(receiver, royaltyBPs);
    }

    /**
     * @dev for opensea collection
     */
    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI = _uri;
        emit LogSetContractURI(_uri);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ERC165CheckerUpgradeable.supportsInterface(manager, type(IProjectTokenURIManager).interfaceId)) {
            return IProjectTokenURIManager(manager).tokenURI(address(this), tokenId);
        } else {
            return super.tokenURI(tokenId);
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _theBaseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _theBaseURI = _uri;
        emit LogSetBaseURI(_uri);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[46] private __gap;
}
