// SPDX-License-Identifier: BSD

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract RewardController is AccessControl {
    using SafeERC20 for IERC20;

    event Burnt(uint256 amount);
    event Forwarded(uint256 amount);
    event RewardContractUpdate(address old, address new_);

    bytes32 public constant DELAYED_OPERATOR = keccak256('DELAYED_OPERATOR');
    bytes32 public constant OPERATOR = keccak256('OPERATOR');

    uint256 public totalBurnt;
    address public rewardContract;
    IERC20 public token;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(
        IERC20 _token,
        address _rewardContract,
        address _admin,
        address _operator,
        address _delayedOperator
    ) {
        token = _token;
        rewardContract = _rewardContract;

        if (_admin == address(0)) {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        } else {
            _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        }

        if (_operator != address(0)) {
            _grantRole(OPERATOR, _operator);
        }
        if (_delayedOperator != address(0)) {
            _grantRole(DELAYED_OPERATOR, _delayedOperator);
        }
    }

    function updateRewardContract(address _rewardContract) external onlyRole(DELAYED_OPERATOR) {
        emit RewardContractUpdate(rewardContract, _rewardContract);
        rewardContract = _rewardContract;
    }

    function burn(uint256 amount) external onlyRole(OPERATOR) {
        require(amount > 0, 'Owner: amount > 0');
        token.safeTransfer(burnAddress, amount);
        totalBurnt += amount;
        emit Burnt(amount);
    }

    function release(uint256 amount) external onlyRole(OPERATOR) {
        require(amount > 0, 'Owner: amount > 0');
        require(rewardContract != address(0), 'Owner: rewardContract is 0x0');
        token.safeTransfer(rewardContract, amount);
        emit Forwarded(amount);
    }
}
