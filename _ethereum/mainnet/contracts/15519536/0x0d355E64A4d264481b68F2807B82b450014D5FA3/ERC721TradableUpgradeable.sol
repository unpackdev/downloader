pragma solidity 0.8.12;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

import "./ContentMixin.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract ERC721TradableUpgradeable is ContextMixin, Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, IERC2981Upgradeable {
    event OperatorChanged (address previous, address new_);
    event AdminChanged (address previous, address new_);
    event ProxyRegistryAddressChanged (address previous, address new_);

    using CountersUpgradeable for CountersUpgradeable.Counter;

    // super admin
    address public admin;// multi sig address
    // operator
    address public operator;
    // creator
    mapping(uint256 => address) public creators;

    /*
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */
    CountersUpgradeable.Counter private _nextTokenId;
    address proxyRegistryAddress;

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId.current();
    }

    mapping(uint256 => string) customUri;


    /**
     * @dev Require _msgSender() to be the creator of the token id
   */
    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == _msgSender(), "ONLY_CREATOR");
        _;
    }

    modifier operatorOnly() {
        require(_msgSender() == operator, "ERC721Tradable#ownersOnly: ONLY_OPERATOR_ALLOWED");
        require(hasRole(OPERATOR_ROLE, _msgSender()), "ERC721Tradable#ownersOnly: ONLY_OPERATOR_ALLOWED");
        _;
    }

    modifier adminOnly() {
        require(_msgSender() == admin, "ERC721Tradable#ownersOnly: ONLY_ADMIN_ALLOWED");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC721Tradable#ownersOnly: ONLY_ADMIN_ALLOWED");
        _;
    }

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _admin,
        address _operator
    ) initializer public {
        __ERC721PresetMinterPauserAutoId_init(_name, _symbol, _uri);
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter

        admin = _admin;
        // set role for admin address
        grantRole(DEFAULT_ADMIN_ROLE, admin);

        operator = _operator;
        // set role for operator address   
        grantRole(OPERATOR_ROLE, operator);
        grantRole(CREATOR_ROLE, operator);
        grantRole(MINTER_ROLE, operator);
        grantRole(PAUSER_ROLE, operator);

        // revoke role for sender
        revokeRole(MINTER_ROLE, _msgSender());
        revokeRole(PAUSER_ROLE, _msgSender());
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // changeOperator: update operator by admin
    function changeOperator(address _newOperator) public adminOnly {
        require(_msgSender() == admin, "Sender is not admin");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender has not admin role");

        address _previousOperator = operator;
        operator = _newOperator;

        grantRole(OPERATOR_ROLE, operator);
        grantRole(CREATOR_ROLE, operator);
        grantRole(MINTER_ROLE, operator);
        grantRole(PAUSER_ROLE, operator);

        revokeRole(OPERATOR_ROLE, _previousOperator);
        revokeRole(CREATOR_ROLE, _previousOperator);
        revokeRole(MINTER_ROLE, _previousOperator);
        revokeRole(PAUSER_ROLE, _previousOperator);

        emit OperatorChanged(_previousOperator, operator);
    }

    // changeOperator: update operator by old admin
    function changeAdmin(address _newAdmin) public adminOnly {
        require(_msgSender() == admin, "Sender is not admin");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender has not admin role");

        address _previousAdmin = admin;
        admin = _newAdmin;

        grantRole(DEFAULT_ADMIN_ROLE, admin);
        //        grantRole(CREATOR_ROLE, admin);
        //        grantRole(MINTER_ROLE, admin);
        //        grantRole(PAUSER_ROLE, admin);

        //        revokeRole(CREATOR_ROLE, admin);
        //        revokeRole(MINTER_ROLE, admin);
        //        revokeRole(PAUSER_ROLE, admin);
        revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);

        emit AdminChanged(_previousAdmin, admin);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to, string memory _uri) public operatorOnly {
        _nextTokenId.increment();
        uint256 currentTokenId = _nextTokenId.current();
        if (bytes(_uri).length > 0) {
            customUri[currentTokenId] = _uri;
        }
        creators[currentTokenId] = _msgSender();
        _safeMint(_to, currentTokenId);
    }

    /**
      * @dev Change the creator address for given token
    * @param _to   Address of the new creator
    * @param _id  Token IDs to change creator of
    */
    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
    {
        creators[_id] = _to;
    }

    /**
      * @dev Change the creator address for given tokens
    * @param _to   Address of the new creator
    * @param _ids  Array of Token IDs to change creator
    */
    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public operatorOnly {
        require(_to != address(0), "INVALID_ADDRESS.");

        _grantRole(CREATOR_ROLE, _to);
        _grantRole(MINTER_ROLE, _to);
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }

    function getCreator(uint256 id)
    public
    view
    returns (address sender)
    {
        return creators[id];
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Will update the base URI for the token
   * @param _tokenId The token to update. _msgSender() must be its creator.
   * @param _newURI New URI for the token.
   */
    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public creatorOnly(_tokenId) {
        require(hasRole(CREATOR_ROLE, _msgSender()), "ONLY_CREATOR");
        customUri[_tokenId] = _newURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bytes memory customUriBytes = bytes(customUri[_tokenId]);
        if (customUriBytes.length > 0) {
            return customUri[_tokenId];
        } else {
            return string(abi.encodePacked(baseTokenURI(), StringsUpgradeable.toString(_tokenId)));
        }
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) public operatorOnly {
        require(_proxyRegistryAddress != proxyRegistryAddress, "new proxy address is invalid");
        address previous = proxyRegistryAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
        emit ProxyRegistryAddressChanged(previous, proxyRegistryAddress);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator)
    override(ERC721Upgradeable, IERC721Upgradeable)
    public
    view
    returns (bool)
    {
        if (proxyRegistryAddress != address(0)) {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721PresetMinterPauserAutoIdUpgradeable, IERC165Upgradeable) returns (bool) {
        return
        interfaceId == type(IERC721Upgradeable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
    internal
    override
    view
    returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /** @dev EIP2981 royalties implementation. */
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
        bool isValue;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;

    function setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _value
    ) public operatorOnly {
        require(hasRole(CREATOR_ROLE, _msgSender()), "NOT_CREATOR");
        require(_value <= 10000, 'TOO_HIGH');
        royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_value), true);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        if (royalty.isValue) {
            receiver = royalty.recipient;
            royaltyAmount = (_salePrice * royalty.amount) / 10000;
        } else {
            receiver = creators[_tokenId];
            royaltyAmount = (_salePrice * 500) / 10000;
        }
    }
}