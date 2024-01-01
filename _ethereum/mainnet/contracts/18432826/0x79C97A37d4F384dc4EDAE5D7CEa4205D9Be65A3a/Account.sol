// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Errors.sol";
import "./IAccount.sol";
import "./IOperator.sol";

/// @title Account
/// @notice Contract which is cloned and deployed for every `trader` interacting with STFX or OZO
contract Account is IAccount {
    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address private immutable OPERATOR;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator) {
        OPERATOR = _operator;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice function to execute trades logic
    /// @dev can only be called by a plugin
    /// @param adapter address of the contract to execute logic
    /// @param data calldata of the function to execute logic
    function execute(address adapter, bytes calldata data, uint256 ethToSend) external payable returns (bytes memory) {
        bool isPlugin = IOperator(OPERATOR).getPlugin(msg.sender);
        if (!isPlugin) revert Errors.NoAccess();
        (bool success, bytes memory returnData) = adapter.call{value: ethToSend}(data);
        if (!success) revert Errors.CallFailed(returnData);
        return returnData;
    }
}
