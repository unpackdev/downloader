//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IQuadPassport.sol";
import "./IQuadGovernance.sol";

contract QuadReaderStore {

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    IQuadGovernance public governance;
    IQuadPassport public passport;

    struct ApplyFilterVars {
        uint256 gaps;
        uint256 delta;
        uint256 filteredIndex;
    }

}