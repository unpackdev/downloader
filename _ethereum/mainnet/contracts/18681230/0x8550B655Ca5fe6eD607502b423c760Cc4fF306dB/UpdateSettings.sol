// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

abstract contract Setter {
    function modifyParameters(bytes32, bytes32, uint) public virtual;
}

contract UpdateSettings {
    Setter public constant GEB_LIQUIDATION_ENGINE =
        Setter(0x6557765796c3b86A721B527006765D056eC038b9);

    uint256 public constant MAX_LIQUIDATION_QUANTITY =
        type(uint256).max / 10 ** 27;

    function run() external {
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "ETH-A",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "ETH-B",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "ETH-C",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "RAI-A",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "WSTETH-A",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "WSTETH-B",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "RETH-A",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "RETH-B",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "CBETH-A",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
        GEB_LIQUIDATION_ENGINE.modifyParameters(
            "CBETH-B",
            "liquidationQuantity",
            MAX_LIQUIDATION_QUANTITY
        );
    }
}