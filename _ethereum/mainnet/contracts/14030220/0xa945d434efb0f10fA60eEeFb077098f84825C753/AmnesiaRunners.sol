// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./DerivedRunner.sol";
import "./Creator.sol";
import "./Feeable.sol";

contract AmnesiaRunners is DerivedRunner {
    constructor(
        DerivedRunnerConfig memory derivedRunnerConfig,
        CreatorConfig memory creatorConfig,
        FeeableConfig memory feeableConfig
    ) ERC721("Amnesia Runners", "AMNRUN") {
        initialize(derivedRunnerConfig, creatorConfig, feeableConfig);
    }
}
