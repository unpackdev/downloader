// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./IPart.sol";
import "./ERC721ARoyalty.sol";

/**
 * @dev Each Part NFT is a material of a Mech NFT.
 */
contract Part is 
    IPart,
    ERC721ARoyalty,
    AccessControlUpgradeable, 
    DefaultOperatorFiltererUpgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable {
    /**
     * @dev Roles
     * DEFAULT_ADMIN_ROLE
     * - can update royalty of each NFT
     * - can update role of each account
     *
     * OPERATOR_ROLE
     * - can update tokenURI
     * - can enable/disable mint
     * - can update minter
     * 
     * MINTER_ROLE
     * - can call mintPart function when mintEnabled is true
     * 
     * RESERVE_MINTER_ROLE
     * - can call mintReserved function when mintEnabled is true
     *
     * DEPLOYER_ROLE
     * - can update the logic contract     
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");    
    bytes32 public constant RESERVE_MINTER_ROLE = keccak256("RESERVE_MINTER_ROLE");    
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    uint256 public totalReserveMinted;
    bool public mintEnabled;
    
    mapping(uint256 => string) private _tokenURIs;
    string private baseURI;
    using StringsUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override only(DEPLOYER_ROLE) {}
    
    /**
     * @dev 
     * Params
     * `adminAddress`: ownership and `DEFAULT_ADMIN_ROLE` will be granted
     * `operatorAddress`: `OPERATOR_ROLE` will be granted
     * `minterAddress`: `MINTER_ROLE` will be granted
     * `reservedMinterAddress`: `RESERVE_MINTER_ROLE` will be granted
     * `defaultRoyaltyReceiver`: default royalty fee receiver
     * `defaultFeeNumerator`: default royalty fee
     */
    function initialize(
        string memory name, 
        string memory symbol, 
        address adminAddress, 
        address operatorAddress, 
        address minterAddress,
        address reservedMinterAddress,
        address defaultRoyaltyReceiver,
        uint96 defaultFeeNumerator
        ) initializerERC721A initializer public {
        __ERC721A_init(name, symbol);
        __ERC721AQueryable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();
        __ReentrancyGuard_init();
        
        mintEnabled = true;
        
        transferOwnership(adminAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
        _setupRole(MINTER_ROLE, minterAddress);
        _setupRole(RESERVE_MINTER_ROLE, reservedMinterAddress);
        _setupRole(DEPLOYER_ROLE, _msgSender());
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultFeeNumerator);
    }
    
    // modifiers
    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), "Caller does not have permission");
       _;
    }

    // viewers
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
    
    function tokenURI(
        uint256 tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    // external
    /**
     * @dev Creates `quantity` tokens and assign them to `to`
     * 
     * Requirements
     * - the caller must have the `MINTER_ROLE`
     */
    function mintPart(
        address to,
        uint256 quantity) external only(MINTER_ROLE) nonReentrant returns (uint256, uint256) {        
        require(quantity > 0, "Quantity cannot be zero");
        require(mintEnabled, "Mint has not been enabled");
        uint256 start = _nextTokenId();
        uint256 end = start + quantity -1;
        _safeMint(to, quantity);
        
        return (start, end);
    }
    
    // reserved
    /**
     * @dev Creates `quantity` reserved tokens and assign them to `to`
     * Admin can create additional NFTs for operation. 
     * 
     * Requirements
     * - the caller must have the `RESERVE_MINTER_ROLE`
     */
    function mintReservedPart(address to, uint quantity) external only(RESERVE_MINTER_ROLE) nonReentrant {
        require(quantity > 0, "Quantity cannot be zero");
        require(mintEnabled, "Mint has not been enabled");
        totalReserveMinted += quantity;

        uint256 start = _nextTokenId();
        uint256 end = start + quantity -1;
        
        _safeMint(to, quantity);
        emit ReservedPartMinted(to, start, end);
    }
    
    // operator
    /**
     * @dev Enables mint
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setMintEnabled(bool value) external only(OPERATOR_ROLE) {
        mintEnabled = value;
    }
    
    /**
     * @dev Sets baseURI
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setBaseURI(string memory uri) external only(OPERATOR_ROLE) {
        baseURI = uri;
    }
    
    /**
     * @dev Sets TokenURI of a token
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setTokenURI(uint256 tokenId, string memory URI) external only(OPERATOR_ROLE) {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = URI;
    }
    
    /**
     * @dev Sets tokenURIs from `tokenIdFrom` to `tokenIdFrom + tokenURIs.length -1`
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setTokenURIs(uint256 tokenIdFrom, string[] calldata tokenURIs) external only(OPERATOR_ROLE) {
        uint count = tokenURIs.length;
        uint256 tokenId = tokenIdFrom;
        for (uint i=0; i<count; i++) {
            _requireMinted(tokenId);
            _tokenURIs[tokenId] = tokenURIs[i];
            tokenId++;
        }
    }
    
    /**
     * @dev Sets minters from given addresses
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setMinter(address[] calldata minters) external only(OPERATOR_ROLE) {
        for(uint i=0; i<minters.length; i++) {
            _grantRole(MINTER_ROLE, minters[i]);
        }
    }
    
    /**
     * @dev Removes minters from given addresses
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function removeMinter(address[] calldata minters) external only(OPERATOR_ROLE) {
        for(uint i=0; i<minters.length; i++) {
            _revokeRole(MINTER_ROLE, minters[i]);
        }
    }
    
    // Royalty interface
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external only(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function deleteDefaultRoyalty() external only(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }
    
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external only(DEFAULT_ADMIN_ROLE){
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    
    function resetTokenRoyalty(uint256 tokenId) external only(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }
    
    // OpenSea operator filter
    function setApprovalForAll(
        address operator, 
        bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) 
        public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    // supportsInterface
    function supportsInterface(bytes4 interfaceId) 
        public view virtual 
        override(AccessControlUpgradeable, ERC721ARoyalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // events
    event ReservedPartMinted(
        address indexed owner, 
        uint256 indexed from,
        uint256 indexed to);
        
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
