// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./ICollectionV3.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorInterface.sol";

contract MysteryDrop is ReentrancyGuard {
    // Add the library methods
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

/*==================================================== Events ==========================================================*/

    event CollectionsTiersSet(Tiers tier, address collection, uint256[] ids);
    event MysteryBoxDropped(
        Tiers tier,
        address collection,
        uint256 id,
        address user
    );
    event MysteryBoxCC(Tiers tier, address user, string purchaseId);

/*==================================================== Modifiers ==========================================================*/

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not Authorized");
        _;
    }

    modifier isStarted() {
        require(startTime <= block.timestamp && endTime > block.timestamp, "Drop has not started yet!");
        _;
    }

   

/*==================================================== State Variables ==========================================================*/

    enum Tiers {
        TierOne,
        TierTwo,
        TierThree
    }

    // These will keep decks' indexes
    EnumerableSet.UintSet private firstDeckIndexes;
    EnumerableSet.UintSet private secondDeckIndexes;
    EnumerableSet.UintSet private thirdDeckIndexes;

    //index counter
    Counters.Counter public firstDeckIndexCounter;
    Counters.Counter public secondDeckIndexCounter;
    Counters.Counter public thirdDeckIndexCounter;

    bytes[] public firstDeck;
    bytes[] public secondDeck;
    bytes[] public thirdDeck;

    // address of the admin
    address admin;
    //start/end time of the contract
    uint256 public startTime;
    uint256 public endTime;
    // Tier price infos
    mapping(Tiers => uint256) public tierPrices;
    // Collection card number infos
    mapping(address => uint256) private cardNumbers;
    mapping(address => bool) private authorizedAddresses;
    IERC20 ern;
    // ERN price feed contract
    AggregatorInterface ernOracleAddr;

    //Deck Max Size
    uint32 public firstDeckLimit = 0;
    uint32 public secondDeckLimit = 0;
    uint32 public thirdDeckLimit = 0;

/*==================================================== Constructor ==========================================================*/

    constructor(IERC20 _ern, AggregatorInterface _ernOracle) {
        ern = _ern;
        ernOracleAddr = _ernOracle;
        admin = msg.sender;
        startTime = 0;
        endTime = 0;
    }

/*==================================================== Functions ==========================================================*/

/*==================================================== Read Functions ==========================================================*/

    /*
     *Returns the current price of the ERN token
    */
    function getPrice() public view returns (uint256) {
        return uint256(ernOracleAddr.latestAnswer());
    }

    /*
     *Returns the amount of the ERN token to transfer
    */
    function computeErnAmount(uint256 _subscriptionPrice, uint256 _ernPrice)
        public
        pure
        returns (uint256)
    {
        uint256 result = (_subscriptionPrice * 10**18) / _ernPrice;
        return result;
    }

    /*
     *Internal Returns the random card
    */
    function _getRandom(uint256 gamerange, uint256 seed)
        internal
        view
        virtual
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            uint256(
                                keccak256(abi.encodePacked(block.coinbase))
                            ) +
                            seed
                    )
                )
            ) % gamerange;
    }

    /*
     * Get the number of available boxes for a tier
     */
    function getAvailable(Tiers _tier) public view returns (uint256) {
        if (_tier == Tiers.TierOne) {
            return firstDeckIndexes.length();
        } else if (_tier == Tiers.TierTwo) {
            return secondDeckIndexes.length();
        } else if (_tier == Tiers.TierThree) {
            return thirdDeckIndexes.length();
        }
        return 0;
    }


