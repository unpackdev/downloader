// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Counters.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC721Pausable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./ERC721APausable.sol";

contract Human is
    ERC721A,
    ERC721ABurnable,
    ERC721AQueryable,
    ERC721APausable,
    AccessControl,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    // Create a new role identifier for the minter role
    bytes32 public constant MINER_ROLE = keccak256("MINER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // using Counters for Counters.Counter;
    // Counters.Counter private currentTokenId;
    /// @dev Base token URI used as a prefix by tokenURI().
    string private baseTokenURI;
    string private collectionURI;
    mapping(address => bool) public disapprovedMarketplaces;

    constructor() ERC721A("NeymarJR", "NJR") {
        _initializeEIP712("NeymarJR");
        baseTokenURI = "https://cdn.nftstar.com/neymar/human/metadata/";
        collectionURI = "https://cdn.nftstar.com/neymar/human/contract.json";
        // Grant the contract deployer the default admin role: it will be able to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSenderERC721A());
        _setupRole(MINER_ROLE, _msgSenderERC721A());
        _setupRole(PAUSER_ROLE, _msgSenderERC721A());
    }

    function mintTo(address to) public onlyRole(MINER_ROLE) {
        _mint(to, 1);
    }

    function mint(address to, uint256 quantity) public onlyRole(MINER_ROLE) {
        _safeMint(to, quantity);
    }

    function setDisapprovedMarketplace(address market, bool isDisapprove)
    external
    onlyRole(MINER_ROLE)
    {
        disapprovedMarketplaces[market] = isDisapprove;
    }

    function approve(address to, uint256 tokenId)
    public
    payable
    virtual
    override
    {
        require(!disapprovedMarketplaces[to], "The address is not approved");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
    {
        require(
            !disapprovedMarketplaces[operator],
            "The address is not approved"
        );
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "HUMAN: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "HUMAN: must have pauser role to unpause"
        );
        _unpause();
    }

    function current() public view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function setContractURI(string memory _contractURI)
        public
        onlyRole(MINER_ROLE)
    {
        collectionURI = _contractURI;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI)
        public
        onlyRole(MINER_ROLE)
    {
        baseTokenURI = _baseTokenURI;
    }

    function transferRoleAdmin(address newDefaultAdmin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, newDefaultAdmin);
    }

    function grantMinerRole(address _miner) external onlyOwner {
        _grantRole(MINER_ROLE, _miner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _msgSenderERC721A()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
