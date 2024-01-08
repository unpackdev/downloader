//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IENSResolver.sol";


interface IENS {
    function resolver(bytes32 node) external view returns (IENSResolver);
}
