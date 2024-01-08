// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract PdexMigrate {
    address private burnTokenAddress =
        0x3737373737373737373737373737373737373737;

    event PdexMigratedEvent(uint256 amount, bytes32 pdexAddress);

    function migrate(
        address _tokenOwnerAddress,
        bytes32 _recipient,
        uint256 _amount
    ) public {
        // Pdex Mainnet address => 0xF59ae934f6fe444afC309586cC60a84a0F89Aaea
        require(
            IERC20(0xF59ae934f6fe444afC309586cC60a84a0F89Aaea).transferFrom(
                _tokenOwnerAddress,
                burnTokenAddress,
                _amount
            ),
            "Contract token allowances insufficient to complete this migration"
        );
        emit PdexMigratedEvent(_amount, _recipient);
    }
}
