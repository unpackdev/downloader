// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CollectionVaultBytecodeLib {
    function getCreationCode(
        address implementation_,
        address collectionAddress_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, collectionAddress_)
            );
    }
}
