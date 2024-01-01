// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/*

Coded for Reflexer and The Money God with 🥕 by

░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░░
░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗░
░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║░
░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║░
░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝░
░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░░

https://defi.sucks

*/

import "./ILiquidationEngine.sol";
import "./ILiquidationEngineOverlay.sol";

import "./ReentrancyGuard.sol";

contract DustyLiquidator is ReentrancyGuard {
    ILiquidationEngine public constant LIQUIDATION_ENGINE =
        ILiquidationEngine(0x4fFbAA89d648079Faafc7852dE49EA1dc92f9976);
    ILiquidationEngineOverlay public constant LIQUIDATION_ENGINE_OVERLAY =
        ILiquidationEngineOverlay(0xa10C1e933C21315DfcaA8C8eDeDD032BD9b0Bccf);

    bytes32 public constant ETH_A =
        0x4554482d41000000000000000000000000000000000000000000000000000000;
    bytes32 public constant DUSTY_LIQUIDATION_ERROR =
        keccak256(abi.encodePacked("LiquidationEngine/dusty-safe"));

    uint256 public constant MAX_LIQUIDATION_PENALTY = 1_150_000_000_000_000_000;
    uint256 public constant MIN_LIQUIDATION_PENALTY = 1_090_000_000_000_000_000;

    event DustySafeLiquidation(address _safe, uint256 _penalty);

    error NotDusty();
    error NotSuccessful();

    function liquidateDustySafe(address _dustySafe) external nonReentrant {
        // Verifies that the SAFE is under the dusty liquidation position
        try LIQUIDATION_ENGINE.liquidateSAFE(ETH_A, _dustySafe) returns (
            uint256
        ) {
            // If the transaction succeeds the transaction is reverted
            revert NotDusty();
        } catch Error(string memory _error) {
            // If the fails with anything other than dusty-safe the transaction is reverted
            if (keccak256(abi.encodePacked(_error)) != DUSTY_LIQUIDATION_ERROR)
                revert NotDusty();

            // Reads current liquidation penalty to restore it later
            (, uint256 _liquidationPenalty, ) = LIQUIDATION_ENGINE
                .collateralTypes(ETH_A);

            // Loads the calldata to liquidate the SAFE
            bytes memory _liquidateCalldata = abi.encodeWithSelector(
                ILiquidationEngine.liquidateSAFE.selector,
                ETH_A,
                _dustySafe
            );

            // Loads the result of the liquidation
            bool _success;

            // If the penalty is already at the minimum value, we don't need to run this block
            if (_liquidationPenalty != MIN_LIQUIDATION_PENALTY) {
                LIQUIDATION_ENGINE_OVERLAY.modifyParameters(
                    ETH_A,
                    "liquidationPenalty",
                    MIN_LIQUIDATION_PENALTY
                );

                (_success, ) = address(LIQUIDATION_ENGINE).call(
                    _liquidateCalldata
                );
                if (_success)
                    emit DustySafeLiquidation(
                        _dustySafe,
                        MIN_LIQUIDATION_PENALTY
                    );
            }

            // If the position was already liquidated, we don't need to run this block
            if (!_success) {
                LIQUIDATION_ENGINE_OVERLAY.modifyParameters(
                    ETH_A,
                    "liquidationPenalty",
                    MAX_LIQUIDATION_PENALTY
                );

                (_success, ) = address(LIQUIDATION_ENGINE).call(
                    _liquidateCalldata
                );
                if (_success)
                    emit DustySafeLiquidation(
                        _dustySafe,
                        MAX_LIQUIDATION_PENALTY
                    );
            }

            if (!_success) revert NotSuccessful();

            // Returns the penalty to the original value
            LIQUIDATION_ENGINE_OVERLAY.modifyParameters(
                ETH_A,
                "liquidationPenalty",
                _liquidationPenalty
            );
        }
    }
}
