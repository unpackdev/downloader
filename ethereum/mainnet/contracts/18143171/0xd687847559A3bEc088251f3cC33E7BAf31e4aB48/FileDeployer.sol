//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title File Deployer
 * @author highlight.xyz
 * @notice Simple singleton to deploy bytecode
 */
contract FileDeployer {
    /**
     * @notice Emitted with deployed content address
     * @param name Content name
     * @param contentAddress Content address
     */
    event DeployedContent(bytes32 indexed name, address indexed contentAddress);

    /**
     * @notice Used to deploy bytes as a contract's bytecode
     * @param contents Contents to be deployed as bytecode
     */
    function deploy(bytes32[] calldata names, string[] memory contents) external {
        uint256 contentsLength = contents.length;
        require(names.length == contentsLength, "Mismatched lengths");
        for (uint256 i = 0; i < contentsLength; i++) {
            address contentAddress = _write(bytes(contents[i]));

            emit DeployedContent(names[i], contentAddress);
        }
    }

    /* solhint-disable max-line-length */
    /**
     * @notice Write bytecode to an address
     * @ author SOLMATE
     */
    function _write(bytes memory data) private returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }
    /* solhint-enable max-line-length */
}
