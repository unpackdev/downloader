// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

import "./SafeMath.sol";

interface IBoomers is IERC721 {}

contract YieldToken is ERC20("Meta Boomers Token", "MBM") {
	using SafeMath for uint256;

	uint256 constant public BASE_RATE = 14 ether;
	uint256 constant public INITIAL_ISSUANCE = 1 ether;
	uint256 immutable public END;

	mapping(address => uint256) public _rewards;
	mapping(address => uint256) public _lastUpdate;

	IBoomers public _boomersContract;

    address GAME_REWARDS_ADDRESS = address(0x150556ad0c82183618ED86164FC8a380fe37a225);

	event RewardClaimed(address indexed user, uint256 reward);

	constructor(address _boomers) public {
        END = block.timestamp + 400 days;
		_boomersContract = IBoomers(_boomers);

        _mint(GAME_REWARDS_ADDRESS, 14 * 8888 * 400 * 1e18);
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function updateRewardOnMint(address _user, uint256 _amount) external {
		require(msg.sender == address(_boomersContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = _lastUpdate[_user];

		if (timerUser > 0)
			_rewards[_user] = _rewards[_user].add(_boomersContract.balanceOf(_user).mul(BASE_RATE.mul((time.sub(timerUser)))).div(86400)
				.add(_amount.mul(INITIAL_ISSUANCE)));
		else 
			_rewards[_user] = _rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));

		_lastUpdate[_user] = time;
	}

	// called on transfers
	function updateReward(address _from, address _to, uint256 _tokenId) external {
		require(msg.sender == address(_boomersContract));

		uint256 time = min(block.timestamp, END);
		uint256 timerFrom = _lastUpdate[_from];

		if (timerFrom > 0)
			_rewards[_from] += _boomersContract.balanceOf(_from).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);

		if (timerFrom != END)
			_lastUpdate[_from] = time;

		if (_to != address(0)) {
			uint256 timerTo = _lastUpdate[_to];

			if (timerTo > 0)
				_rewards[_to] += _boomersContract.balanceOf(_to).mul(BASE_RATE.mul((time.sub(timerTo)))).div(86400);

			if (timerTo != END)
				_lastUpdate[_to] = time;
		}
	}

	function getReward(address _to) external {
		require(msg.sender == address(_boomersContract));

		uint256 reward = _rewards[_to];

		if (reward > 0) {
			_rewards[_to] = 0;

			_mint(_to, reward);

			emit RewardClaimed(_to, reward);
		}
	}

	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(_boomersContract));
        
		_burn(_from, _amount);
	}

	function getTotalClaimable(address _user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
		uint256 pending = _boomersContract.balanceOf(_user).mul(BASE_RATE.mul((time.sub(_lastUpdate[_user])))).div(86400);

		return _rewards[_user] + pending;
	}
}

abstract contract YieldingBoomer is ERC721, Ownable {
	address public constant burn = address(0x000000000000000000000000000000000000dEaD);

	YieldToken public yieldToken;

	function setYieldToken(address _yield) external onlyOwner {
		yieldToken = YieldToken(_yield);
	}

	function getReward() external {
		yieldToken.updateReward(msg.sender, address(0), 0);
		yieldToken.getReward(msg.sender);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override {
		yieldToken.updateReward(from, to, tokenId);
		ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		yieldToken.updateReward(from, to, tokenId);
		ERC721.safeTransferFrom(from, to, tokenId, _data);
	}
}