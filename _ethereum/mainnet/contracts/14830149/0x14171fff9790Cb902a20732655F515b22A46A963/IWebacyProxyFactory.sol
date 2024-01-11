// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWebacyProxyFactory {
    function createProxyContract(address _memberAddress) external;

    function deployedContractFromMember(address _memberAddress) external view returns (address);

    function setWebacyAddress(address _webacyAddress) external;

    function pauseContract() external;

    function unpauseContract() external;
}
