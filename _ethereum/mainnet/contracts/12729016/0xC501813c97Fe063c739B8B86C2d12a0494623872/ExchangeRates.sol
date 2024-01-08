// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./AggregatorV2V3Interface.sol";

import "./IExchangeRates.sol";

contract ExchangeRates is Ownable, IExchangeRates {
    using SafeMath for uint;

    uint32 private _indexNext = 1;
    mapping(bytes32 => address) private _aggregators;
    mapping(bytes32 => uint32) private _key2Indexs;
    mapping(uint32 => bytes32) private _Indexs2Keys;
    mapping(uint32 => address) private _keyAddressIndexs;

    uint private constant DECIMALS18 = 18;

    function addCurrencyKey(bytes32 currencyKey_, address aggregator_) external override onlyOwner {
        require(address(_aggregators[currencyKey_]) == address(0), "aggregator already exist");
        AggregatorV2V3Interface aggregator = AggregatorV2V3Interface(aggregator_);

        require(aggregator.latestRound() >= 0, "Given Aggregator is invalid");

        _aggregators[currencyKey_] = aggregator_;
        _indexNext++;

        uint32 idx = _indexNext;
        _Indexs2Keys[idx] = currencyKey_;
        _key2Indexs[currencyKey_] = idx;
        _keyAddressIndexs[idx] = aggregator_;
        
        emit AddCurrencyKey(currencyKey_, aggregator_, idx);
    }

    function updateCurrencyKey(bytes32 currencyKey_, address aggregator_) external override onlyOwner {
        address oldAggregator = address(_aggregators[currencyKey_]);
        require(oldAggregator != address(0), "aggregator does not exist");

        AggregatorV2V3Interface aggregator = AggregatorV2V3Interface(aggregator_);
        require(aggregator.latestRound() >= 0, "Given Aggregator is invalid");

        // update map to address
        _aggregators[currencyKey_] = aggregator_;

        // update the index
        // update address to aggregator for a currencyKey will not update the idx

        uint32 idx = _key2Indexs[currencyKey_];
        require(idx != 0, "The currency key int be indexed!");
        require(oldAggregator == _keyAddressIndexs[idx], "The idx to address not eq to old");

        _keyAddressIndexs[idx] = aggregator_;

        emit UpdateCurrencyKey(currencyKey_, oldAggregator, aggregator_, idx);
    }

    function deleteCurrencyKey(bytes32 currencyKey_) external override onlyOwner {
        delete _aggregators[currencyKey_];

        // not to delete index to key, but delete the idx to address
        uint32 idx = _key2Indexs[currencyKey_];
        require(idx != 0, "The currency key int be indexed!");

        delete _keyAddressIndexs[idx];

        emit DelCurrencyKey(currencyKey_, idx);
    }

    function rateForCurrency(bytes32 currencyKey_) external override view returns (uint32, uint) {
        address aggregatorAddr = _aggregators[currencyKey_];
        require(aggregatorAddr != address(0), "aggregator does not exist");

        uint32 idx = _key2Indexs[currencyKey_];

        uint price = uint(AggregatorV2V3Interface(aggregatorAddr).latestAnswer());
        uint decimals = DECIMALS18.sub(uint(AggregatorV2V3Interface(aggregatorAddr).decimals()));

        return (idx, price.mul(10 ** decimals));
    }

    function rateForCurrencyByIdx(uint32 idx) external override view returns (uint) {
        address aggregatorAddr = _keyAddressIndexs[idx];
        require(aggregatorAddr != address(0), "aggregator does not exist");

        uint price = uint(AggregatorV2V3Interface(aggregatorAddr).latestAnswer());
        uint decimals = DECIMALS18.sub(uint(AggregatorV2V3Interface(aggregatorAddr).decimals()));

        return price.mul(10 ** decimals);
    }

    function currencyKeyExist(bytes32 currencyKey_) external override view returns (bool) {
        return (_aggregators[currencyKey_] != address(0));
    }

    event AddCurrencyKey(bytes32 indexed key, address aggregator, uint32 idx);
    event UpdateCurrencyKey(bytes32 indexed key, address from, address to, uint32 idx);
    event DelCurrencyKey(bytes32 indexed key, uint32 idx);
}
