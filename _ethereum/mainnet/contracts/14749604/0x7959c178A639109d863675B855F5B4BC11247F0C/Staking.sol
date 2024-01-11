// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721Enumerable.sol";
import "./Authority.sol";
import "./ISToken.sol";
import "./ILogic.sol";

import "./console.sol";


contract Staking is Authority {
	using SafeERC20 for IERC20;

	event LogStake(address indexed recipient, uint256 amount);
	event LogUnstake(address indexed recipient, uint256 amount);

	struct Epoch {
		uint256 number;
		uint256 delta;
		uint32 duration;
		uint32 end;
	}

	struct Adjust {
		bool add;
		uint256 rate;
		uint256 target;
	}

	address public token;
	address public sToken;
	address public logic;
	address public treasury;
	address public nft;

	Epoch public epoch;
	Adjust public adjustment;

	uint256 public rewardsRate; // 1000 = 0.1%

	constructor(
		address _token, 
		address _sToken, 
		uint256 _rewardsRate,
		address _treasury,
		address _nft
	) {
		require(_token != address(0), "Staking: Token cannot be address zero");
		token = _token;

		require(_sToken != address(0), "Staking: SToken cannot be address zero");
		sToken = _sToken;

		require(_rewardsRate >= 0 && _rewardsRate < 1000000, "Staking: RewardsRate must be between 0 and 1000000");
		rewardsRate = _rewardsRate;

		treasury = _treasury;
		nft = _nft;

		uint32 dur = 8 * 3600;
		epoch = Epoch({
			number: 0,
			delta: 0,
			duration: dur,
			end: uint32(block.timestamp)
		});
	}

	function rebase() public {
		if (balanceStaked() <= 0) {
			return;
		}
		if (epoch.end <= block.timestamp) {
			ISToken(sToken).rebase(epoch.number, epoch.delta);
			if (epoch.end + epoch.duration <= block.timestamp) {
				epoch.end = uint32(block.timestamp) + epoch.duration;
			} else {
				epoch.end += epoch.duration;
			}
			epoch.number += 1;

			getRewards();

			uint256 balanceToken_ = balanceToken();
			uint256 balanceStaked_ = balanceStaked();

			if (balanceToken_ > balanceStaked_) {
				epoch.delta = balanceToken_ - balanceStaked_;
			} else {
				epoch.delta = 0;
			}
		}
	}

	function stake(uint256 _amount, address _recipient) external {
		rebase();
		IERC20(sToken).safeTransfer(_recipient, _amount);
		if (msg.sender != logic)
			IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
		else
			IERC20(token).safeTransferFrom(treasury, address(this), _amount);
		emit LogStake(_recipient, _amount);
	}

	function unstake(uint256 _amount) external {
		rebase();
		IERC20(token).safeTransfer(msg.sender, _amount);
		IERC20(sToken).safeTransferFrom(msg.sender, address(this), _amount);
		emit LogUnstake(msg.sender, _amount);
	}

	function getRewards() private {
		if (rewardsRate > 0) {
			uint totalNft = IERC721Enumerable(nft).totalSupply();
			uint dailyRewards = ILogic(logic).dailyRewards();
			IERC20(token).transferFrom(
				treasury,
				address(this),
				totalNft * dailyRewards * rewardsRate / 1000000
			);
			adjust();
		}
	}

	function adjust() private {
		if (adjustment.rate != 0) {
			if (adjustment.add) {
				rewardsRate += adjustment.rate;
				if (rewardsRate >= adjustment.target) {
					adjustment.rate = 0;
				}
			} else {
				rewardsRate -= adjustment.rate;
				if (rewardsRate <= adjustment.target) {
					adjustment.rate = 0;
				}
			}
		}
	}

	function balanceToken() public view returns (uint256) {
		return IERC20(token).balanceOf(address(this));
	}

	function balanceStaked() public view returns (uint256) {
		return ISToken(sToken).circulatingSupply();
	}

	function setLogic(address _logic) external onlyAuthority {
		logic = _logic;
	}

	function setToken(address _token) external onlyAuthority {
		token = _token;
	}

	function setSToken(address _sToken) external onlyAuthority {
		sToken = _sToken;
	}
	
	function setTreasury(address _treasury) external onlyAuthority {
		treasury = _treasury;
	}
	
	function setNft(address _nft) external onlyAuthority {
		nft = _nft;
	}

	function setRewardsRate(uint256 _rate) external onlyAuthority {
		require(_rate >= 0 && _rate < 1000000, "Staking: RewardsRate must be between 0 and 1000000");
		rewardsRate = _rate;
	}

	function setAdjustment(bool _add, uint256 _rate, uint256 _target) external onlyAuthority {
		adjustment = Adjust({
			add: _add,
			rate: _rate,
			target: _target
		});
	}

	function setEpochDuration(uint32 dur) external onlyAuthority {
		epoch.duration = dur;
	}
}
