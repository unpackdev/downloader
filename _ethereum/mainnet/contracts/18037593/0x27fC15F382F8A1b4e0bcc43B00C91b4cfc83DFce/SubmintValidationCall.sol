//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./DataTypes.sol";

contract SubmintValidationCall {
    function validate(bytes calldata validationData) external payable {
        bytes memory registryData = abi.decode(validationData, (bytes));
        (
            bool isWhitelisted,
            uint8 whitelistType,
            bool isReserved,
            uint256 deadline
        ) = abi.decode(registryData, (bool, uint8, bool, uint256));

        if (whitelistType == WHITELIST_CAN_BUY) {
            require(isWhitelisted, "You are not whitelisted.");
        }

        require(!isReserved, "Name is reserved.");

        require(
            deadline == 0 || deadline > block.timestamp,
            "Listing has expired"
        );
    }
}
