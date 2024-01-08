// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC1155.sol";
import "./IBearable.sol";

/// Represents a deployed TwoBitHoney contract
abstract contract TwoBitHoney is IERC1155, IBearable {

    /// Sets the address of the TwoBitCubs contract, which will have rights to burn honey tokens
    function setCubsContractAddress(address cubsContract) external virtual;

    /// Performs the burn of a single honey token on behalf of the TwoBitCubs contract
    /// @dev Throws if the msg.sender is not the configured TwoBitCubs contract
    function burnHoneyForAddress(address burnTokenAddress) external virtual;
}
