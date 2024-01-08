// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

interface IndexInterface {
    function list() external view returns (address);
}
interface ListInterface {
    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }

    struct UserList {
        uint64 prev;
        uint64 next;
    }

    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    struct AccountList {
        address prev;
        address next;
    }

    function accounts() external view returns (uint);
    function accountID(address) external view returns (uint64);
    function accountAddr(uint64) external view returns (address);
    function userLink(address) external view returns (UserLink memory);
    function userList(address, uint64) external view returns (UserList memory);
    function accountLink(uint64) external view returns (AccountLink memory);
    function accountList(uint64, address) external view returns (AccountList memory);
}

interface AccountInterface {

    function version() external view returns (uint);

    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    )
    external
    payable 
    returns (bytes32);

    function isAuth(address) external view returns (bool);
}

interface IGnosisSafe {

    function isOwner(address) external view returns (bool);
}