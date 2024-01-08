// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./OwnableUpgradeable.sol";

contract MemberController is OwnableUpgradeable {

    //成员 key:合约名，value合约地址
    mapping(string => address) public members;

    event SetMember(string name, address member);
    event RemoveMember(string name);

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    //获取合约成员地址
    function getMember(string memory name) external view returns(address addr) {
        return members[name];
    }
    //设置合约成员
    function setMember(string memory name, address member) external onlyOwner {
        members[name] = member;
        emit SetMember(name,member);
    }
    //删除合约成员
    function removeMember(string memory name) external onlyOwner {
        delete members[name];
        emit RemoveMember(name);
    }

}
