// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

import "./Pool.sol";


library FactoryUtils {

    function generatePoolInitCode(bytes memory encodedParams) external pure returns (bytes memory) {
        // generate the init code
        return abi.encodePacked(
            type(Pool).creationCode, encodedParams
        );
    }
}