// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

interface IRegistry {
    function registerNewContract(bytes32 _cid, address _payer, address _payee) external;
    function escrowContracts(address _addr) external returns (bool);
    function insuranceManager() external returns (address);
}