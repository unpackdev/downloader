// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./IERC721AQueryableUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";

import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MulticallUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC2981.sol";

import "./ERC2771ContextUpgradeable.sol";
import "./IOwnable.sol";
import "./MerkleProof.sol";

//  ==========  Internal imports    ==========

import "./ISignatureMinting.sol";
import "./IPropsContract.sol";
import "./ISanctionsList.sol";


import "./DefaultOperatorFiltererUpgradeable.sol";

//@dev RIPTCG vaults will be bridged to SKALE using IMA bridge

contract PropsERC721ARIPTCG is
    Initializable,
    IOwnable,
    IPropsContract,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771ContextUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC2981
{
    using StringsUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using ECDSAUpgradeable for bytes32;

    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE = bytes32('PropsERC721ARIPTCG');
    uint256 private constant _VERSION = 1;

    uint256 private nextTokenId;
    mapping(address => uint256) public minted;

    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256('CONTRACT_ADMIN_ROLE');
    bytes32 private constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 private constant PRODUCER_ROLE = keccak256('PRODUCER_ROLE');

    uint256 public MAX_SUPPLY;

    mapping(string => mapping(address => uint256)) public mintedByID;

    string private baseURI_;
    string public contractURI;
    address private _owner;
    address private accessRegistry;
    address public project;
    address public receivingWallet;
    address public rWallet;
    address public signatureVerifier;
    address[] private trustedForwarders;
    address public SANCTIONS_CONTRACT;

    //////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////

    error AllowlistInactive();
    error AllowlistSupplyExhausted();
    error MintQuantityInvalid();
    error MerkleProofInvalid();
    error MintClosed();
    error InsufficientFunds();
    error InvalidSignature();
    error Sanctioned();
    error ExpiredSignature();

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////

    event Minted(address indexed account, string tokens);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    bool private initialized;

    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _trustedForwarders,
        address _sigVerifier,
        address _receivingWallet,
        address _royaltyWallet,
        uint96 _royaltyBIPs,
        uint256 _maxSupply,
        address _accessRegistry,
        address _OFAC
    ) public initializerERC721A initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);

        receivingWallet = _receivingWallet;
        rWallet = _royaltyWallet;
        _owner = _defaultAdmin;
        accessRegistry = _accessRegistry;
        signatureVerifier = _sigVerifier;
        baseURI_ = _baseURI;
        MAX_SUPPLY = _maxSupply;
        SANCTIONS_CONTRACT = _OFAC;

        _setDefaultRoyalty(rWallet, _royaltyBIPs);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, PRODUCER_ROLE);

        nextTokenId = 1;
    }

    /*///////////////////////////////////////////////////////////////
                      Generic contract logic
  //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(_VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /*///////////////////////////////////////////////////////////////
                      ERC 165 / 721A logic
  //////////////////////////////////////////////////////////////*/

    /**
     * @dev see {ERC721AUpgradeable}
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev see {IERC721Metadata}
     */
    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(_tokenId), '!t');
        return string(abi.encodePacked(baseURI_, _tokenId.toString(), '.json'));
    }

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC721AUpgradeable,
            IERC721AUpgradeable,
            ERC2981
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function mintWithSignature(
        ISignatureMinting.SignatureMintCart calldata cart
    ) external payable nonReentrant {
        uint256 _cost = 0;
        uint256 _quantity = 0;

        for (uint256 i = 0; i < cart.items.length; i++) {
            ISignatureMinting.SignatureMintCartItem memory _item = cart.items[i];

            revertOnInvalidMintSignature(_msgSender(), _item);

            _logMintActivity(cart.items[i].uid, address(_msgSender()), cart.items[i].quantity);

            _quantity += _item.quantity;
            _cost += _item.price * _item.quantity;
        }

        require(nextTokenId + _quantity - 1 <= MAX_SUPPLY, 'Max Supply');

        if (_cost > msg.value) revert InsufficientFunds();
        (bool sent, bytes memory data) = receivingWallet.call{value: msg.value}('');

        // mint _quantity tokens
        string memory tokensMinted = '';
        unchecked {
            for (uint256 i = nextTokenId; i < nextTokenId + _quantity; i++) {
                tokensMinted = string(abi.encodePacked(tokensMinted, i.toString(), ','));
            }
            minted[address(_msgSender())] += _quantity;
            nextTokenId += _quantity;
            _safeMint(_msgSender(), _quantity);
            emit Minted(_msgSender(), tokensMinted);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Signature Enforcement
    //////////////////////////////////////////////////////////////*/

    function revertOnInvalidMintSignature(
        address sender,
        ISignatureMinting.SignatureMintCartItem memory cartItem
    ) internal view {
        if (cartItem.expirationTime < block.timestamp) revert ExpiredSignature();

        if (mintedByID[cartItem.uid][sender] + cartItem.quantity > cartItem.allocation)
            revert MintQuantityInvalid();

        if (mintedByID[cartItem.uid][address(0)] + cartItem.quantity > cartItem.maxSupply)
            revert AllowlistSupplyExhausted();

        address recoveredAddress = ECDSAUpgradeable.recover(
            keccak256(
                abi.encodePacked(
                    sender,
                    cartItem.uid,
                    cartItem.quantity,
                    cartItem.price,
                    cartItem.allocation,
                    cartItem.expirationTime,
                    cartItem.maxSupply
                )
            ).toEthSignedMessageHash(),
            cartItem.signature
        );

        if (recoveredAddress != signatureVerifier) revert InvalidSignature();
    }

    function _logMintActivity(
        string memory uid,
        address wallet_address,
        uint256 incrementalQuantity
    ) internal {
        mintedByID[uid][wallet_address] += incrementalQuantity;
        mintedByID[uid][address(0)] += incrementalQuantity;
    }

    function setMaxSupply(uint256 _maxSupply) external {
        require(_hasMinRole(PRODUCER_ROLE));
        MAX_SUPPLY = _maxSupply;
    }

    function setRoyaltyConfig(address _address, uint96 _royalty) external {
        require(_hasMinRole(PRODUCER_ROLE));
        rWallet = _address;
        _setDefaultRoyalty(rWallet, _royalty);
    }

    function setReceivingWallet(address _address) external {
        require(_hasMinRole(PRODUCER_ROLE));
        receivingWallet = _address;
    }

    function getReceivingWallet() external view returns (address) {
        return receivingWallet;
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external {
        require(_hasMinRole(DEFAULT_ADMIN_ROLE));
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), '!Admin');
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        contractURI = _uri;
    }

    /// @dev Lets a contract admin set the URI for the baseURI.
    function setBaseURI(string calldata _baseURI, uint256 _startTokenId, uint256 _endTokenId) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        baseURI_ = _baseURI;
        emit BatchMetadataUpdate(_startTokenId, _endTokenId);
    }

    function setSignatureVerifier(address _address) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        signatureVerifier = _address;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

    function togglePause(bool isPaused) external {
        require(_hasMinRole(MINTER_ROLE));
        if (isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        if (!hasRole(role, account)) {
            super._grantRole(role, account);
        }
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        if (hasRole(role, account)) {
            if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
            super._revokeRole(role, account);
        }
    }

    function _hasMinRole(bytes32 _role) internal view returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return _hasMinRole(getRoleAdmin(_role));
    }

    // @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (isSanctioned(from) || isSanctioned(to)) revert Sanctioned();

    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(operator), 'Operator not allowed');
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(operator), 'Operator not allowed');
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(from), 'Operator not allowed');
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(from), 'Operator not allowed');
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(from), 'Operator not allowed');
        super.safeTransferFrom(from, to, tokenId, data);
    }

   

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function isSanctioned(address _operatorAddress) public view returns (bool) {
        SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
        bool isToSanctioned = sanctionsList.isSanctioned(_operatorAddress);
        return isToSanctioned;
    }

    function setSanctionsContract(address _address) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        SANCTIONS_CONTRACT = _address;
    }

    /// @dev Returns the number of minted tokens for sender by allowlist.
    function getMintedByUid(string calldata _uid, address _wallet) external view returns (uint256) {
        return mintedByID[_uid][_wallet];
    }

    uint256[46] private ___gap;
}
