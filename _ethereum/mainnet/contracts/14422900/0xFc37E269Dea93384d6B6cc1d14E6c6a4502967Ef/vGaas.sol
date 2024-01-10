// SPDX-License-Identifier: AGPL-3.0-or-later



pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./DaoOwnable.sol";

contract vGaas is ERC20, DaoOwnable {
    using SafeMath for uint256;

    IERC20 public wsMeta;

    mapping(address => uint256) public unstakeTime;
    mapping(address => uint256) public unstakeValue;
    uint256 public unstakeCD = 14;

    event Stake(address indexed user, uint256 amount);
    event RequestUnstake(address indexed user, uint256 amount, uint256 unlockTime);
    event CancelUnstake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);

    constructor(IERC20 wsMeta_) ERC20("Congruent DAO Vote Token", "vGaas", 18) {
        wsMeta = wsMeta_;
    }

    function stake(uint256 amount) external {
        wsMeta.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
		unstakeTime[msg.sender] = type(uint256).max;
        emit Stake(msg.sender, amount);
    }

    function requestUnstake(uint256 amount) external {
        _burn(msg.sender, amount);
        unstakeTime[msg.sender] = block.timestamp + unstakeCD * 1 days;
        unstakeValue[msg.sender] = unstakeValue[msg.sender].add(amount);
        emit RequestUnstake(msg.sender, amount, unstakeTime[msg.sender]);
    }

    function cancelUnstake(uint256 amount) external {
        unstakeValue[msg.sender] = unstakeValue[msg.sender].sub(amount);
        _mint(msg.sender, amount);
        emit CancelUnstake(msg.sender, amount);
    }

    function unstake() external {
        require(unstakeTime[msg.sender] <= block.timestamp, "unlocking...");
        unstakeTime[msg.sender] = type(uint256).max;
        wsMeta.transfer(msg.sender, unstakeValue[msg.sender]);
        emit Unstake(msg.sender, unstakeValue[msg.sender]);
        unstakeValue[msg.sender] = 0;
    }

    function moveWsGaas(uint256 amount) external onlyManager {
        wsMeta.transfer(msg.sender, amount);
    }

    function setCoolDown(uint256 coolDownDays) external onlyManager {
        require(coolDownDays <= 30, "bruh that's tooooo looooong");
        unstakeCD = coolDownDays;
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("no transfer");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("no transfer");
    }
}
