// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./IEthlasFees.sol";

contract EthlasFees is AccessControlEnumerable, IEthlasFees {
    bytes32 public constant SU_ROLE = keccak256("SU_ROLE");
    uint256 public percentOfTotal;
    uint256 public percentSlip;

    constructor(uint256 _percentOfTotal, uint256 _percentSlip) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        percentOfTotal = _percentOfTotal;
        percentSlip = _percentSlip;
    }

    function getFee(
        uint16,
        uint256,
        uint256 _estimatedFee
    ) external view returns (uint256) {
        return (_estimatedFee * percentOfTotal) / 100;
    }

    function setFee(uint256 _percentOfTotal, uint256 _percentSlip) external {
        require(hasRole(SU_ROLE, msg.sender), "Caller is not SU");
        percentOfTotal = _percentOfTotal;
        percentSlip = _percentSlip;
    }
}
