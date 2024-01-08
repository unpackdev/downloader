// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces.sol";

contract Events {
    event LogSubmitAction(
        Position position,
        address sourceDsaSender,
        string actionId,
        uint256 targetDsaId,
        uint256 targetChainId,
        bytes metadata
    );
}
