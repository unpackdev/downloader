// SPDX-License-Identifier: MIT
// Adapted from BgD Aave Payload @ https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/master/src/PayloadAaveBGD.sol

pragma solidity 0.8.11;

import "./IInitializableAdminUpgradeabilityProxy.sol";
import "./IAaveEcosystemReserveController.sol";
import "./IERC20.sol";

contract PayloadAaveSigP {
    IInitializableAdminUpgradeabilityProxy public constant COLLECTOR_V2_PROXY =
        IInitializableAdminUpgradeabilityProxy(
            0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        );

    IAaveEcosystemReserveController public constant CONTROLLER_OF_COLLECTOR =
        IAaveEcosystemReserveController(
            0x3d569673dAa0575c936c7c67c4E6AedA69CC630C
        );

    address public constant GOV_SHORT_EXECUTOR =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    IERC20 public constant AUSDC =
        IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);
    IERC20 public constant AUSDT =
        IERC20(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811);

    // As per the offchain governance proposal
    // 50% upfront payment, 50% in 12 months with a streaming payment of 1 second:
    // Start stream time = block.timestamp + 12 months
    // End streat time = block.timestamp + 12 months + 1 second
    // (splits payment equally between aUSDC and aUSDT):


    uint256 public constant FEE = 1296000 * 1e6; // $1,296,000. Minimum engagement fee as per proposal
    uint256 public constant UPFRONT_AMOUNT = FEE / 2;// $648.000 ; // 50% of the fee
    uint256 public constant STREAM_AMOUNT = FEE / 2;// $648.000 ; // 50% of the fee

    uint256 public constant AUSDC_UPFRONT_AMOUNT = UPFRONT_AMOUNT / 2; // 324,000 aUSDC
    uint256 public constant AUSDT_UPFRONT_AMOUNT = UPFRONT_AMOUNT /2 ; // 324,000 aUSDT

    uint256 public constant AUSDC_STREAM_AMOUNT = STREAM_AMOUNT / 2; // 324,000 aUSDC. No extra needed for streaming requirements since duration is exactly 1 second
    uint256 public constant AUSDT_STREAM_AMOUNT = STREAM_AMOUNT / 2; // 324,000 aUSDT. No extra needed for streaming requirements since duration is exactly 1 second

    uint256 public constant STREAMS_DURATION = 1 seconds; // Instant unlock 12 months from now
    uint256 public constant STREAMS_DELAY = 365 days; // 12 months

    address public constant SIGP =
        address(0x014D706F8C893166Da0C6C3343fF9359D1C08FA3);

    function execute() external {

        // Transfer of the upfront payment, 50% of the total engagement fee, split in aUSDC and aUSDT.
        CONTROLLER_OF_COLLECTOR.transfer(
            address(COLLECTOR_V2_PROXY),
            AUSDC,
            SIGP,
            AUSDC_UPFRONT_AMOUNT
        );

        CONTROLLER_OF_COLLECTOR.transfer(
            address(COLLECTOR_V2_PROXY),
            AUSDT,
            SIGP,
            AUSDT_UPFRONT_AMOUNT
        );

        // Creation of the streams

        // aUSDC stream
        // 6 months stream, starting 6 months from now
        CONTROLLER_OF_COLLECTOR.createStream(
            address(COLLECTOR_V2_PROXY),
            SIGP,
            AUSDC_STREAM_AMOUNT,
            AUSDC,
            block.timestamp + STREAMS_DELAY,
            block.timestamp + STREAMS_DELAY + STREAMS_DURATION
        );

        // aUSDT stream
        // 6 months stream, starting 6 months from now
        CONTROLLER_OF_COLLECTOR.createStream(
            address(COLLECTOR_V2_PROXY),
            SIGP,
            AUSDT_STREAM_AMOUNT,
            AUSDT,
            block.timestamp + STREAMS_DELAY,
            block.timestamp + STREAMS_DELAY + STREAMS_DURATION
        );
    }
}
