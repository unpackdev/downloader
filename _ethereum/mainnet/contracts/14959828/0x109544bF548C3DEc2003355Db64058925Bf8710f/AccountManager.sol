// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IAuthCenter.sol";
import "./IAccount.sol";
// import "./console.sol";

contract AccountManager is Ownable {
    // totally account count
    uint256 accountCount;

    // id -> Account
    mapping(string => address) accountBook;

    // Account -> id
    mapping(address => string) idBook;

    // account template
    address public accountTemplate;

    IAuthCenter public authCenter;

    bool flag;

    event CreateAccount(string id, address account);
    event UpdateAccountTemplate(address preTemp, address accountTemplate);
    event SetAuthCenter(address preAuthCenter, address authCenter);

    modifier onlyAccess() {
        authCenter.ensureAccountManagerAccess(_msgSender());
        _;
    }

    function init(address _template, IAuthCenter _authCenter) external {
        require(!flag, "BYDEFI: already initialized!");
        super.initialize();
        accountTemplate = _template;
        authCenter = _authCenter;
        flag = true;
    }

    function updateAccountTemplate(address _newTemplate) external onlyOwner {
        require(_newTemplate != address(0), "BYDEFI: _newTemplate should not be 0");
        address preTemp = accountTemplate;
        accountTemplate = _newTemplate;

        emit UpdateAccountTemplate(preTemp, accountTemplate);
    }

    function setAuthCenter(address _authCenter) external onlyOwner {
        address pre = address(authCenter);
        authCenter = IAuthCenter(_authCenter);
        emit SetAuthCenter(pre, _authCenter);
    }

    function createAccount(string memory id) external onlyAccess returns (address _account) {
        require(bytes(id).length != 0, "BYDEFI: Invalid id!");
        require(accountBook[id] == address(0), "BYDEFI: account exist");

        _account = _cloneAccountProxy(accountTemplate);
        require(_account != address(0), "BYDEFI: cloneAccountProxy failed!");
        IAccount(_account).init(address(authCenter));

        accountBook[id] = _account;
        unchecked {
            accountCount++;
        }
        idBook[_account] = id;

        emit CreateAccount(id, _account);
    }

    function getAccount(string memory id) external view returns (address _account) {
        _account = accountBook[id];
    }

    function isAccount(address _address) external view returns (bool res, string memory id) {
        id = idBook[_address];
        if (bytes(id).length != 0) {
            res = true;
        }
    }

    function getAccountCount() external view returns (uint256) {
        return accountCount;
    }

    function _cloneAccountProxy(address _template) internal returns (address accountAddress) {
        bytes20 targetBytes = bytes20(_template);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            accountAddress := create(0, clone, 0x37)
        }
    }

    function useless() public pure returns (uint256 a, string memory s) {
        a = 100;
        s = "hello world!";
    }
}
