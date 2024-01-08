// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./Collection.sol";
import "./MoneyHandler.sol";
import "./FarmV2.sol";

enum CurrencyType {weth, ern, stone}

contract Factory is AccessControl {
    
    bytes32 public constant COLLECTION_ROLE = bytes32(keccak256("COLLECTION_ROLE"));
    
    FarmV2 public Ifarm;
    MoneyHandler public moneyHand;
    Collection[] public collections;
    
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

    constructor(address admin) public {
     _setupRole(DEFAULT_ADMIN_ROLE, admin);
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
        address _farmAddress,
        address _moneyHandler
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        Collection collection =
            new Collection(uri, _total, _startTime, _endTime, _amount, _percent, _admin, address(this));

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

        giveRole(_farmAddress, address(collection));
        giveRoleMnyHnd(_moneyHandler, address(collection));
        return address(collection);
    }

    function collectionLength() external view returns (uint256) {
        return collections.length;
    }

    function giveRole(address _farmAddress, address _collec) public onlyRole(DEFAULT_ADMIN_ROLE){
        Ifarm = FarmV2(_farmAddress);
        Ifarm.grantRole(COLLECTION_ROLE, _collec);
    
    }

    function giveRoleMnyHnd(address _moneyAddress, address _collec) public onlyRole(DEFAULT_ADMIN_ROLE){
        moneyHand = MoneyHandler(_moneyAddress);
        moneyHand.grantRole(COLLECTION_ROLE, _collec);
        
    }

    function buy(
        address collection,
        uint256 id,
        address buyer
    ) external returns (bool) {
        require(buyer == msg.sender);

        Collection _collection = Collection(collection);

        _collection.buy(buyer, id);

        return true;
    }
}
