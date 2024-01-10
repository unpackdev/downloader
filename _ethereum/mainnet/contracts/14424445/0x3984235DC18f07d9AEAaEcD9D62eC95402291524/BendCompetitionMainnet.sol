// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./BendCompetition.sol";

contract BendCompetitionMainnet is BendCompetition {
    function getConfig() public pure override returns (Config memory config) {
        config.TREASURY_ADDRESS = address(
            0x472FcC65Fab565f75B1e0E861864A86FE5bcEd7B
        );
        config.BEND_TOKEN_ADDRESS = address(
            0x0d02755a5700414B26FF040e1dE35D337DF56218
        );
        config.TEAM_WALLET_ADDRESS = address(
            0x4D62360CEcF722A7888b1f97D4c7e8b170071248
        );
        config.AUTO_DRAW_DIVIDEND_THRESHOLD = 100 * 10**18;
        config.BEND_TOKEN_REWARD_PER_ETH = 333333 * 10**18;
        config.MAX_ETH_PAYMENT_PER_ADDR = 1 * 10**18;
        config.VEBEND_ADDRESS = address(
            0xd7e97172C2419566839Bf80DeeA46D22B1B2E06E
        );
        config.VEBEND_LOCK_MIN_WEEK = 2;

        return config;
    }
}
