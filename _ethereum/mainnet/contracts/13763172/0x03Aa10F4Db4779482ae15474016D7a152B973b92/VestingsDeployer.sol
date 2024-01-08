// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./VestingWallet.sol";

contract VestingsDeployer {

    /// @notice Vestings deploy
    constructor(
        address[] memory beneficiaryAddresses
    ) {
        for (uint256 i = 0; i < beneficiaryAddresses.length; i++) {
            // solhint-disable-next-line not-rely-on-time
            new VestingWallet(beneficiaryAddresses[i], uint64(block.timestamp), uint64(365 days));
        }
    }
}
