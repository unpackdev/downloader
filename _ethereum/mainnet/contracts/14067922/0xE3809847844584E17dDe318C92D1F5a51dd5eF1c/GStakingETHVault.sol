// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./GStakingRoles.sol";

contract GStakingETHVault is Pausable, GStakingRoles {
    using SafeERC20 for IERC20;

    event ClaimReward(address indexed sender, uint256 amount);
    event Refund(address indexed receiver, uint256 amount);

    constructor(
        address[] memory _admins
    ) {
        _setRoleAdmin(GUARDIAN_ROLE, BIG_GUARDIAN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, GUARDIAN_ROLE);
        _setRoleAdmin(CLAIM_ROLE, GUARDIAN_ROLE);

        for (uint256 i = 0; i < _admins.length; ++i) {
            _setupRole(GUARDIAN_ROLE, _admins[i]);
        }

        _setupRole(GUARDIAN_ROLE, msg.sender);
        _setupRole(BIG_GUARDIAN_ROLE, msg.sender);
    }

    function claimReward(
        address _token,
        address _receiver,
        uint _amount
    ) external whenNotPaused onlyRole(CLAIM_ROLE) {
        _paramsValidate(_token, _receiver);

        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Exceeds current balance!");
        IERC20(_token).safeTransfer(_receiver, _amount);

        emit ClaimReward(msg.sender, _amount);
    }

    function recoverFund(
        address _token,
        address _receiver
    ) external whenPaused onlyRole(BIG_GUARDIAN_ROLE) {
        _paramsValidate(_token, _receiver);

        uint balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "Balance is not enough!");
        IERC20(_token).safeTransfer(_receiver, balance);

        emit Refund(_receiver, balance);
    }

    function _paramsValidate(address _token, address _receiver) internal pure {
        require(
            _token != address(0) && _receiver != address(0),
            "Invalid address!"
        );
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }
}
