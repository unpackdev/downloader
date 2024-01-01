// SPDX-License-Identifier: MIT
// For access to Factory from external contracts

pragma solidity 0.8.19;

interface IUsersCollectionFactory {
    function deployProxyFor(
        address _implAddress, 
        address _creator,
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) external returns(address proxy);
} 