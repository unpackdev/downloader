// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./EscrowUtilsLib.sol";

abstract contract ContractContext {
    mapping (bytes32 => EscrowUtilsLib.Contract) public contracts;

    event ApprovedContractVersion(
        bytes32 indexed cid,
        bytes32 indexed approvedCid,
        bytes32 indexed key
    );
}