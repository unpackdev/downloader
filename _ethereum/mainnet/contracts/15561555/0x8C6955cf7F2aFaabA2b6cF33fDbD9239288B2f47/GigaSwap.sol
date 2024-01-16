pragma solidity ^0.8.17;
import "./Swapper.sol";
import "./FeeSettingsDecorator.sol";

contract GigaSwap is Swapper, FeeSettingsDecorator {
    constructor(address feeSettingsAddress)
        FeeSettingsDecorator(feeSettingsAddress)
    {}
}
