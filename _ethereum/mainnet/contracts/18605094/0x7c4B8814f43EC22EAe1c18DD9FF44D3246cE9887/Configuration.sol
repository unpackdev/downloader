// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./OwnableUpgradeable.sol";

contract Configuration is OwnableUpgradeable {
    enum ContractType {
        Starter,
        Trader,
        Pro
    }

    struct Subscription {
        uint price;
        uint configPrice;
        uint configs;
        uint duration;
        uint refreshPrice;
    }

    enum GasType {
        Normal,
        Speed,
        Ultra
    }

    address public targetWallet;
    mapping(address => bool) public isBuyer;
    mapping(ContractType => Subscription) public contractToSubscription;
    mapping(GasType => uint) public pricePerSetting;

    event SubscriptionUpdated(
        Subscription oldSubscription,
        Subscription newSubscription,
        ContractType contractType,
        uint price,
        uint configPrice,
        uint configs,
        uint duration,
        uint refreshPrice
    );
    event BuyerAdded(address indexed account);
    event BuyerRemoved(address indexed account);
    event GasPriceUpdated(uint oldPrice, uint newPrice, GasType type_);

    function initialize(
        Subscription memory starterSubscription,
        Subscription memory traderSubscription,
        Subscription memory proSubscription,
        uint normalGas_,
        uint speedGas_,
        uint ultraGas_,
        address targetWallet_,
        address[] memory BuyerWallets_
    ) public initializer {
        __Ownable_init(msg.sender);
        contractToSubscription[ContractType.Starter] = starterSubscription;
        contractToSubscription[ContractType.Trader] = traderSubscription;
        contractToSubscription[ContractType.Pro] = proSubscription;
        pricePerSetting[GasType.Normal] = normalGas_;
        pricePerSetting[GasType.Speed] = speedGas_;
        pricePerSetting[GasType.Ultra] = ultraGas_;

        targetWallet = targetWallet_;
        for (uint i = 0; i < BuyerWallets_.length; i++) {
            _addBuyer(BuyerWallets_[i]);
        }
    }

    function addBuyer(address account) public onlyOwner {
        _addBuyer(account);
    }

    function removeBuyer(address account) public onlyOwner {
        _removeBuyer(account);
    }

    function _addBuyer(address account) internal {
        isBuyer[account] = true;
        emit BuyerAdded(account);
    }

    function getBuyer(address buyer_) public view virtual returns (bool) {
        return isBuyer[buyer_];
    }

    function _removeBuyer(address account) internal {
        isBuyer[account] = false;
        emit BuyerRemoved(account);
    }

    function setSubscriptionConfig(
        ContractType contractType_,
        Subscription memory subscription_
    ) public onlyOwner {
        Subscription memory currentSubscription = contractToSubscription[
            contractType_
        ];
        contractToSubscription[contractType_].price = subscription_.price;
        contractToSubscription[contractType_].configs = subscription_.configs;
        contractToSubscription[contractType_].duration = subscription_.duration;
        contractToSubscription[contractType_].configPrice = subscription_
            .configPrice;
        contractToSubscription[contractType_].refreshPrice = subscription_
            .refreshPrice;
        emit SubscriptionUpdated(
            currentSubscription,
            contractToSubscription[contractType_],
            contractType_,
            subscription_.price,
            subscription_.configPrice,
            subscription_.configs,
            subscription_.duration,
            subscription_.refreshPrice
        );
    }

    function getSubscriptionPrice(
        ContractType contractType_
    ) external view returns (uint) {
        return contractToSubscription[contractType_].price;
    }

    function getAddConfigPrice(
        ContractType contractType_
    ) external view virtual returns (uint) {
        return contractToSubscription[contractType_].configPrice;
    }

    function getSubscriptionDuration(
        ContractType contractType_
    ) external view returns (uint) {
        return contractToSubscription[contractType_].duration;
    }

    function getSubscriptionConfigs(
        ContractType contractType_
    ) external view returns (uint) {
        return contractToSubscription[contractType_].configs;
    }

    function getRefreshPrice(
        ContractType contractType_
    ) external view returns (uint) {
        return contractToSubscription[contractType_].refreshPrice;
    }

    function setAddGas(GasType type_, uint speed_) public onlyOwner {
        uint oldPrice = pricePerSetting[type_];
        pricePerSetting[type_] = speed_;
        emit GasPriceUpdated(oldPrice, pricePerSetting[type_], type_);
    }

    function getGas(GasType speed_) public view virtual returns (uint) {
        return pricePerSetting[speed_];
    }

    function setTargetWallet(address targetWallet_) public onlyOwner {
        require(
            targetWallet_ != address(0),
            "Target wallet must be valid address"
        );
        targetWallet = targetWallet_;
    }

    function getTargetWallet() public view virtual returns (address) {
        return targetWallet;
    }
}
