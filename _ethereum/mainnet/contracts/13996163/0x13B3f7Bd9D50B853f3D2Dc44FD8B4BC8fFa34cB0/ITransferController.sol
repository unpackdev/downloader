// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

//Interface to control transfer of q2
interface ITransferController {
    function addAddressToWhiteList(address[] memory _users, bool status)
       external 
        returns (bool);

    function isWhiteListed(address _user)  external view returns (bool);
}