pragma solidity ^0.5.2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155MintBurn.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155MintBurn, Ownable {
    // Proxy registry address
    address public proxyRegistryAddress;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    mapping(uint256 => uint256) private _supply;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev Throws if called by any account other than the owner or their proxy
     */
    modifier onlyOwner() {
        require(
            _isOwner(_msgSender()),
            "ERC1155Tradable#onlyOwner: CALLER_IS_NOT_OWNER"
        );
        _;
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return _supply[_id];
    }

    /**
     * Override isApprovedForAll to whitelist user's Swappable proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool isOperator)
    {
        // Whitelist Swappable proxy contracts for easy trading.
        if (_isProxyForUser(_owner, _operator)) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
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
    ) public onlyOwner {
        _mint(_to, _id, _quantity, _data);
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
    ) public onlyOwner {
        _batchMint(_to, _ids, _quantities, _data);
    }

    /**
     * @dev Returns whether the specified token is minted
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function exists(uint256 _id) public view returns (bool) {
        return _supply[_id] > 0;
    }

    function _isOwner(address _address) internal view returns (bool) {
        return owner() == _address || _isProxyForUser(owner(), _address);
    }

    // Overrides ERC1155MintBurn to allow changing birth events to creator transfers,
    // and to set _supply
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Add _amount
        balances[_to][_id] = balances[_to][_id].add(_amount);
        _supply[_id] = _supply[_id].add(_amount);

        // Origin of token will be the _from parameter
        address origin = _origin(_id);

        // Emit event
        emit TransferSingle(msg.sender, origin, _to, _id, _amount);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(origin, _to, _id, _amount, gasleft(), _data);
    }

    // Overrides ERC1155MintBurn to change the batch birth events to creator transfers, and to set _supply
    function _batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        require(
            _ids.length == _amounts.length,
            "ERC1155Tradable#batchMint: INVALID_ARRAYS_LENGTH"
        );

        // Number of mints to execute
        uint256 nMint = _ids.length;

        // Origin of tokens will be the _from parameter
        address origin = _origin(_ids[0]);

        // Executing all minting
        for (uint256 i = 0; i < nMint; i++) {
            // Update storage balance
            uint256 id = _ids[i];
            require(
                _origin(id) == origin,
                "ERC1155Tradable#batchMint: MULTIPLE_ORIGINS_NOT_ALLOWED"
            );
            balances[_to][id] = balances[_to][id].add(_amounts[i]);
            _supply[id] = _supply[id].add(_amounts[i]);
        }

        // Emit batch mint event
        emit TransferBatch(msg.sender, origin, _to, _ids, _amounts);

        // Calling onReceive method if recipient is contract
        _callonERC1155BatchReceived(
            origin,
            _to,
            _ids,
            _amounts,
            gasleft(),
            _data
        );
    }

    // Override this to change birth events' _from address
    function _origin(
        uint256 /* _id */
    ) internal view returns (address) {
        return address(0);
    }

    // PROXY HELPER METHODS

    function _isProxyForUser(address _user, address _address)
        internal
        view
        returns (bool)
    {
        return _proxy(_user) == _address;
    }

    function _proxy(address _address) internal view returns (address) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return address(proxyRegistry.proxies(_address));
    }
}