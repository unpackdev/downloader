// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

interface IInsurance {
    function getCoverage(bytes32 _cid, address _token, uint256 _feeAmount) external view returns (uint256, uint256);
    function useCoverage(bytes32 _cid, address _token, uint256 _amount) external returns (bool);
}