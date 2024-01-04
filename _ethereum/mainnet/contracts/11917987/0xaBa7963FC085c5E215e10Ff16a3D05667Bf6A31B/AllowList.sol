pragma solidity >=0.6.0 <0.7.0;

import "./SafeMath.sol";
import "./Context.sol";

import "./IAllowList.sol";


contract AllowList is IAllowList, IAllowListChange, Context {
    using SafeMath for uint256;

    event AccountAdded(address account);
    event AccountRemoved(address account);

    address _admin;

    mapping(address => bool) private _allowList;

    constructor(address admin) public {
        require(admin != address(0), "invalid argument");
        _admin = admin;
    }

    modifier onlyAdmin() {
        require(_msgSender() == _admin, "user is not admin");
        _;
    }

    /**
     * Allows user to receive tokens
     */
    function allowAccount(address account) external override onlyAdmin {
        if (!_isAllowedAccount(account)) {
            _allowList[account] = true;
            emit AccountAdded(account);
        }
    }

    /**
     * Forbids user from receiving tokens
     */
    function disallowAccount(address account) external override onlyAdmin {
        if (_isAllowedAccount(account)) {
            delete _allowList[account];
            emit AccountRemoved(account);
        }
    }

    /**
     * Checks if user is allowed to receive tokens
     */
    function isAllowedAccount(address account) external view override returns (bool) {
        return _isAllowedAccount(account);
    }

    function _isAllowedAccount(address account) private view returns (bool) {
        return _allowList[account];
    }
}
