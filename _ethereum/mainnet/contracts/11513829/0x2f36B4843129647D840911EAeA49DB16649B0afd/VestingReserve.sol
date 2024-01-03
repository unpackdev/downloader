// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title VestingReserve
 * @dev A vested reserve, freeing 1% per day
 * @author Ethichub
 */
contract VestingReserve is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    bool public initialized;

    // Dates
    uint256 public startTime;
    uint256 public endTime;
    uint256 public editAddressUntil;

    // Amounts
    mapping(address => uint256) public locked;
    mapping(address => uint256) public claimed;

    // Events
    event Fund(address indexed recipient, uint256 amount);
    event Claim(address indexed recipient, uint256 claimed);
    event ToggleDisable(address recipient, bool disabled);
    event ChangeTokenOwnership(address _account, address indexed _newAccount);

    modifier isInitialized() {
        require(initialized, 'VestingReserve: Contract not initialized');
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _editAddressUntil
    ) {
        token = _token;
        require(_endTime > _startTime, 'VestingReserve: end time must be later than start time');
        startTime = _startTime;
        endTime = _endTime;
        require(_editAddressUntil <= _endTime, 'VestingReserve: _editAddressUntil time should be before than end time');
        editAddressUntil = _editAddressUntil;
    }

    function initialize() external virtual {}

    function _vestedOf(address _account) internal view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp > endTime) {
            return locked[_account];
        } else if (locked[_account] == 0) {
            return 0;
        }

        uint256 amountLocked = locked[_account];

        uint256 vested =
            (amountLocked.mul(block.timestamp.sub(startTime)).div(endTime.sub(startTime)));
        if (vested > amountLocked) {
            return amountLocked;
        } else {
            return vested;
        }
    }

    function _lockedOf(address _account) internal view returns (uint256) {
        return locked[_account].sub(_vestedOf(_account));
    }

    function changeTokenOwnership(address _account, address _newAccount)
        public
        isInitialized
        onlyOwner
    {
        require(
            block.timestamp <= editAddressUntil,
            'VestingReserve: Expired date to change token ownership'
        );
        locked[_newAccount] = locked[_account];
        claimed[_newAccount] = claimed[_account];

        locked[_account] = 0;
        claimed[_account] = 0;

        emit ChangeTokenOwnership(_account, _newAccount);
    }

    function _claim(address _account, uint256 _amount) internal {
        uint256 claimable = _vestedOf(_account).sub(claimed[_account]);
        require(claimable > 0, 'VestingReserve: No tokens to transfer');
        require(_amount > 0, 'VestingReserve: Amount cannot be zero');

        if (_amount > claimable) {
            _amount = claimable;
        }

        claimed[_account] = claimed[_account].add(_amount);
        token.safeTransfer(_account, _amount);
        emit Claim(_account, _amount);
    }

    function claim(uint256 _amount) external virtual isInitialized {
        _claim(msg.sender, _amount);
    }

    function claimFor(address _account, uint256 _amount) external isInitialized onlyOwner {
        _claim(_account, _amount);
    }

    function vestedOf(address _account) external view isInitialized returns (uint256) {
        return _vestedOf(_account);
    }

    function lockedOf(address _account) external view isInitialized returns (uint256) {
        return locked[_account].sub(_vestedOf(_account));
    }
}
