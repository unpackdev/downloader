// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroTreasury {
    function getFee(address _sender, uint32 _eid, uint _totalFee, bool _payInLzToken) external view returns (uint);
}
