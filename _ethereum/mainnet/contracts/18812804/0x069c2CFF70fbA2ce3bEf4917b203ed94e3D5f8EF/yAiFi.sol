// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./BasePool.sol";
import "./IAiFiStaking.sol";

contract yAiFi is BasePool, IAiFiStaking, Pausable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    string _name = "AiFi Governance";
    string _symbol = "yAiFi";

    constructor(address _token) BasePool(_name, _symbol, _token) {}

    event Deposited(uint256 amount, address _depositor);
    event Withdrawn(uint256 _amount, address indexed receiver);

    function depositAiFi(
        address _depositor,
        uint256 _amount
    ) external override whenNotPaused {
        require(_amount > 0, "AiFiStaking.depositAiFi: cannot deposit 0");

        token.safeTransferFrom(_depositor, address(this), _amount);

        _update(address(0), _depositor, _amount);
        emit Deposited(_amount, _depositor);
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "AiFiStaking.withdraw: zero amount");
        // burn pool shares
        _update(_msgSender(), address(0), _amount);

        // return tokens
        token.safeTransfer(_msgSender(), _amount);
        emit Withdrawn(_amount, _msgSender());
    }

    function pause() public onlyGovManager {
        super._pause();
    }

    function unpause() public onlyGovManager {
        super._unpause();
    }
}
