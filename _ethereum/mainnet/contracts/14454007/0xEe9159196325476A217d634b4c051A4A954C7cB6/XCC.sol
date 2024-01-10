// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

pragma solidity ^0.8.0;
import "./IRegistry.sol";

library XCC {
    function findIntegration(
        IRegistry.Integration[] memory s,
        address integration
    )
        public
        pure
        returns (
            bool exist,
            uint8 index,
            IRegistry.Integration memory ypltfm
        )
    {
        uint256 len = s.length;
        require(len < type(uint8).max, "XCC1");
        require(integration != address(0), "XCC2");
        if (len > 0) {
            for (uint8 i; i < len; i++) {
                // load to memory
                IRegistry.Integration memory temp = s[i];
                if (temp.integration == integration) {
                    exist = true;
                    index = i;
                    ypltfm = temp;
                }
            }
        }
    }
}