/*==================================================== External Functions ==========================================================*/

    /*
     *This function sets the collection with the cards by admin via internal call
    */
    function setCollection(
        Tiers _tier,
        address _collection,
        uint256[] calldata _ids
    ) external onlyAdmin {
        uint256 length = _ids.length;
        for (uint16 i = 0; i < length; ) {
            _setCollection(_tier, _collection, _ids[i]);
            unchecked {
                ++i;
            }
        }
        emit CollectionsTiersSet(_tier, _collection, _ids);
    }

    /*
     *This function sets the collections with the cards by admin via internal call
    */
    function setCollectionsBatch(
        Tiers _tier,
        address[] calldata _collections,
        uint256[] calldata _ids
    ) external onlyAdmin {
        uint256 last;
        for (uint256 j = 0; j < _collections.length; j++) {
            for (
                uint256 i = last;
                i < last + cardNumbers[_collections[j]];
                i++
            ) {
                _setCollection(_tier, _collections[j], _ids[i]);
            }
            last += cardNumbers[_collections[j]];
        }
    }

    /*
     *This function resets the decks by the admin
    */
    function resetTierDeck(Tiers _tier) external onlyAdmin {
        if (_tier == Tiers.TierOne) {
            firstDeck = new bytes[](0);
            firstDeckIndexCounter._value = 0;
            for (
                uint256 i = 0;
                i < firstDeckIndexes._inner._values.length;
                i++
            ) {
                firstDeckIndexes._inner._indexes[
                    firstDeckIndexes._inner._values[i]
                ] = 0;
            }
            firstDeckIndexes._inner._values = new bytes32[](0);
        } else if (_tier == Tiers.TierTwo) {
            secondDeck = new bytes[](0);
            secondDeckIndexCounter._value = 0;
            for (
                uint256 i = 0;
                i < secondDeckIndexes._inner._values.length;
                i++
            ) {
                secondDeckIndexes._inner._indexes[
                    secondDeckIndexes._inner._values[i]
                ] = 0;
            }
            secondDeckIndexes._inner._values = new bytes32[](0);
        } else if (_tier == Tiers.TierThree) {
            thirdDeck = new bytes[](0);
            thirdDeckIndexCounter._value = 0;
            for (
                uint256 i = 0;
                i < thirdDeckIndexes._inner._values.length;
                i++
            ) {
                thirdDeckIndexes._inner._indexes[
                    thirdDeckIndexes._inner._values[i]
                ] = 0;
            }
            thirdDeckIndexes._inner._values = new bytes32[](0);
        } else revert("wrong parameter!");
    }

    /*
     *This function sets the card prices per Tier by the admin
    */
    function tierPricesSet(Tiers[] memory _tiers, uint256[] memory _prices)
        external
        onlyAdmin
    {
        for (uint8 i = 0; i < _tiers.length; i++) {
            tierPrices[_tiers[i]] = _prices[i];
        }
    }

    /*
     *This function sets the number of cards per collection by admin
    */
    function setCardNumbers(
        address[] calldata _collections,
        uint256[] calldata numberofIds
    ) external onlyAdmin {
        for (uint256 i = 0; i < _collections.length; i++) {
            cardNumbers[_collections[i]] = numberofIds[i];
        }
    }
    /*
     *This function sets the authorized address for Credit Card sell
    */
    function setAuthorizedAddr(address _addr) external onlyAdmin{
        authorizedAddresses[_addr] = true;
    }

    /*
     *This function removes the authorized address for Credit Card sell
    */
    function removeAuthorizedAddr(address _addr) external onlyAdmin{
        authorizedAddresses[_addr] = false;
    }
    

    /*
     *User can buy mysteryBox via this function with creditcard
    */
   function buyCreditMysteryBox(address _user, Tiers _tier, string calldata _purchaseId) external onlyAuthorized {
        _buy(_user, _tier);
        emit MysteryBoxCC(_tier, _user, _purchaseId);
    }


    /*
     *User can buy mysteryBox via this function with token payment
    */
    function buyMysteryBox(Tiers _tier) external isStarted nonReentrant {
        uint256 _ernAmount = _buy(msg.sender, _tier);
        ern.transferFrom(msg.sender, address(this), _ernAmount);
    }

    /*
     *Admin can start the contract via this function
    */
    function setTimestamps(uint256 _start, uint256 _end) external onlyAdmin {
        startTime = _start;
        endTime = _end;
    }

    /*
     *Admin can withdraw earning with given amount
    */
    function withdrawFundsPartially(uint256 _amount, address _to)
        external
        onlyAdmin
    {
        require(
            ern.balanceOf(address(this)) >= _amount,
            "Amount exceeded ern balance"
        );
        ern.transfer(_to, _amount);
    }

    /*
     *Admin can withdraw all of th earning
    */
    function withdrawAllFunds(address _to) external onlyAdmin {
        uint256 _balance = ern.balanceOf(address(this));
        ern.transfer(_to, _balance);
    }

    /*
    * This functions set the decks maximum limit
    */ 
    function setDeckMaxLimit(uint32 first, uint32 second, uint32 third) external onlyAdmin {
        firstDeckLimit = first;
        secondDeckLimit = second;
        thirdDeckLimit = third;
    }

    /*
    * This functions set the admin of the contract
    */ 
    function setAdmin(address _admin) external onlyAdmin {
       require(_admin != address(0), "Not allowed to renounce admin");
       admin = _admin;
    }


