// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

/**
 * @title Helper Contract
 * @dev This contract includes a function to perform a call to a given address.
 */
contract Helper {
    /**
     * @dev Executes a call to a given address.
     * @param _target The address to call to.
     * @param _data The call data to be executed.
     * @return result The result of the call.
     * @return returnData The return data of the call.
     */
    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bool result, bytes memory returnData)
    {
        // Call to the target address with the provided data
        (result, returnData) = _target.call{value: msg.value}(_data);

        // Check if the call was successful
        if (!result) {
            // If the call was not successful, revert the transaction
            revert("Call failed");
        }
    }
}
