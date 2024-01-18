// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./CollectionAutoEdition.sol";
import "./IMoneyHandler.sol";
import "./IFarmV2.sol";

enum CurrencyType {
    weth,
    ern,
    stone
}

contract FactoryAutoEdition is AccessControl {
    event NewCollection(
        string uri,
        uint256 total,
        uint256 startTime,
        uint256 endTime,
        uint256 amount,
        uint256 percent,
        address admin,
        address factoryAddress,
        uint8 currencyType
    );

    bytes32 public constant COLLECTION_ROLE =
        bytes32(keccak256("COLLECTION_ROLE"));

    address public farm;
    address public moneyHandler;
    address public treasury;

    address public priceFeed;
    IFarmV2 public Ifarm;
    IMoneyHandler public moneyHand;
    CollectionAutoEdition[] public collections;

    mapping(address => uint256) public tokenIds;
    address public operatorSubscription =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createCollection(
        string memory uri,
        uint256 _total,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _amount,
        uint256 _percent,
        address _admin,
        CurrencyType cType,
        address _token,
        address _stone
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        CollectionData memory collecData;

        collecData.uri = uri;
        collecData.total = _total;
        collecData.startTime = _startTime;
        collecData.endTime = _endTime;
        collecData.amount = _amount;
        collecData.percent = _percent;
        collecData.admin = _admin;
        collecData.factoryAddress = address(this);
        collecData.farm = farm;
        collecData.moneyHandler = moneyHandler;
        collecData.treasury = treasury;
        collecData.token = _token;
        collecData.stone = _stone;
        collecData.operatorSubscription = operatorSubscription;

        CollectionAutoEdition collection = new CollectionAutoEdition(
            collecData
        );

        collections.push(collection);

        giveRole(farm, address(collection));
        tokenIds[address(collection)] = 0;
        emit NewCollection(
            uri,
            _total,
            _startTime,
            _endTime,
            _amount,
            _percent,
            _admin,
            address(this),
            uint8(cType)
        );
        return address(collection);
    }

    function addExternalAddresses(
        address _farm,
        address _moneyHandler,
        address _treasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        farm = _farm;
        moneyHandler = _moneyHandler;
        treasury = _treasury;
    }

    function setPriceOracle(address _priceFeed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceFeed = _priceFeed;
    }

    function setOperatorSubscription(address _operatorSubscription)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        operatorSubscription = _operatorSubscription;
    }

    function giveRole(address _farmAddress, address _collec)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Ifarm = IFarmV2(_farmAddress);
        Ifarm.grantRole(COLLECTION_ROLE, _collec);
    }

    function collectionLength() external view returns (uint256) {
        return collections.length;
    }

    function getPriceOracle() external view returns (address) {
        return priceFeed;
    }

    function setTokenId(address collection, uint256 tokenId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenIds[collection] = tokenId;
    }

    function buy(
        address collection,
        address buyer,
        uint256 quantity
    ) external returns (uint256[] memory) {
        require(buyer == msg.sender, "Factory: you are not authorized");
        CollectionAutoEdition _collection = CollectionAutoEdition(collection);
        uint256[] memory result = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[collection] += 1;
            result[i] = tokenIds[collection];
        }
        _collection.buyBatch(buyer, result);
        return result;
    }

    function buyWithWhitelist(
        address collection,
        address buyer,
        uint256 quantity,
        bytes32[] calldata proof
    ) external returns (uint256[] memory) {
        require(buyer == msg.sender, "Factory: you are not authorized");
        CollectionAutoEdition _collection = CollectionAutoEdition(collection);
        uint256[] memory result = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[collection] += 1;
            result[i] = tokenIds[collection];
        }
        _collection.buyWithWhitelistBatch(buyer, result, proof);
        return result;
    }

    function mint(address collection, address buyer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        CollectionAutoEdition _collection = CollectionAutoEdition(collection);

        tokenIds[collection] += 1;
        _collection.mint(buyer, tokenIds[collection]);

        return tokenIds[collection];
    }

    function mintBatch(
        address collection,
        address buyer,
        uint256 count
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256[] memory) {
        CollectionAutoEdition _collection = CollectionAutoEdition(collection);
        uint256[] memory ids = new uint256[](count);
        uint256[] memory amounts = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[collection] += 1;
            ids[i] = tokenIds[collection];
            amounts[i] = 1;
        }
        _collection.mintBatch(buyer, ids, amounts);

        return ids;
    }
}