/*==================================================== Internal Functions ==========================================================*/

    /*
     *This function picks random card and mints this random card to user
    */
    function _buy(address _user, Tiers _tier) internal returns (uint256) {
        uint256 _ernPrice = getPrice();
        uint256 ernAmount;
        uint256 random;
        uint256 index;
        address _contract;
        uint256 _id;
        if (_tier == Tiers.TierOne) {
            require(
                firstDeckIndexes.length() > 0,
                "There is no card left in Tier 1!"
            );
            ernAmount = computeErnAmount(tierPrices[Tiers.TierOne], _ernPrice);
            random = _getRandom(firstDeckIndexes.length(), _ernPrice);
            index = firstDeckIndexes.at(random);
            firstDeckIndexes.remove(index);
            (_contract, _id) = abi.decode(firstDeck[index], (address, uint256));
        } else if (_tier == Tiers.TierTwo) {
            require(
                secondDeckIndexes.length() > 0,
                "There is no card left in Tier 2!"
            );
            ernAmount = computeErnAmount(tierPrices[Tiers.TierTwo], _ernPrice);
            random = _getRandom(secondDeckIndexes.length(), _ernPrice);
            index = secondDeckIndexes.at(random);
            secondDeckIndexes.remove(index);
            (_contract, _id) = abi.decode(
                secondDeck[index],
                (address, uint256)
            );
        } else if (_tier == Tiers.TierThree) {
            require(
                thirdDeckIndexes.length() > 0,
                "There is no card left in Tier 3!"
            );
            ernAmount = computeErnAmount(
                tierPrices[Tiers.TierThree],
                _ernPrice
            );
            random = _getRandom(thirdDeckIndexes.length(), _ernPrice);
            index = thirdDeckIndexes.at(random);
            thirdDeckIndexes.remove(index);
            (_contract, _id) = abi.decode(thirdDeck[index], (address, uint256));
        } else {
            revert("Wrong Tier Parameter!");
        }

        ICollectionV3(_contract).mint(_user, _id);
        emit MysteryBoxDropped(_tier, _contract, _id, _user);
        return ernAmount;
    }

    /*
     *This function sets the collection with the cards by admin
    */
    function _setCollection(
        Tiers _tier,
        address _collection,
        uint256 _id
    ) internal {
        if (_tier == Tiers.TierOne) {
            require(firstDeck.length <= firstDeckLimit, "More than Tier Limit!");
            firstDeck.push(abi.encode(_collection, _id));
            firstDeckIndexes.add(firstDeckIndexCounter.current());
            firstDeckIndexCounter.increment();
        } else if (_tier == Tiers.TierTwo) {
            require(secondDeck.length <= secondDeckLimit, "More than Tier Limit!");
            secondDeck.push(abi.encode(_collection, _id));
            secondDeckIndexes.add(secondDeckIndexCounter.current());
            secondDeckIndexCounter.increment();
        } else if (_tier == Tiers.TierThree) {
            require(thirdDeck.length <= thirdDeckLimit, "More than Tier Limit!");
            thirdDeck.push(abi.encode(_collection, _id));
            thirdDeckIndexes.add(thirdDeckIndexCounter.current());
            thirdDeckIndexCounter.increment();
        } else {
            revert("Wrong Tier Parameter!");
        }
    }
}