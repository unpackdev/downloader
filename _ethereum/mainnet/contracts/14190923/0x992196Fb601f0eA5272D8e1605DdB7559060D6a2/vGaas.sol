// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity 0.7.5;

import "./ERC20.sol";
import "./DaoOwnable.sol";

contract vGaas is ERC20, DaoOwnable {
	
	IERC20 public wsMeta;
	mapping(address=>uint256) unstakeRequestTime;
	mapping(address=>uint256) unstakeValue;
	uint256 unstakeCD = 14;
	
	event Stake(address user, uint256 amount);
	event RequestUnstake(address user, uint256 amount, uint256 timestamp);
	event UnStake(address user, uint256 amount, uint256 timestamp);
	
	
    constructor(IERC20 wsMeta_) ERC20("Congruent DAO Vote Token", "vGaas", 18) {
		wsMeta = wsMeta_;
    }
	
	function stake(uint256 amount) external {
		wsMeta.transferFrom(msg.sender, address(this), amount);
		_mint(msg.sender , amount);
		emit Stake(msg.sender , amount);
    }

    function requestUnstake(uint256 amount) external {
		_burn(msg.sender, amount);
        unstakeRequestTime[msg.sender] = block.timestamp;
		unstakeValue[msg.sender] += amount;
		emit RequestUnstake(msg.sender , amount, block.timestamp);
    }
	
	function unstake() external {
		require(unstakeRequestTime[msg.sender] + unstakeCD * 1 days > block.timestamp, "unlocking...");
		unstakeRequestTime[msg.sender] = 0;
        wsMeta.transferFrom(address(this), msg.sender, unstakeValue[msg.sender]);
		emit RequestUnstake(msg.sender , unstakeValue[msg.sender], block.timestamp);
		unstakeValue[msg.sender] = 0;
    }
	
	function setCoolDown(uint256 coolDownDays) external onlyManager{
		require(coolDownDays <= 30, "bruh that's tooooo looooong");
		unstakeCD = coolDownDays;
	}
	
	function transfer(address , uint256 ) public pure override returns (bool) {
        revert("no transfer");
    }
	
	function transferFrom(address , address , uint256 ) public pure override returns (bool) {
        revert("no transfer");
    }
}