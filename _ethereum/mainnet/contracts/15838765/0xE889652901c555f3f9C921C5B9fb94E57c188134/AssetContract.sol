// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./ERC2981Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC1155Tradable.sol";
/**
 * @title AssetContract
 * AssetContract - A contract for easily creating non-fungible assets on Jungle.
 */
abstract contract AssetContract is ERC1155Tradable, ERC2981Upgradeable {

    uint256 public platformMintingFee;

    uint256 public royaltyFeeLimit;

    address public royaltyFeeRecipient;

    string public templateURI;

    uint256 private constant TOKEN_SUPPLY_CAP = 1;

    address public feeController;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURI;

    // Mapping for whether a token URI is set permanently
    mapping(uint256 => bool) private _isPermanentURI;

    event PermanentURI(string _value, uint256 indexed _id);

    modifier onlyTokenAmountOwned(
        address _from,
        uint256 _id,
        uint256 _quantity
    ) {
        require(
            _ownsTokenAmount(_from, _id, _quantity),
            "AssetContract#onlyTokenAmountOwned: ONLY_TOKEN_AMOUNT_OWNED_ALLOWED"
        );
        _;
    }

    /**
     * @dev Require the URI to be impermanent
     */
    modifier onlyImpermanentURI(uint256 id) {
        require(
            !isPermanentURI(id),
            "AssetContract#onlyImpermanentURI: URI_CANNOT_BE_CHANGED"
        );
        _;
    }

    modifier onlyFeeController() {
        require(_msgSender() == feeController, "Invalid Caller");
        _;
    }

    function __AssetContract_init(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _templateURI,
        uint256 _fee,
        address _recipient,
        address _defaultFeeController
    ) internal initializer { 
        
        __ERC1155Tradable_init(_name, _symbol, _proxyRegistryAddress);

        require(_fee <= _feeDenominator(), "Cannot be more than 100.00%");
        require(_recipient != address(0), "Invalid receiver" );
        require(_proxyRegistryAddress != address(0), "Invalid ProxyRegistry");
        feeController = _defaultFeeController;
        platformMintingFee = _fee;
        royaltyFeeRecipient = _recipient;
        royaltyFeeLimit = 1000; // default Royalty Fee limit set to 10%

        if (bytes(_templateURI).length > 0) {
            setTemplateURI(_templateURI);
        }
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwnerOrProxy {
        _setDefaultRoyalty(royaltyFeeRecipient, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyOwnerOrProxy {
        _deleteDefaultRoyalty();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, ERC2981Upgradeable) returns (bool) {
        return (interfaceId == type(IERC2981Upgradeable).interfaceId ||  interfaceId == type(IERC1155Upgradeable).interfaceId ||super.supportsInterface(interfaceId));
    }

    /**
     * @dev Sets the feeController
     * can be only called the owner
     * @param _feeController address of new feeSetter
     */
    function setFeeController(address _feeController) external onlyOwner {
        require(_feeController != address(0), "Invalid Address");
        feeController = _feeController;
    }
    /**
     * @dev Set platform fee for Jungle
     * @param _fee Input should be in bips
     */
    function setPlatformMintingFee(uint256 _fee) external onlyFeeController {
        require(_fee <= _feeDenominator(), "Cannot be more than 100.00%");
        platformMintingFee = _fee;
    }

    /**
     * @dev update receiver address
     * @param _recipient Address of the receiver
     */
     function setRoyaltyFeeRecipient(address _recipient) external onlyOwnerOrProxy {
        require(_recipient != address(0), "Invalid address");
        royaltyFeeRecipient = _recipient;
    }

    /**
     * Compat for factory interfaces on Jungle
     * Indicates that this contract can return balances for
     * tokens that haven't been minted yet
     */
    function supportsFactoryInterface() external pure returns (bool) {
        return true;
    }  

    function setTemplateURI(string memory _uri) public onlyOwnerOrProxy {
        templateURI = _uri;
    }

    function setURI(uint256 _id, string memory _uri)
    external
    virtual
    onlyOwnerOrProxy
    onlyImpermanentURI(_id)
    {
        _setURI(_id, _uri);
    }

    function setPermanentURI(uint256 _id, string memory _uri)
    external
    virtual
    onlyOwnerOrProxy
    onlyImpermanentURI(_id)
    {
        _setPermanentURI(_id, _uri);
    }

    function isPermanentURI(uint256 _id) public view returns (bool) {
        return _isPermanentURI[_id];
    }

    function uri(uint256 _id) public view override returns (string memory) {
        string memory tokenUri = _tokenURI[_id];
        if (bytes(tokenUri).length != 0) {
            return tokenUri;
        }
        return string(abi.encodePacked(templateURI, StringsUpgradeable.toString(_id)));
    }

    /**
     * @dev Get royalty info like royalty receiver and royalty amount
     * @param _tokenId Id of a token
     * @param _salePrice sale price of an NFT
     */
     function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address, uint256) {
        (, uint256 _royaltyAmount) = super.royaltyInfo(_tokenId, _salePrice);

        uint256 _platformMintingFee = (_salePrice * platformMintingFee) / _feeDenominator();
        _royaltyAmount = _royaltyAmount + _platformMintingFee;

        return (royaltyFeeRecipient, _royaltyAmount);
    }

    function balanceOf(address _owner, uint256 _id)
    public
    view
    virtual
    override
    returns (uint256)
    {
        uint256 balance = super.balanceOf(_owner, _id);
        return
        _isCreatorOrProxy(_id, _owner)
        ? balance + _remainingSupply(_id)
        : balance;
    }

    /**
     * @dev set royalty fee limit
     * @param _royaltyFeeLimit value to be set in royaltyFeeLimit
     */
    function setRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external onlyOwnerOrProxy {
        require(_royaltyFeeLimit + platformMintingFee <= _feeDenominator(), "Invalid Royalty Limit");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override {
        uint256 mintedBalance = super.balanceOf(_from, _id);
        if(_data.length>0 && _isCreatorOrProxy(_id, _msgSender())) {
            (uint96 _royaltyAmount) = abi.decode(_data, (uint96));
            require(_royaltyAmount <= royaltyFeeLimit, "Royalty fee too high");
            // set royalty fee if _royaltyAmount is greater than zero
            if (_royaltyAmount > 0) {
                _setTokenRoyalty(_id, royaltyFeeRecipient, _royaltyAmount);

            }
        }
        if (mintedBalance < _amount) {
            // Only mint what _from doesn't already have
            mint(_to, _id, _amount - mintedBalance, "");
            if (mintedBalance > 0) {
                super.safeTransferFrom(_from, _to, _id, mintedBalance, "");
            }
        } else {
            super.safeTransferFrom(_from, _to, _id, _amount, "");
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override {
        require(
            _ids.length == _amounts.length,
            "AssetContract#safeBatchTransferFrom: INVALID_ARRAYS_LENGTH"
        );
        (uint96[] memory dataDecode) = abi.decode(_data, (uint96[]));
        require(dataDecode.length == _ids.length, "AssetContract#safeBatchTransferFrom: INVALID_DATA_IDS_LENGTH");
        for (uint256 i = 0; i < _ids.length; i++) {
            bytes memory dataEncode = abi.encode(dataDecode[i]);
            safeTransferFrom(_from, _to, _ids[i], _amounts[i], dataEncode);
        }
    }

    // Overrides ERC1155Tradable burn to check for quantity owned
    function burn(
        address _from,
        uint256 _id,
        uint256 _quantity
    ) public override onlyTokenAmountOwned(_from, _id, _quantity) {
        _resetTokenRoyalty(_id);
        super.burn(_from, _id, _quantity);
    }

    // Overrides ERC1155Tradable batchBurn to check for quantity owned
    function batchBurn(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) public override {
        require(_ids.length == _quantities.length, "Lengths don't match");
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _ownsTokenAmount(_from, _ids[i], _quantities[i]),
                "AssetContract#batchBurn: ONLY_TOKEN_AMOUNT_OWNED_ALLOWED"
            );
        }
        super.batchBurn(_from, _ids, _quantities);
    }

    function _beforeMint(uint256 _id, uint256 _quantity)
    internal
    view
    override
    {
        require(
            _quantity <= _remainingSupply(_id),
            "AssetContract#_beforeMint: QUANTITY_EXCEEDS_TOKEN_SUPPLY_CAP"
        );
    }

    /**
     * @dev Require _from to own a specified quantity of the token
     */
    function _ownsTokenAmount(
        address _from,
        uint256 _id,
        uint256 _quantity
    ) internal view returns (bool) {
        return balanceOf(_from, _id) >= _quantity;
    }

    function _mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) internal override {
        super._mint(_to, _id, _quantity, _data);
        if (_data.length > 1) {
            _setURI(_id, string(_data));
        }
    }

    function _isCreatorOrProxy(uint256, address _address)
    internal
    view
    virtual
    returns (bool)
    {
        return _isOwnerOrProxy(_address);
    }

    function _batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) internal virtual override {
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

    function _setPermanentURI(uint256 _id, string memory _uri)
    internal
    virtual
    {
        require(
            bytes(_uri).length > 0,
            "AssetContract#setPermanentURI: ONLY_VALID_URI"
        );
        _isPermanentURI[_id] = true;
        _setURI(_id, _uri);
        emit PermanentURI(_uri, _id);
    }

    // Override ERC1155Tradable for birth events
    function _origin(
        uint256 /* _id */
    ) internal view virtual override returns (address) {
        return owner();
    }

    function _remainingSupply(uint256 _id)
    internal
    view
    virtual
    returns (uint256)
    {
        return TOKEN_SUPPLY_CAP - totalSupply(_id);
    }
}