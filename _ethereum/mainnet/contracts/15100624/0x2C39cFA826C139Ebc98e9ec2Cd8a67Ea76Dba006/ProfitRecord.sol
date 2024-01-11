// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RootDB.sol";
import "./ContextUpgradeable.sol";

contract ProfitRecord is ContextUpgradeable {

    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;


    struct PRICE_STORE {
        //weighted average price
        uint256 price;
        // amount
        uint256 amount;
    }
    // address -> PRICE_STORE  map
    mapping(address => PRICE_STORE) public profitStore;


    modifier onlyDepositContract() {
        require(msg.sender == RootDB(ROOT_DB).depositContract(), "Caller is not depositContract");
        _;
    }

    constructor(address _torn_contract, address _root_db) {
        TORN_CONTRACT = _torn_contract;
        ROOT_DB = _root_db;
    }

    function __ProfitRecord_init() public initializer {
        __Context_init();
    }


    /**
    * @notice Deposit used to record the price
             this  is called when user deposit torn to the system
    * @param  _addr the user's address
    * @param  _torn_amount is the  the user's to deposit amount
    * @param  _token_qty is amount of voucher which the user get
      @dev    if the user Deposit more than once function will calc weighted average
   **/
    function deposit(address _addr, uint256 _torn_amount, uint256 _token_qty) onlyDepositContract public {
        PRICE_STORE memory userStore = profitStore[_addr];
        if (userStore.amount == 0) {
            uint256 new_price = _torn_amount * (10 ** 18) / _token_qty;
            profitStore[_addr].price = new_price;
            profitStore[_addr].amount = _token_qty;
        } else {
            // calc weighted average
            profitStore[_addr].price = (userStore.amount * userStore.price + _torn_amount * (10 ** 18)) / (_token_qty + userStore.amount);
            profitStore[_addr].amount = _token_qty + userStore.amount;
        }

    }

    /**
     * @notice withDraw used to clean record
             this  is called when user withDraw
     * @param  _addr the user's address
     * @param  _token_qty is amount of voucher which the user want to withdraw
   **/
    function withDraw(address _addr, uint256 _token_qty) onlyDepositContract public returns (uint256 profit) {
        profit = getProfit(_addr, _token_qty);
        if (profitStore[_addr].amount > _token_qty) {
            profitStore[_addr].amount -= _token_qty;
        }
        else {
            delete profitStore[_addr];
        }
    }

    /**
     * @notice getProfit used to calc profit
     * @param  _addr the user's address
     * @param  _token_qty is amount of voucher which the user want to calc
     * @dev  RootDB(ROOT_DB).valueForTorn(_token_qty) only calc the torn and ignored  eth and other tokens
             so before operator swap to torn it  will been defective then we have to return profit 0
   **/
    function getProfit(address _addr, uint256 _token_qty) public view returns (uint256 profit){
        PRICE_STORE memory userStore = profitStore[_addr];
        require(userStore.amount >= _token_qty, "err root token");
        uint256 now_value = RootDB(ROOT_DB).valueForTorn(_token_qty);
        uint256 last_value = userStore.price * _token_qty / 10 ** 18;
        if(now_value > last_value){
            profit = now_value - last_value;
        }else{
           profit = 0;
        }
    }

}
