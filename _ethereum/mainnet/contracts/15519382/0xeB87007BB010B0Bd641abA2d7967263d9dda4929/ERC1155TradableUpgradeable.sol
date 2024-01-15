// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./AccessControl.sol";
import "./ERC20Upgradeable.sol";
import "./ERC1155PresetMinterPauserUpgradeable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ContentMixin.sol";
import "./IERC1155TradableUpgradeable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155TradableUpgradeable is ContextMixin, Initializable, ERC1155PresetMinterPauserUpgradeable, ReentrancyGuardUpgradeable, IERC1155TradableUpgradeable {
    event OperatorChanged (address previous, address new_);
    event AdminChanged (address previous, address new_);
    event ProxyRegistryAddressChanged (address previous, address new_);
    event CreateEvent (address _initialOwner, uint256 _id, uint256 _initialSupply, string _uri, address _operator);
    event MintEvent (address _to, uint256 _id, uint256 _quantity);
    event PriceChanged (uint256 _id, address erc_20, int256 previous, int256 new_);

    using Strings for string;
    using SafeMath for uint256;

    // super admin
    address public admin;// multi sig address
    // operator
    address public operator;

    address public proxyRegistryAddress;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => string) customUri;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    mapping(uint256 => mapping(address => int256)) public price_tokens;
    mapping(uint256 => mapping(address => bool)) public erc20_tokens;
    mapping(uint256 => uint256) public max_supply_tokens;


    /**
     * @dev Require _msgSender() to be the creator of the token id
   */
    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == _msgSender(), "ONLY_CREATOR");
        _;
    }

    /**
     * @dev Require _msgSender() to own more than 0 of the token id
   */
    modifier ownersOnly(uint256 _id) {
        require(balanceOf(_msgSender(), _id) > 0, "ONLY_OWNERS");
        _;
    }

    modifier operatorOnly() {
        require(_msgSender() == operator, "ONLY_OPERATOR");
        require(hasRole(OPERATOR_ROLE, _msgSender()), "ONLY_OPERATOR");
        _;
    }

    modifier adminOnly() {
        require(_msgSender() == admin, "ONLY_ADMIN");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ONLY_ADMIN");
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
        __ERC1155PresetMinterPauser_init(_uri);
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = address(0);

        admin = _admin;
        // set role for admin address
        grantRole(DEFAULT_ADMIN_ROLE, admin);

        operator = _operator;
        // set role for operator address   
        grantRole(OPERATOR_ROLE, operator);
        grantRole(CREATOR_ROLE, operator);
        grantRole(MINTER_ROLE, operator);
        grantRole(PAUSER_ROLE, operator);

        if (admin != _msgSender()) {
            // revoke role for sender
            revokeRole(MINTER_ROLE, _msgSender());
            revokeRole(PAUSER_ROLE, _msgSender());
            revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        }
    }

    function changePriceToken(uint256 _id, address erc_20, int256 _price) public operatorOnly {
        int256 prev = price_tokens[_id][erc_20];
        price_tokens[_id][erc_20] = _price;
        if (_price >= 0) {
            erc20_tokens[_id][erc_20] = true;
        } else {
            // price = -1(or < 0)
            // remove price with this erc_20
            erc20_tokens[_id][erc_20] = false;
        }
        emit PriceChanged(_id, erc_20, prev, _price);
    }

    // changeOperator: update operator by admin
    function changeOperator(address _newOperator) public adminOnly {
        require(_msgSender() == admin, "NOT_ADMIN");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NOT_ADMIN");

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

    // changeOperator: update admin by old admin
    function changeAdmin(address _newAdmin) public adminOnly {
        require(_msgSender() == admin, "NOT_ADMIN");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NOT_ADMIN");

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

    function uri(
        uint256 _id
    ) override public view returns (string memory) {
        require(_exists(_id), "NONEXISTENT_TOKEN");
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(customUri[_id]);
        if (customUriBytes.length > 0) {
            return customUri[_id];
        } else {
            return string(abi.encodePacked(super.uri(_id), StringsUpgradeable.toString(_id)));
        }
    }

    /**
      * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
    * substitution mechanism
    * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   * @param _newURI New URI for all tokens
   */
    function setURI(
        string memory _newURI
    ) public operatorOnly {
        require(hasRole(CREATOR_ROLE, _msgSender()), "ONLY_CREATOR");
        _setURI(_newURI);
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
        emit URI(_newURI, _tokenId);
    }

    /**
      * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: The token id must be passed. This allows lazy creation of tokens or
    *       creating NFTs by setting the id's high bits with the method
    *       described in ERC1155 or to use ids representing values other than
    *       successive small integers. If you wish to create ids as successive
    *       small integers you can either subclass this class to count onchain
    *       or maintain the offchain cache of identifiers recommended in
    *       ERC1155 and calculate successive ids from that.
    * @param _initialOwner address of the first owner of the token
    * @param _id The id of the token to create (must not currenty exist).
    * @param _initialSupply amount to supply the first owner
    * @param _uri Optional URI for this token type
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
    function create(
        address _initialOwner,
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri,
        bytes memory _data,
        address erc_20,
        int256 _price,
        uint256 _max
    ) virtual public operatorOnly
    returns (uint256) {
        require(hasRole(CREATOR_ROLE, _msgSender()), "NOT_CREATOR");
        require(!_exists(_id), "ALREADY_EXIST");
        if (_max > 0) {
            require(_initialSupply <= _max, "REACH_MAX");
        }

        creators[_id] = _msgSender();

        if (bytes(_uri).length > 0) {
            customUri[_id] = _uri;
            emit URI(_uri, _id);
        }

        _mint(_initialOwner, _id, _initialSupply, _data);

        tokenSupply[_id] = _initialSupply;

        price_tokens[_id][erc_20] = _price;
        erc20_tokens[_id][erc_20] = true;
        max_supply_tokens[_id] = _max;

        emit CreateEvent(_initialOwner, _id, _initialSupply, _uri, operator);
        return _id;
    }

    /**
      * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    * @param _data        Data to pass if receiver is contract
    */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) virtual public override creatorOnly(_id) {
        require(_exists(_id), "NONEXIST_TOKEN");
        require(hasRole(MINTER_ROLE, _msgSender()), "NOT_MINTER");

        if (max_supply_tokens[_id] != 0) {
            require(tokenSupply[_id].add(_quantity) <= max_supply_tokens[_id], "REACH_MAX");
        }
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
        emit MintEvent(_to, _id, _quantity);
    }

    /**
      * @dev Mints some amount of tokens to an address
    * @param _to          Address of the future owner of the token
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    * @param _data        Data to pass if receiver is contract
    */
    function userMint(address _to,
        uint256 _id,
        address erc_20,
        uint256 _quantity,
        bytes memory _data
    ) virtual public payable {
        require(_exists(_id), "NONEXIST_TOKEN");
        require(erc20_tokens[_id][erc_20], "INVALID_ERC20");
        if (erc_20 == address(0x0)) {
            if (price_tokens[_id][erc_20] > 0) {
                require(msg.value >= uint256(price_tokens[_id][erc_20]) * _quantity, "MISS_PRICE");
            } else {
                require(_quantity <= 1, "MAX_QUANTITY");
            }
        } else {
            if (price_tokens[_id][erc_20] > 0) {
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(erc_20);
                // tranfer erc-20 token to this contract
                bool success = tokenERC20.transferFrom(_msgSender(), address(this), uint256(price_tokens[_id][erc_20]) * _quantity);
                require(success == true, "TRANSFER_FAIL_E");
            } else {
                require(_quantity <= 1, "MAX_QUANTITY");
            }
        }
        if (max_supply_tokens[_id] != 0) {
            require(tokenSupply[_id].add(_quantity) <= max_supply_tokens[_id], "REACH_MAX");
        }
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
        emit MintEvent(_to, _id, _quantity);
    }


    /**
      * @dev Mint tokens for each id in _ids
    * @param _to          The address to mint tokens to
    * @param _ids         Array of ids to mint
    * @param _quantities  Array of amounts of tokens to mint per id
    * @param _data        Data to pass if receiver is contract
    */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public operatorOnly {
        require(hasRole(MINTER_ROLE, _msgSender()), "NOT_MINTER");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            require(creators[_id] == _msgSender(), "ONLY_CREATOR");
            uint256 quantity = _quantities[i];
            if (max_supply_tokens[_id] != 0) {
                require(tokenSupply[_id].add(quantity) <= max_supply_tokens[_id], "REACH_MAX");
            }
            tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
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

    function setProxyRegistryAddress(address _proxyRegistryAddress) public operatorOnly {
        require(_proxyRegistryAddress != proxyRegistryAddress, "PROXY_INVALID");
        address previous = proxyRegistryAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
        emit ProxyRegistryAddressChanged(previous, proxyRegistryAddress);
    }

    /**
   * Override isApprovedForAll to whitelist user's [OpenSea] proxy accounts to enable gas-free listings.
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) override(ERC1155Upgradeable, IERC1155Upgradeable) public view returns (bool isOperator) {
        if (proxyRegistryAddress != address(0)) {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }

        return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
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
      * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
    function _exists(
        uint256 _id
    ) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function exists(
        uint256 _id
    ) external view returns (bool) {
        return _exists(_id);
    }

    function getCreator(uint256 id)
    public
    view
    returns (address sender)
    {
        return creators[id];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauserUpgradeable, IERC165Upgradeable) returns (bool) {
        return
        interfaceId == type(IERC1155TradableUpgradeable).interfaceId ||
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

    // Withdraw
    function withdraw(address _to, address erc_20) external nonReentrant adminOnly {
        if (erc_20 == address(0x0)) {
            require(address(this).balance > 0, "NOT_ENOUGH");
            (bool success,) = _to.call{value : address(this).balance}("");
            require(success, "FAIL");
        } else {
            ERC20Upgradeable tokenERC20 = ERC20Upgradeable(erc_20);
            uint256 balance = tokenERC20.balanceOf(address(this));
            require(balance > 0, "NOT_ENOUGH");
            // tranfer erc-20 token
            bool success = tokenERC20.transfer(_to, balance);
            require(success == true, "TRANSFER_FAIL_E");
        }
    }
}
