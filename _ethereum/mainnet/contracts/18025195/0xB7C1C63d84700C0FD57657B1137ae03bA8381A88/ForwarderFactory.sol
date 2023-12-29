// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
import "./CloneFactory.sol";
import "./Forwarder.sol";

contract ForwarderFactory is CloneFactory {
    address public implementationAddress;

    event ForwarderCreated(
        address newForwarderAddress,
        address parentAddress,
        bool shouldAutoFlushNative,
        bool shouldAutoFlushERC721,
        bool shouldAutoFlushERC1155
    );

    constructor(address _implementationAddress) {
        implementationAddress = _implementationAddress;
    }


    function createForwarder(
        address parent,
        bytes32 salt,
        bool shouldAutoFlushNative,
        bool shouldAutoFlushERC721,
        bool shouldAutoFlushERC1155
    ) external {
        // Include parent and salt, for the salt to ensure uniqueness since CREATE2 depends on "deployer", "custom salt", and "bytecode"
        bytes32 finalSalt = keccak256(abi.encodePacked(parent, salt));

        address payable clone = createClone(implementationAddress, finalSalt);
        Forwarder(clone).init(
            parent,
            shouldAutoFlushNative,
            shouldAutoFlushERC721,
            shouldAutoFlushERC1155
        );
        emit ForwarderCreated(
            clone,
            parent,
            shouldAutoFlushNative,
            shouldAutoFlushERC721,
            shouldAutoFlushERC1155
        );
    }
}
