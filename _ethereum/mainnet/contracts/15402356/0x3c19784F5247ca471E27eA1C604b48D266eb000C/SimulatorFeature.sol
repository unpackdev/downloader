// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./LibAggregatorStorage.sol";
import "./FixinTokenSpender.sol";
import "./ISimulator.sol";


contract SimulatorFeature is ISimulator, FixinTokenSpender {

    uint256 public constant WETH_MARKET_ID = 999;
    address public immutable WETH;

    constructor(address weth) {
        WETH = weth;
    }

    function batchBuyWithETHSimulate(TradeDetails[] calldata tradeDetails) external payable override {
        // simulate trade and revert
        bytes memory error = abi.encodePacked(_simulateTrade(tradeDetails));
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function batchBuyWithERC20sSimulate(
        IAggregator.ERC20Pair[] calldata erc20Pairs,
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable override {
        // transfer ERC20 tokens from the sender to this contract
        _transferERC20Pairs(erc20Pairs);

        uint256 result = _simulateTrade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        bytes memory error = abi.encodePacked(result);
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function _simulateTrade(TradeDetails[] calldata tradeDetails) internal returns (uint256 result) {
        unchecked {
            LibAggregatorStorage.Storage storage stor = LibAggregatorStorage.getStorage();
            for (uint256 i = 0; i < tradeDetails.length; ++i) {
                bool success;
                TradeDetails calldata item = tradeDetails[i];

                if (item.marketId == WETH_MARKET_ID) {
                    (success, ) = WETH.call{value: item.value}(item.tradeData);
                } else {
                    LibAggregatorStorage.Market memory market = stor.markets[item.marketId];
                    if (market.isActive) {
                        (success,) = market.isLibrary ?
                            market.proxy.delegatecall(item.tradeData) :
                            market.proxy.call{value: item.value}(item.tradeData);
                    }
                }

                if (success) {
                    result |= 1 << i;
                }
            }
            return result;
        }
    }

    function _transferERC20Pairs(IAggregator.ERC20Pair[] calldata erc20Pairs) internal {
        // transfer ERC20 tokens from the sender to this contract
        if (erc20Pairs.length > 0) {
            assembly {
                let ptr := mload(0x40)
                let end := add(erc20Pairs.offset, mul(erc20Pairs.length, 0x40))

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                for { let offset := erc20Pairs.offset } lt(offset, end) { offset := add(offset, 0x40) } {
                    let amount := calldataload(add(offset, 0x20))
                    if gt(amount, 0) {
                        mstore(add(ptr, 0x44), amount)
                        let success := call(gas(), calldataload(offset), 0, ptr, 0x64, 0, 0)
                    }
                }
            }
        }
    }

    function _returnDust(address[] calldata tokens) internal {
        // return remaining tokens (if any)
        for (uint256 i; i < tokens.length; ) {
            _transferERC20WithoutCheck(tokens[i], msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            unchecked { ++i; }
        }
    }
}
