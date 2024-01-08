pragma solidity ^0.5.2;

import "./Ownable.sol";
import "./AssetContract.sol";
import "./TokenIdentifiers.sol";
/**
 * @title AssetContractShared
 * Swappable shared asset contract - A contract for easily creating custom assets on Swappable
 */
contract AssetContractShared is AssetContract, ReentrancyGuard {
    mapping(address => bool) public sharedProxyAddresses;
    using SafeMath for uint256;
    using TokenIdentifiers for uint256;

    event CreatorChanged(uint256 indexed _id, address indexed _creator);

    mapping(uint256 => address) internal _creatorOverride;

    /**
     * @dev Require msg.sender to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            _isCreatorOrProxy(_id, _msgSender()),
            "AssetContractShared#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _templateURI
    )
        public
        AssetContract(_name, _symbol, _proxyRegistryAddress, _templateURI)
    {}

    /**
     * @dev Allows owner to change the proxy registry
     */
    function setProxyRegistryAddress(address _address) public onlyOwner {
        proxyRegistryAddress = _address;
    }

    /**
     * @dev Allows owner to add a shared proxy address
     */
    function addSharedProxyAddress(address _address) public onlyOwner {
        sharedProxyAddresses[_address] = true;
    }

    /**
     * @dev Allows owner to remove a shared proxy address
     */
    function removeSharedProxyAddress(address _address) public onlyOwner {
        delete sharedProxyAddresses[_address];
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public nonReentrant() {
        _requireMintable(_msgSender(), _id, _quantity);
        _mint(_to, _id, _quantity, _data);
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public nonReentrant() {
        for (uint256 i = 0; i < _ids.length; i++) {
            _requireMintable(_msgSender(), _ids[i], _quantities[i]);
        }
        _batchMint(_to, _ids, _quantities, _data);
    }

    /////////////////////////////////
    // CONVENIENCE CREATOR METHODS //
    /////////////////////////////////

    /**
     * @dev Will update the URI for the token
     * @param _id The token ID to update. msg.sender must be its creator.
     * @param _uri New URI for the token.
     */
    function setURI(uint256 _id, string memory _uri) public creatorOnly(_id) {
        _setURI(_id, _uri);
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function setCreator(uint256 _id, address _to) public creatorOnly(_id) {
        require(
            _to != address(0),
            "AssetContractShared#setCreator: INVALID_ADDRESS."
        );
        _creatorOverride[_id] = _to;
        emit CreatorChanged(_id, _to);
    }

    /**
     * @dev Get the creator for a token
     * @param _id   The token id to look up
     */
    function creator(uint256 _id) public view returns (address) {
        if (_creatorOverride[_id] != address(0)) {
            return _creatorOverride[_id];
        } else {
            return _id.tokenCreator();
        }
    }

    /**
     * @dev Get the maximum supply for a token
     * @param _id   The token id to look up
     */
    function maxSupply(uint256 _id) public pure returns (uint256) {
        return _id.tokenMaxSupply();
    }

    // Override ERC1155Tradable for birth events
    function _origin(uint256 _id) internal view returns (address) {
        return _id.tokenCreator();
    }

    function _requireMintable(
        address _address,
        uint256 _id,
        uint256 _amount
    ) internal view {
        require(
            _isCreatorOrProxy(_id, _address),
            "AssetContractShared#_requireMintable: ONLY_CREATOR_ALLOWED"
        );
        require(
            _remainingSupply(_id) >= _amount,
            "AssetContractShared#_requireMintable: SUPPLY_EXCEEDED"
        );
    }

    function _remainingSupply(uint256 _id) internal view returns (uint256) {
        return maxSupply(_id).sub(totalSupply(_id));
    }

    function _isCreatorOrProxy(uint256 _id, address _address)
        internal
        view
        returns (bool)
    {
        address creator_ = creator(_id);
        return creator_ == _address || _isProxyForUser(creator_, _address);
    }

    // Overrides ERC1155Tradable to allow a shared proxy address
    function _isProxyForUser(address _user, address _address)
        internal
        view
        returns (bool)
    {
        if (sharedProxyAddresses[_address]) {
            return true;
        }
        return super._isProxyForUser(_user, _address);
    }
}