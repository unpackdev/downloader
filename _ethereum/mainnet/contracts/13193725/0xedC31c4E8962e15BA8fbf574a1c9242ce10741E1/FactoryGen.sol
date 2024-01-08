// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./CollectionGen.sol";
import "./MoneyHandler.sol";
import "./FarmV2.sol";

enum CurrencyType {
    weth,
    ern,
    stone
}

contract FactoryGen is AccessControl {
    event NewCollection(
        string uri,
        uint256 total,
        uint256 startTime,
        uint256 endTime,
        uint256 amount,
        uint256 percent,
        address admin,
        address factoryAddress,
        address collectionAddress
    );
    event SetPfeedAddress(address priceFeed);
    event SetAddresses(address moneyHandler, address farm, address treasury);

    bytes32 public constant COLLECTION_ROLE =
        bytes32(keccak256("COLLECTION_ROLE"));

    address public farm;
    address public moneyHandler;
    address public treasury;

    address public priceFeed;
    FarmV2 public Ifarm;
    MoneyHandler public moneyHand;
    CollectionGen[] public collections;

    struct Card {
        CurrencyType cType;
        uint256 amount;
        uint256 total;
        uint256 startTime;
        uint256 endTime;
        uint256 percent;
        string uri;
    }

    mapping(address => Card) public cards;

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

        CollectionGen collection = new CollectionGen(collecData);

        collections.push(collection);

        cards[address(collection)] = Card(
            cType,
            _amount,
            _total,
            _startTime,
            _endTime,
            _percent,
            uri
        );

        giveRole(farm, address(collection));
        giveRoleMnyHnd(moneyHandler, address(collection));

        emit NewCollection(
            uri,
            _total,
            _startTime,
            _endTime,
            _amount,
            _percent,
            _admin,
            address(this),
            address(collection)
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

        emit SetAddresses(moneyHandler, farm, treasury);
    }

    function setPriceOracle(address _priceFeed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        priceFeed = _priceFeed;

        emit SetPfeedAddress(priceFeed);
    }

    function giveRole(address _farmAddress, address _collec)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Ifarm = FarmV2(_farmAddress);
        Ifarm.grantRole(COLLECTION_ROLE, _collec);
    }

    function giveRoleMnyHnd(address _moneyAddress, address _collec)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        moneyHand = MoneyHandler(_moneyAddress);
        moneyHand.grantRole(COLLECTION_ROLE, _collec);
    }

    function collectionLength() external view returns (uint256) {
        return collections.length;
    }

    function getPriceOracle() external view returns (address) {
        return priceFeed;
    }

    function buy(
        address collection,
        uint256 id,
        address buyer
    ) external returns (bool) {
        require(buyer == msg.sender, "Factory: you are not authorized ");

        CollectionGen _collection = CollectionGen(collection);

        _collection.buy(buyer, id);

        return true;
    }
}
