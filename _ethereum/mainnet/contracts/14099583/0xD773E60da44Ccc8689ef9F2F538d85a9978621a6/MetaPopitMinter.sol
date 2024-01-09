// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";
import "./NftMintingStation.sol";

/**
 * @title MetaPopit Minter
 * @notice MetaPopit Minting Station
 */
contract MetaPopitMinter is NftMintingStation {
    using SafeMath for uint256;

    bytes32 public constant SIGN_MINT_TYPEHASH = keccak256("Mint(uint256 quantity,uint256 value,address account)");

    uint8 public constant WL_FAST = 1;
    uint8 public constant WL_TURBO = 2;
    uint8 public constant WL_SUPERSONIC = 3;

    uint256 public constant MAX_FREE = 200;
    uint256 public constant MAX_MINT_PER_WALLET = 3;

    uint256 public startTimestamp;
    uint256 public startPublicTimestamp;
    uint256 public endTimestamp;

    uint256 public freeTokens;

    uint256 public immutable creator1Fee;
    uint256 public immutable creator2Fee;
    uint256 public immutable creator3Fee;
    uint256 public immutable creator4Fee;

    address public immutable creator1;
    address public immutable creator2;
    address public immutable creator3;
    address public immutable creator4;

    mapping(uint256 => uint256) private _tokenIdsCache;
    mapping(address => uint256) private _userMints;

    event Withdraw(uint256 amount);

    modifier whenClaimable() {
        require(currentStatus == STATUS_CLAIM, "Status not claim");
        _;
    }

    modifier whenMintOpened(uint256 _wl) {
        require(startTimestamp <= block.timestamp, "Mint too early");
        require(endTimestamp == 0 || endTimestamp > block.timestamp, "Mint too late");
        if (_wl == 0) require(startPublicTimestamp <= block.timestamp, "Mint not public");
        _;
    }

    modifier whenValidQuantity(uint256 _quantity) {
        require(availableSupply > 0, "No more supply");
        require(availableSupply >= _quantity, "Not enough supply");
        require(_quantity > 0, "Qty <= 0");
        _;
    }

    constructor(INftCollection _collection) NftMintingStation(_collection, "MetaPopit", "1.0") {
        creator1Fee = 2500;
        creator2Fee = 2500;
        creator3Fee = 2500;
        creator4Fee = 2500;

        creator1 = 0x90A7237f48F3EE8FD60ae267Ae4C0551ab2030A3;
        creator2 = 0x872c125125A003610dE6581E165808bA4B153fd6;
        creator3 = 0x2B21eCcaB47B18f79f9167A2aC1636DA3dC25505;
        creator4 = 0xF4a202Ed4541C5735d584966a52cFa17749acb7b;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev initialize the default configuration
     */
    function initialize(
        uint256 _unitPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _startPublicTimestamp
    ) external onlyOwnerOrOperator {
        unitPrice = _unitPrice;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        startPublicTimestamp = _startPublicTimestamp;
        _syncSupply();
        currentStatus = STATUS_PREPARING;
    }

    /**
     * @dev mint a `_quantity` NFT (quantity max for a wallet is limited by `MAX_MINT_PER_WALLET`)
     * _wl: whitelist level
     * _signature: backend signature for the transaction
     */
    function mint(
        uint256 _quantity,
        uint8 _wl,
        bytes memory _signature
    ) external payable notContract nonReentrant whenValidQuantity(_quantity) whenClaimable whenMintOpened(_wl) {
        require(_userMints[_msgSender()].add(_quantity) <= MAX_MINT_PER_WALLET, "Above quantity allowed");

        uint256 value = unitPrice.mul(_quantity);
        if (_wl == WL_SUPERSONIC) {
            value = value.mul(800).div(1000); // 20% discount
        } else if (_wl == WL_TURBO) {
            value = value.mul(900).div(1000); // 10% discount
        }

        require(isAuthorized(_hashMintPayload(_quantity, value, _msgSender()), _signature), "Not signed by authorizer");
        require(msg.value >= value, "Payment failed");

        _mint(_quantity, _msgSender());
        _userMints[_msgSender()] = _userMints[_msgSender()] + _quantity;
    }

    /**
     * @dev mint a free NFT (number of free NFT is limited by `MAX_FREE`)
     */
    function mintFree(address _destination, uint256 _quantity)
        external
        onlyOwnerOrOperator
        whenValidQuantity(_quantity)
    {
        require(freeTokens + _quantity <= MAX_FREE, "Above free quantity allowed");
        _mint(_quantity, _destination);
        freeTokens = freeTokens + _quantity;
    }

    /**
     * @dev mint a free NFT by specifying the tokenIds (number of free NFT is limited by `MAX_FREE`)
     */
    function mintReserve(address _destination, uint256[] calldata _tokenIds)
        external
        onlyOwnerOrOperator
        whenValidQuantity(_tokenIds.length)
    {
        require(freeTokens + _tokenIds.length <= MAX_FREE, "Above free quantity allowed");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 cacheId = _tokenIds[i] - 1;
            _tokenIdsCache[cacheId] = _tokenIdsCache[availableSupply - 1] == 0
                ? availableSupply - 1
                : _tokenIdsCache[availableSupply - 1];

            nftCollection.mint(_destination, _tokenIds[i]);
            availableSupply = availableSupply - 1;
        }

        freeTokens = freeTokens + _tokenIds.length;
    }

    /**
     * @dev mint the remaining NFTs when the sale is closed
     */
    function mintRemaining(address _destination, uint256 _quantity)
        external
        onlyOwnerOrOperator
        whenValidQuantity(_quantity)
    {
        require(currentStatus == STATUS_CLOSED, "Status not closed");
        _mint(_quantity, _destination);
    }

    function _withdraw(uint256 amount) private {
        require(amount <= address(this).balance, "amount > balance");
        require(amount > 0, "Empty amount");

        uint256 amount1 = amount.mul(creator1Fee).div(10000);
        uint256 amount2 = amount.mul(creator2Fee).div(10000);
        uint256 amount3 = amount.mul(creator3Fee).div(10000);
        uint256 amount4 = amount.sub(amount3).sub(amount2).sub(amount1);

        payable(creator1).transfer(amount1);
        payable(creator2).transfer(amount2);
        payable(creator3).transfer(amount3);
        payable(creator4).transfer(amount4);

        emit Withdraw(amount);
    }

    /**
     * @dev withdraw selected amount
     */
    function withdraw(uint256 amount) external onlyOwnerOrOperator {
        _withdraw(amount);
    }

    /**
     * @dev withdraw full balance
     */
    function withdrawAll() external onlyOwnerOrOperator {
        _withdraw(address(this).balance);
    }

    /**
     * @dev configure the mint dates
     */
    function setMintDates(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _startPublicTimestamp
    ) external onlyOwnerOrOperator {
        require(_endTimestamp == 0 || _startTimestamp < _endTimestamp, "Invalid timestamps");
        require(
            _endTimestamp == 0 || (_startPublicTimestamp < _endTimestamp && _startTimestamp <= _startPublicTimestamp),
            "Invalid public timestamp"
        );
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        startPublicTimestamp = _startPublicTimestamp;
    }

    function _getNextRandomNumber() private returns (uint256 index) {
        require(availableSupply > 0, "Invalid _remaining");

        uint256 i = maxSupply.add(uint256(keccak256(abi.encode(block.difficulty, blockhash(block.number))))).mod(
            availableSupply
        );

        // if there's a cache at _tokenIdsCache[i] then use it
        // otherwise use i itself
        index = _tokenIdsCache[i] == 0 ? i : _tokenIdsCache[i];

        // grab a number from the tail
        _tokenIdsCache[i] = _tokenIdsCache[availableSupply - 1] == 0
            ? availableSupply - 1
            : _tokenIdsCache[availableSupply - 1];
    }

    function getNextTokenId() internal override returns (uint256 index) {
        return _getNextRandomNumber() + 1;
    }

    function _hashMintPayload(
        uint256 _quantity,
        uint256 _value,
        address _account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SIGN_MINT_TYPEHASH, _quantity, _value, _account));
    }

    /**
     * @dev returns the number of tokens minted by `account`
     */
    function mintedTokensCount(address account) public view returns (uint256) {
        return _userMints[account];
    }
}
