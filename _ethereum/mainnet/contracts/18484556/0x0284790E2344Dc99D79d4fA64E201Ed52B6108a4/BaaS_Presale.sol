// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IBull20.sol";
import "./IToken.sol";
import "./IRateProvider.sol";
import "./Stage.sol";
import "./Holder.sol";

contract BaaS_Presale is Holder {
    event SetInstanceAddressEvent(address indexed instance);
    event SendEthToInstance(uint256 value);
    event BuyEvent();
    event StatusEvent(bool enabled);
    event SetRateProviderEvent(address indexed rateProvider);
    event EditStageEvent(uint indexed index, uint256 priceUSD, uint256 expectedValue);
    event DeleteLastStageEvent();
    event AirdropEvent();
    event WithdrawEvent();

    address private _instance;

    function setInstanceAddress(address instance) onlyHolder external {
        require(instance.code.length != 0, "Invalid contract");
        _instance = instance;
        emit SetInstanceAddressEvent(instance);
    }

    function getInstanceAddress() external view returns (address) {
        return _instance;
    }

    function _getInstance() private view returns (IBull20) {
        address inst = _instance;
        require(inst != address(0x0), "Instance is not configured");
        return IBull20(inst);
    }

    // public overrides

    function holders() external view returns (address[] memory) {
        return _getInstance().holders();
    }

    function enabled() external view returns (bool) {
        return _getInstance().enabled();
    }

    function rateProvider() external view returns (IRateProvider) {
        return _getInstance().rateProvider();
    }

    function stages() public view returns (Stage[] memory) {
        return _getInstance().stages();
    }

    function activeStage() public view returns (Stage memory) {
        return _getInstance().activeStage();
    }

    function totalRaised() external view returns (uint256) {
        return _getInstance().totalRaised();
    }

    function presaleAmount(address _wallet) external view returns (uint256) {
        return _getInstance().presaleAmount(_wallet);
    }

    // user overrides

    function buy(uint256 amount, address token) external payable {
        _getInstance().buy(amount, token, msg.value, msg.sender);

        if (address(this).balance == 0) {
            return;
        }

        payable(_instance).transfer(address(this).balance);
    }

    // owner overrides

    function disable() external onlyHolder {
        emit StatusEvent(false);
        return _getInstance().disable();
    }

    function enable() external onlyHolder {
        emit StatusEvent(true);
        return _getInstance().enable();
    }

    function setRateProvider(address rateProvider_) public onlyHolder {
        emit SetRateProviderEvent(rateProvider_);
        return _getInstance().setRateProvider(rateProvider_);
    }

    function addStage(uint256 priceUSD, uint256 expectedValue) external onlyHolder returns (Stage memory) {
        Stage memory stage = _getInstance().addStage(priceUSD, expectedValue);
        return stage;
    }

    function addStages(uint256[] memory prices, uint256[] memory expectedValues) external onlyHolder {
        return _getInstance().addStages(prices, expectedValues);
    }

    function editStage(uint index, uint256 priceUSD, uint256 expectedValue) external onlyHolder returns (Stage memory) {
        emit EditStageEvent(index, priceUSD, expectedValue);
        return _getInstance().editStage(index, priceUSD, expectedValue);
    }

    function deleteLastStage() external onlyHolder {
        emit DeleteLastStageEvent();
        return _getInstance().deleteLastStage();
    }

    function airdrop(address wallet, uint256 amount) external onlyHolder {
        emit AirdropEvent();
        return _getInstance().airdrop(wallet, amount);
    }

    function airdropMany(address[] memory wallets, uint256[] memory amounts) external onlyHolder {
        emit AirdropEvent();
        return _getInstance().airdropMany(wallets, amounts);
    }

    function withdraw() external onlyHolder payable {
        emit WithdrawEvent();
        return _getInstance().withdraw(holder());
    }
}