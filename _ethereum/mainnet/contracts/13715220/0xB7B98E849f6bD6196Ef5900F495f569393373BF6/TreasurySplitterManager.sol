// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ITreasurySplitterManager.sol";
import "./LazyInitCapableElement.sol";
import "./GeneralUtilities.sol";
import "./KnowledgeBase.sol";
import "./IOrganization.sol";
import "./IERC20.sol";

contract TreasurySplitterManager is ITreasurySplitterManager, LazyInitCapableElement {
    using ReflectionUtilities for address;
    using Getters for IOrganization;
    using TransferUtilities for address;

    uint256 public constant override ONE_HUNDRED = 1e18;

    uint256 public override flushExecutorRewardPercentage;
    uint256 public override executorRewardPercentage;

    uint256 public override lastSplitBlock;
    uint256 public override splitInterval;

    bytes32[] private _keys;
    uint256[] private _percentages;

    bytes32 private _flushKey;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override virtual returns (bytes memory) {
        uint256 firstSplitBlock;
        (firstSplitBlock, splitInterval, _keys, _percentages, _flushKey, flushExecutorRewardPercentage, executorRewardPercentage) = abi.decode(lazyInitData, (uint256, uint256, bytes32[], uint256[], bytes32, uint256, uint256));
        _setKeysAndPercentages(_keys, _percentages);
        lastSplitBlock = firstSplitBlock < splitInterval ? firstSplitBlock : (firstSplitBlock - splitInterval);
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(ITreasurySplitterManager).interfaceId ||
            interfaceId == this.ONE_HUNDRED.selector ||
            interfaceId == this.lastSplitBlock.selector ||
            interfaceId == this.splitInterval.selector ||
            interfaceId == this.nextSplitBlock.selector ||
            interfaceId == this.executorRewardPercentage.selector ||
            interfaceId == this.receiversAndPercentages.selector ||
            interfaceId == this.splitTreasury.selector;
    }

    receive() external payable {
    }

    function nextSplitBlock() public view override returns(uint256) {
        return lastSplitBlock == 0 ? 0 : (lastSplitBlock + splitInterval);
    }

    function receiversAndPercentages() public override view returns (bytes32[] memory keys, address[] memory addresses, uint256[] memory percentages) {
        keys = _keys;
        addresses = IOrganization(host).list(keys);
        percentages = _percentages;
    }

    function flushReceiver() public override view returns(bytes32 key, address addr) {
        addr = IOrganization(host).get(key = _flushKey);
    }

    function splitTreasury(address executorRewardAddress) external override {
        require(block.number >= nextSplitBlock(), "Too early, BRO");
        lastSplitBlock = block.number;

        uint256 availableAmount = address(this).balance;

        require(availableAmount > 0, "balance");

        uint256 receiverAmount = 0;

        if(executorRewardPercentage > 0) {
            address to = executorRewardAddress == address(0) ? msg.sender : executorRewardAddress;
            to.submit(receiverAmount = _calculatePercentage(availableAmount, executorRewardPercentage), "");
            availableAmount -= receiverAmount;
        }

        uint256 remainingAmount = availableAmount;

        (bytes32[] memory keys, address[] memory addresses, uint256[] memory percentages) = receiversAndPercentages();

        address parentTreasury = address(IOrganization(host).treasuryManager());

        if(addresses.length == 0) {
            parentTreasury.submit(remainingAmount, "");
            emit Splitted(bytes32(0), parentTreasury, remainingAmount);
            return;
        }

        address receiver;
        for(uint256 i = 0; i < addresses.length - 1; i++) {
            receiver = addresses[i];
            receiver = receiver != address(0) ? receiver : parentTreasury;
            receiverAmount = _calculatePercentage(availableAmount, percentages[i]);
            receiver.submit(receiverAmount, "");
            emit Splitted(keys[i], receiver, receiverAmount);
            remainingAmount -= receiverAmount;
        }

        receiver = addresses[addresses.length - 1];
        receiver = receiver != address(0) ? receiver : parentTreasury;
        receiver.submit(remainingAmount, "");
        emit Splitted(keys[addresses.length - 1], receiver, remainingAmount);
    }

    function flushERC20Tokens(address[] calldata tokenAddresses, address executorRewardReceiver) external override {
        address to = executorRewardReceiver != address(0) ? executorRewardReceiver : msg.sender;
        (,address wallet) = flushReceiver();
        wallet = wallet != address(0) ? wallet : address(IOrganization(host).treasuryManager());
        require(wallet != address(0), "zero");
        require(tokenAddresses.length > 0, "tokens");
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            require(tokenAddress != address(0), "token");
            uint256 availableAmount = IERC20(tokenAddress).balanceOf(address(this));
            require(availableAmount > 0, "value");
            if(flushExecutorRewardPercentage > 0) {
                uint256 receiverAmount = _calculatePercentage(availableAmount, flushExecutorRewardPercentage);
                tokenAddress.safeTransfer(to, receiverAmount);
                availableAmount -= receiverAmount;
            }
            tokenAddress.safeTransfer(wallet, availableAmount);
        }
    }

    function _calculatePercentage(uint256 totalSupply, uint256 percentage) private pure returns(uint256) {
        return (totalSupply * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    function _setKeysAndPercentages(bytes32[] memory keys, uint256[] memory percentages) private {
        delete _keys;
        delete _percentages;
        uint256 percentage = 0;
        if(keys.length > 0) {
            for(uint256 i = 0; i < keys.length - 1; i++) {
                _keys.push(keys[i]);
                _percentages.push(percentages[i]);
                percentage += percentages[i];
            }
            _keys.push(keys[keys.length - 1]);
        }
        require(percentage < ONE_HUNDRED, "overflow");
    }
}