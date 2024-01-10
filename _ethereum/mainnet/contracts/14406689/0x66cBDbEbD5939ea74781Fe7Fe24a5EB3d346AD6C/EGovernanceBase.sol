// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import "./EGovernanceInterface.sol";
import "./EKotketAccessControl.sol";

contract EGovernanceBase is EKotketAccessControl{
    EGovernanceInterface internal governance;
    constructor (address _governanceAdress) {
        require(_governanceAdress != address(0), "Governance is the zero address");
        governance = EGovernanceInterface(_governanceAdress);
    }
}