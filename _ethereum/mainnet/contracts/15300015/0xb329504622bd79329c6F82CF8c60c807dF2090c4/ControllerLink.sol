// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./TimelockCallable.sol";
import "./IAccount.sol";

contract ControllerLink is TimelockCallable, Ownable {
    // Smart Account Count.
    uint256 public accounts;
    mapping(address => uint256) public accountID;
    mapping(uint256 => address) public accountAddr;
    mapping(address => UserLink) public userLink;
    mapping(address => mapping(uint256 => UserList)) public userList;

    address public trustFactory;
    address public timeLock;

    event NewAccount(address owner, address account);
    event DelAccount(address owner, address account);

    struct UserLink {
        uint256 first;
        uint256 last;
        uint256 count;
    }
    struct UserList {
        uint256 prev;
        uint256 next;
    }

    mapping(uint256 => AccountLink) public accountLink;
    mapping(uint256 => mapping(address => AccountList)) public accountList;

    struct AccountLink {
        address first;
        address last;
        uint256 count;
    }
    struct AccountList {
        address prev;
        address next;
    }

    constructor(address _timelock) TimelockCallable(_timelock) {}

    function initialize(address _trustFactory) external onlyTimelock {
        trustFactory = _trustFactory;
    }

    modifier onlyFactory() {
        require(msg.sender == trustFactory, "!trustFactory");
        _;
    }

    function accountVerification(address _owner, address _account)
        internal
        view
        returns (bool)
    {
        return IAccount(_account).owner() == _owner;
    }

    function addAuth(address _owner, address _account) external onlyFactory {
        require(
            accountVerification(_owner, _account),
            "Account addition verification failed!"
        );
        accounts++;
        accountID[_account] = accounts;
        accountAddr[accounts] = _account;
        addAccount(_owner, accounts);
        addUser(_owner, accounts);

        emit NewAccount(_owner, _account);
    }

    function removeAuth(address _owner, address _account) external {
        uint256 removeAccountID = accountID[_account];
        require(removeAccountID != 0, "not-account");
        require(
            accountVerification(_owner, _account) && msg.sender == _account,
            "Account deletion verification failed!"
        );
        removeAccount(_owner, removeAccountID);
        removeUser(_owner, removeAccountID);
        accountID[_account] = 0;

        emit DelAccount(_owner, _account);
    }

    function addAccount(address _owner, uint256 _account) internal {
        if (userLink[_owner].last != 0) {
            userList[_owner][_account].prev = userLink[_owner].last;
            userList[_owner][userLink[_owner].last].next = _account;
        }
        if (userLink[_owner].first == 0) userLink[_owner].first = _account;
        userLink[_owner].last = _account;
        userLink[_owner].count++;
    }

    function addUser(address _owner, uint256 _account) internal {
        if (accountLink[_account].last != address(0)) {
            accountList[_account][_owner].prev = accountLink[_account].last;
            accountList[_account][accountLink[_account].last].next = _owner;
        }
        if (accountLink[_account].first == address(0))
            accountLink[_account].first = _owner;
        accountLink[_account].last = _owner;
        accountLink[_account].count++;
    }

    function removeAccount(address _owner, uint256 _account) internal {
        uint256 _prev = userList[_owner][_account].prev;
        uint256 _next = userList[_owner][_account].next;
        if (_prev != 0) userList[_owner][_prev].next = _next;
        if (_next != 0) userList[_owner][_next].prev = _prev;
        if (_prev == 0) userLink[_owner].first = _next;
        if (_next == 0) userLink[_owner].last = _prev;
        userLink[_owner].count--;
        delete userList[_owner][_account];
    }

    function removeUser(address _owner, uint256 _account) internal {
        address _prev = accountList[_account][_owner].prev;
        address _next = accountList[_account][_owner].next;
        if (_prev != address(0)) accountList[_account][_prev].next = _next;
        if (_next != address(0)) accountList[_account][_next].prev = _prev;
        if (_prev == address(0)) accountLink[_account].first = _next;
        if (_next == address(0)) accountLink[_account].last = _prev;
        accountLink[_account].count--;
        delete accountList[_account][_owner];
    }

    function existing(address _account) external view returns (bool) {
        if (accountID[_account] == 0) {
            return false;
        } else {
            return true;
        }
    }
}
