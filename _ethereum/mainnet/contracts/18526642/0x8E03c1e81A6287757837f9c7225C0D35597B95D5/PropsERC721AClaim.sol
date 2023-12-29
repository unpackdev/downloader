// SPDX-License-Identifier: Apache 2.0
// Powered by @Props

pragma solidity ^0.8.4;

//  ==========  External imports    ==========

import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./IERC721AQueryableUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

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

//  ==========  Internal imports    ==========
import "./IPropsInit.sol";
import "./ISignatureMinting.sol";
import "./IPropsContract.sol";
import "./ISanctionsList.sol";
import "./IPropsFeeManager.sol";
import "./IPropsERC721AClaim.sol";


import "./DefaultOperatorFiltererUpgradeable.sol";

contract PropsERC721AClaim is
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

    bytes32 private constant MODULE_TYPE = bytes32('PropsERC721AClaim');
    uint256 private constant VERSION = 19;

    uint256 private nextTokenId;
    mapping(address => uint256) public minted;

    bytes32 private constant CONTRACT_ADMIN_ROLE = keccak256('CONTRACT_ADMIN_ROLE');

    mapping(string => mapping(address => uint256)) public mintedByID;

    uint256 public MAX_SUPPLY;
    string private baseURI_;
    string public contractURI;
    address private _owner;
    address public project;
    address public receivingWallet;
    address public rWallet;
    address public signatureVerifier;
    address[] private trustedForwarders;
    address public SANCTIONS_CONTRACT;
    address public PROPS_FEE_MANAGER;
    address public FEE_RECIPIENT; 
    address[] public APPROVED_RELAY_ADDRESSES;
    uint256 public VERSION_OVERRIDE;
    bool public isTradeable;
    bool public isSoulbound;
    address private creator_affiliate_address;
    uint256 public collector_affiliate_fee_split;
    bool public share_topline_with_affiliate;
    bool public share_tips_with_affiliate;
    bool public share_protocol_fee_with_affiliate;

    //////////////////////////////////////////////
    // Errors
    /////////////////////////////////////////////

    error AllowlistSupplyExhausted();
    error MintQuantityInvalid();
    error MaxSupplyExhausted();
    error InsufficientFunds();
    error InvalidSignature();
    error Sanctioned();
    error ExpiredSignature();
    error SoulBound();

    //////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////

    event Minted(address indexed account, string tokens);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    //////////////////////////////////////////////
    // Init
    /////////////////////////////////////////////

    function initialize(
       IPropsInit.InitializeArgs memory args
    ) public initializerERC721A initializer {
         __ERC2771Context_init(args._trustedForwarders);
        __ERC721A_init(args._name, args._symbol);

        receivingWallet = args._receivingWallet;
        rWallet = args._royaltyWallet;
        creator_affiliate_address = args._creator_affiliate_wallet;
        _owner = args._defaultAdmin;
        signatureVerifier = args._sigVerifier;
        baseURI_ = args._baseURI;
        contractURI = args._contractURI;
        MAX_SUPPLY = args._maxSupply;
        SANCTIONS_CONTRACT = args._OFAC;

        isTradeable = args._isTradeable;
        isSoulbound = args._isSoulbound;

        collector_affiliate_fee_split = args._collector_affiliate_split;
        share_topline_with_affiliate = args._share_topline_with_affiliate;
        share_tips_with_affiliate = args._share_tips_with_affiliate;
        share_protocol_fee_with_affiliate = args._share_protocol_fee_with_affiliate;

        PROPS_FEE_MANAGER = 0xe8E8d2fdAc9c5264ac877586bD435a5686C30320;
        FEE_RECIPIENT = 0xeeeB783c979fEC681e356Dba2Dde9cA3382aF532; 
        APPROVED_RELAY_ADDRESSES = [0xa8C10eC49dF815e73A881ABbE0Aa7b210f39E2Df, 0x79bB164367BB64742E993f381372961a945BF447, 0xFd88229910A28D6B319E147b40c822FA5CF38a45, 0x6b40a842e05D60081F5474046c713b294B4BbC63, 0x8528fA2503c49893B704B981e0cBAC021E678789, 0x13253aa4Abe1861124d4c286Ee4374cD054D3eb9];
    
        nextTokenId = 1;

         _setDefaultRoyalty(args._royaltyWallet, args._royaltyBIPs);
        _setupRole(DEFAULT_ADMIN_ROLE, args._defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
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
        return uint8(VERSION);
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
        ISignatureMinting.SignatureClaimAffiliateCart calldata cart
    ) public payable nonReentrant {

        revertOnInvalidCartSignature(cart);

        uint256 _cost = 0;
        uint256 _quantity = 0;

        for (uint256 i = 0; i < cart.items.length; i++) {
            ISignatureMinting.SignatureMintCartItem memory _item = cart.items[i];

            revertOnInvalidMintSignature(cart.delegated_wallet, _item);

            _logMintActivity(_item.uid, address(cart.delegated_wallet), _item.quantity);

            _quantity += _item.quantity;
            _cost += _item.price * _item.quantity;
        }

        ISignatureMinting.CartAffiliateMint memory _cart = ISignatureMinting.CartAffiliateMint({
            _minting_wallet: cart.minting_wallet, 
            _delegated_wallet: cart.delegated_wallet, 
            _receiving_wallet: cart.receiving_wallet,
            _quantity: _quantity, 
            _cost: _cost,
            _collector_affiliate_wallet: cart.collector_affiliate_wallet
        });

        _executeMint(_cart);

        
    }


     function mintTo(address _to, uint256 _quantity, address _delegated_wallet, string calldata _uid, uint256 _allocation, uint256 _max_supply, uint256 _pricePerUnit, uint256 _expirationTime, bytes calldata _signature, address _collector_affiliate_wallet) external payable nonReentrant {
         ISignatureMinting.RelayAffiliateMint memory relayMint = ISignatureMinting.RelayAffiliateMint({
           _to: _to,
            _quantity: _quantity,
            _minting_wallet: _delegated_wallet,
            _delegated_wallet: _delegated_wallet,
            _uid: _uid,
            _allocation: _allocation,
            _max_supply: _max_supply,
            _pricePerUnit: _pricePerUnit,
            _expirationTime: _expirationTime,
            _signature: _signature,
            _collector_affiliate_wallet: _collector_affiliate_wallet
        });
        
        _mintTo(relayMint);
    }

    function _mintTo(ISignatureMinting.RelayAffiliateMint memory _relay_data) internal {
        bool isApprovedRelay = false;
        for(uint i = 0; i < APPROVED_RELAY_ADDRESSES.length; i++) {
            if(msg.sender == APPROVED_RELAY_ADDRESSES[i] || _msgSender() == APPROVED_RELAY_ADDRESSES[i]) {
                isApprovedRelay = true;
                break;
            }
        }
        require(isApprovedRelay, 'Invalid Relay');

        if (_relay_data._expirationTime < block.timestamp) revert ExpiredSignature();
        

        address recoveredAddress = ECDSAUpgradeable.recover(
            keccak256(
                abi.encodePacked(
                    _relay_data._to,
                    _relay_data._quantity,
                    _relay_data._minting_wallet,
                    _relay_data._delegated_wallet,
                    _relay_data._uid,
                    _relay_data._allocation,
                    _relay_data._max_supply,
                    _relay_data._pricePerUnit,
                    _relay_data._expirationTime,
                    _relay_data._collector_affiliate_wallet
                )
            ).toEthSignedMessageHash(),
            _relay_data._signature
        );

        if (recoveredAddress != signatureVerifier) revert InvalidSignature();

        if (mintedByID[_relay_data._uid][_relay_data._delegated_wallet] + _relay_data._quantity > _relay_data._allocation)
            revert MintQuantityInvalid();

        if (mintedByID[_relay_data._uid][address(0)] + _relay_data._quantity > _relay_data._max_supply)
            revert AllowlistSupplyExhausted();

        _logMintActivity(_relay_data._uid, address(_relay_data._delegated_wallet), _relay_data._quantity);

        ISignatureMinting.CartAffiliateMint memory cartMint = ISignatureMinting.CartAffiliateMint({
            _minting_wallet: _relay_data._minting_wallet, 
            _delegated_wallet: _relay_data._delegated_wallet, 
            _receiving_wallet: _relay_data._to,
            _quantity: _relay_data._quantity, 
            _cost: _relay_data._pricePerUnit * _relay_data._quantity,
            _collector_affiliate_wallet: _relay_data._collector_affiliate_wallet
        });

        _executeMint(cartMint);
    }

     function _executeMint(ISignatureMinting.CartAffiliateMint memory cart ) internal {
        if(nextTokenId + cart._quantity - 1 > MAX_SUPPLY) revert MaxSupplyExhausted();

        IPropsFeeManager feeManager = IPropsFeeManager(PROPS_FEE_MANAGER);
        
        uint256 _fee = feeManager.getETHWEIFeeSetting()  * cart._quantity;

        uint256 fee_split = feeManager.getSplitSetting();
        uint256 platform_fee = (_fee * (10000 - fee_split)) / 10000;

        uint256 creator_protocol_fee = (_fee * fee_split) / 10000;
        uint256 creator_tip_fee = 0;
        uint256 creator_topline_fee = cart._cost;
        
        uint256 collector_affiliate_protocol_fee = 0;
        uint256 collector_affiliate_tip_fee = 0;
        uint256 collector_affiliate_topline_fee = 0;
        

        cart._cost += _fee;
        if (cart._cost > msg.value) revert InsufficientFunds();

        if(msg.value > cart._cost) {
            creator_tip_fee = ((msg.value - cart._cost) * feeManager.getTipSplitSetting()) / 10000;
            platform_fee += ((msg.value - cart._cost) - creator_tip_fee);
            
        }

        if(creator_affiliate_address != address(0) && !isSanctioned(creator_affiliate_address)) {
            uint256 creator_affiliate_fee = (platform_fee * feeManager.getCreatorAffiliateSplitSetting()) / 10000;
            platform_fee -= creator_affiliate_fee;
            (bool affiliate_fee_sent, bytes memory affiliate_fee_data) = creator_affiliate_address.call{value: creator_affiliate_fee}('');
        }

        if(cart._collector_affiliate_wallet != address(0) && !isSanctioned(cart._collector_affiliate_wallet)) {

             if(share_tips_with_affiliate){
                collector_affiliate_tip_fee += (creator_tip_fee * collector_affiliate_fee_split) / 10000;
                creator_tip_fee -= collector_affiliate_tip_fee;
            }

            if(share_topline_with_affiliate && (cart._cost > _fee)){
                collector_affiliate_topline_fee += ((cart._cost - _fee) * collector_affiliate_fee_split) / 10000;
                creator_topline_fee -= collector_affiliate_topline_fee;
            }

            if(share_protocol_fee_with_affiliate){
                collector_affiliate_protocol_fee += (creator_protocol_fee * collector_affiliate_fee_split) / 10000;
                creator_protocol_fee -= collector_affiliate_protocol_fee;
            }

            cart._collector_affiliate_wallet.call{value: (collector_affiliate_tip_fee + collector_affiliate_topline_fee + collector_affiliate_protocol_fee)}('');
        }

        FEE_RECIPIENT.call{value: platform_fee}('');
        receivingWallet.call{value: (creator_tip_fee + creator_topline_fee + creator_protocol_fee)}('');

        // mint _quantity tokens
        string memory tokensMinted = '';
        unchecked {
            for (uint256 i = nextTokenId; i < nextTokenId + cart._quantity; i++) {
                tokensMinted = string(abi.encodePacked(tokensMinted, i.toString(), ','));
            }
            minted[address(cart._delegated_wallet)] += cart._quantity;
            nextTokenId += cart._quantity;
            _safeMint(cart._receiving_wallet, cart._quantity);
            emit Minted(cart._minting_wallet, tokensMinted);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Signature Enforcement
    //////////////////////////////////////////////////////////////*/

    function revertOnInvalidCartSignature(
        ISignatureMinting.SignatureClaimAffiliateCart calldata cart
    ) internal view {
        if (cart.expirationTime < block.timestamp) revert ExpiredSignature();

        address recoveredAddress = ECDSAUpgradeable.recover(
            keccak256(
                abi.encodePacked(
                    cart.minting_wallet,
                    cart.delegated_wallet,
                    cart.receiving_wallet,
                    cart.expirationTime,
                    cart.collector_affiliate_wallet
                )
            ).toEthSignedMessageHash(),
            cart.signature
        );

        if (recoveredAddress != signatureVerifier) revert InvalidSignature();
    }

    function revertOnInvalidMintSignature(
        address delegated_wallet,
        ISignatureMinting.SignatureMintCartItem memory cartItem
    ) internal view {
        if (cartItem.expirationTime < block.timestamp) revert ExpiredSignature();

        if (mintedByID[cartItem.uid][delegated_wallet] + cartItem.quantity > cartItem.allocation)
            revert MintQuantityInvalid();

        if (mintedByID[cartItem.uid][address(0)] + cartItem.quantity > cartItem.maxSupply)
            revert AllowlistSupplyExhausted();

        address recoveredAddress = ECDSAUpgradeable.recover(
            keccak256(
                abi.encodePacked(
                    delegated_wallet,
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
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        MAX_SUPPLY = _maxSupply;
    }

    function setCollectorAffiliateSplit(uint256 _newSplit) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        collector_affiliate_fee_split = _newSplit;
    }

    function setCollectorAffiliateSettings(bool _share_topline_with_affiliate, bool _share_tips_with_affiliate, bool _share_protocol_fee_with_affiliate) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        share_topline_with_affiliate = _share_topline_with_affiliate;
        share_tips_with_affiliate = _share_tips_with_affiliate;
        share_protocol_fee_with_affiliate = _share_protocol_fee_with_affiliate;
    }

    function setRoyaltyConfig(address _address, uint96 _royalty) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        rWallet = _address;
        _setDefaultRoyalty(rWallet, _royalty);
    }

    function setReceivingWallet(address _address) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        receivingWallet = _address;
    }

    function setFeeManager(address _address, bytes calldata signature) external {
        require(_hasMinRole(DEFAULT_ADMIN_ROLE));
        revertOnInvalidAddressSignature(_address, signature);
        PROPS_FEE_MANAGER = _address;
    }

    function setCreatorAffiliateAddress(address _address, bytes calldata signature) external {
        require(_hasMinRole(DEFAULT_ADMIN_ROLE));
        revertOnInvalidAddressSignature(_address, signature);
        creator_affiliate_address = _address;
    }

     function setFeeRecipient(address _address, bytes calldata signature) external {
        require(_hasMinRole(DEFAULT_ADMIN_ROLE));
        revertOnInvalidAddressSignature(_address, signature);
        FEE_RECIPIENT = _address;
    }

     function revertOnInvalidAddressSignature(
        address _address,
        bytes calldata signature
    ) internal view {
         address recoveredAddress = ECDSAUpgradeable.recover(
            keccak256(
                abi.encodePacked(
                    _address
                )
            ).toEthSignedMessageHash(),
            signature
        );

        if (recoveredAddress != signatureVerifier) revert InvalidSignature();
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external {
        require(_hasMinRole(DEFAULT_ADMIN_ROLE) && hasRole(DEFAULT_ADMIN_ROLE, _newOwner), '!Admin');
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
    function setBaseURI(string calldata _baseURI) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        baseURI_ = _baseURI;
        emit BatchMetadataUpdate(1, totalSupply());
    }

    function setSignatureVerifier(address _address) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        signatureVerifier = _address;
    }

    /*///////////////////////////////////////////////////////////////
                      Miscellaneous / Overrides
  //////////////////////////////////////////////////////////////*/

    function togglePause(bool isPaused) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
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
        if (hasRole(_role, _msgSender())) return true;
        if (_role == DEFAULT_ADMIN_ROLE) return false;
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
        if(isSoulbound && from != address(0)) revert SoulBound();
        if (isSanctioned(from) || isSanctioned(to)) revert Sanctioned();
       
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(operator), "Operator not allowed");
        require(isTradeable, "Approvals are disabled.");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(operator), "Operator not allowed");
        require(isTradeable, "Approvals are disabled.");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(from), "Operator not allowed");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(onlyAllowedOperatorApproval(from), "Operator not allowed");
        super.safeTransferFrom(from, to, tokenId);
    }

    function isApprovedForAll(address _owner, address operator) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns (bool) {
        require(isTradeable, "Approvals are disabled");
        return super.isApprovedForAll(_owner, operator);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
       
    {
       require(onlyAllowedOperatorApproval(from), "Operator not allowed");
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

     function setVersionOverride(uint256 _version) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        VERSION_OVERRIDE = _version;
    }

    function setRelayAddresses(address[] memory _addresses) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        APPROVED_RELAY_ADDRESSES = _addresses;
    }

    function setTradability(bool _isTradeable) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        isTradeable = _isTradeable;
    }

    function setSoulbound(bool _isSoulbound) external {
        require(_hasMinRole(CONTRACT_ADMIN_ROLE));
        isSoulbound = _isSoulbound;
    }

    /// @dev Returns the number of minted tokens for sender by allowlist.
    function getMintedByUid(string calldata _uid, address _wallet) external view returns (uint256) {
        return mintedByID[_uid][_wallet];
    }

    uint256[46] private ___gap;
}
