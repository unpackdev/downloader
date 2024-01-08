pragma solidity ^0.5.2;

import "./ERC1155Tradable.sol";

/**
 * @title AssetContract
 * AssetContract - A contract for easily creating non-fungible assets on Swappable.
 */
contract AssetContract is ERC1155Tradable {
    event URI(string _value, uint256 indexed _id);

    uint256 constant TOKEN_SUPPLY_CAP = 1;

    string public templateURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _templateURI
    ) public ERC1155Tradable(_name, _symbol, _proxyRegistryAddress) {
        if (bytes(_templateURI).length > 0) {
            setTemplateURI(_templateURI);
        }
    }

    function swappableVersion() public pure returns (string memory) {
        return "2.0.2";
    }

    /**
     * Compat for factory interfaces on Swappable
     * Indicates that this contract can return balances for
     * tokens that haven't been minted yet
     */
    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    function setTemplateURI(string memory uri) public onlyOwner {
        templateURI = uri;
    }

    function setURI(uint256 _id, string memory _uri) public onlyOwner {
        _setURI(_id, _uri);
    }

    function uri(uint256 _id) public view returns (string memory) {
        string memory tokenUri = _tokenURI[_id];
        if (bytes(tokenUri).length != 0) {
            return tokenUri;
        }
        return templateURI;
    }

    function balanceOf(address _owner, uint256 _id)
        public
        view
        returns (uint256)
    {
        uint256 balance = super.balanceOf(_owner, _id);
        return
            _isCreatorOrProxy(_id, _owner)
                ? balance.add(_remainingSupply(_id))
                : balance;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        uint256 mintedBalance = super.balanceOf(_from, _id);
        if (mintedBalance < _amount) {
            // Only mint what _from doesn't already have
            mint(_to, _id, _amount.sub(mintedBalance), _data);
            if (mintedBalance > 0) {
                super.safeTransferFrom(_from, _to, _id, mintedBalance, _data);
            }
        } else {
            super.safeTransferFrom(_from, _to, _id, _amount, _data);
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        require(
            _ids.length == _amounts.length,
            "AssetContractShared#safeBatchTransferFrom: INVALID_ARRAYS_LENGTH"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            safeTransferFrom(_from, _to, _ids[i], _amounts[i], _data);
        }
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyOwner {
        require(
            _quantity <= _remainingSupply(_id),
            "AssetContract#mint: QUANTITY_EXCEEDS_TOKEN_SUPPLY_CAP"
        );
        _mint(_to, _id, _quantity, _data);
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _quantities[i] <= _remainingSupply(_ids[i]),
                "AssetContract#batchMint: QUANTITY_EXCEEDS_TOKEN_SUPPLY_CAP"
            );
        }
        _batchMint(_to, _ids, _quantities, _data);
    }

    function _mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) internal {
        super._mint(_to, _id, _quantity, _data);
        if (_data.length > 1) {
            _setURI(_id, string(_data));
        }
    }

    function _isCreatorOrProxy(uint256, address _address)
        internal
        view
        returns (bool)
    {
        return _isOwner(_address);
    }

    function _remainingSupply(uint256 _id) internal view returns (uint256) {
        return TOKEN_SUPPLY_CAP.sub(totalSupply(_id));
    }

    // Override ERC1155Tradable for birth events
    function _origin(
        uint256 /* _id */
    ) internal view returns (address) {
        return owner();
    }

    function _batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) internal {
        super._batchMint(_to, _ids, _quantities, _data);
        if (_data.length > 1) {
            for (uint256 i = 0; i < _ids.length; i++) {
                _setURI(_ids[i], string(_data));
            }
        }
    }

    function _setURI(uint256 _id, string memory _uri) internal {
        _tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }
}