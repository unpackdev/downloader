// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface INTokenController {

    /// @dev A struct for an ntoken
    ///     size: 2 x 256bit
    struct NTokenTag {
        address owner;          // the owner with the highest bid
        uint128 nestFee;        // NEST amount staked for opening a NToken
        uint64  startTime;      // the start time of service
        uint8   state;          // =0: normal | =1 disabled
        uint56  _reserved;      // padding space
    }

    function open(address token) external;
    
    function NTokenTagOf(address token) external view returns (NTokenTag memory);

    /// @dev Only for governance
    function loadContracts() external; 

    function loadGovernance() external;

    function setParams(uint256 _openFeeNestAmount) external;

    event ParamsSetup(address gov, uint256 oldParam, uint256 newParam);

    event FlagSet(address gov, uint256 flag);

}
