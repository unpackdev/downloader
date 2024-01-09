// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";

interface IEtherealWorlds {
	function balanceOf(address _user) external view returns(uint256);
	function ownerOf(uint256 id) external view returns (address user);
}

contract EtherealFragments is ERC20("Ethereal Fragments", "FRAGZ") {
	uint256 constant public BASE_RATE = 2 ether; // Not actually ether
	uint256 constant public DISTRIBUTION_END = 1643533200 + 157784760; // Start time + duration

	mapping(uint256 => uint256) public lastUpdate;

	IEtherealWorlds private  _worldsContract;

	event FragzPaid(address indexed user, uint256 reward);
	event FragzBurnt(address indexed user, uint256 amount, string indexed reason);

	// Link the _worlds contract and mint 2500 tokens to provide liquidity / donations
	constructor(address _worlds) {
		_worldsContract = IEtherealWorlds(_worlds);
		_mint(0x17020cBf555670aB1c7f3e64a80dA61b0B4990c0, 2500 ether);
	}

	function getRewards(uint256 _tokenId, uint256 _time) internal returns(uint256) {
		uint256 _lastUpdate = lastUpdate[_tokenId] == 0 ? DISTRIBUTION_END - 157784760 : lastUpdate[_tokenId];
	
		lastUpdate[_tokenId] = _time;
		return BASE_RATE * (_time - _lastUpdate) / 86400;		
	}

	function claimFragz(uint256[] calldata _tokens) external {
		require(_worldsContract.ownerOf(_tokens[0]) == msg.sender, "Fragz: Not Owner");
		uint256 _time = block.timestamp < DISTRIBUTION_END ? block.timestamp : DISTRIBUTION_END;
		uint256 reward = getRewards(_tokens[0], _time);

        for (uint256 i = 1; i < _tokens.length; i++) {
			require(_worldsContract.ownerOf(_tokens[i]) == msg.sender, "Fragz: Not Owner");
			reward += getRewards(_tokens[i], _time);
        }
			
		_mint(msg.sender, reward);
		emit FragzPaid(msg.sender, reward);
	}

	function burn(uint256 _amount, string memory _reason) external {
		_burn(msg.sender, _amount);
		emit FragzBurnt(msg.sender, _amount, _reason);
	}

	function getTotalClaimable(uint256 _tokenId) external view returns(uint256 _rewards) {
		uint256 _lastUpdate = lastUpdate[_tokenId] == 0 ? DISTRIBUTION_END - 157784760 : lastUpdate[_tokenId];

		uint256 _time = block.timestamp < DISTRIBUTION_END ? block.timestamp : DISTRIBUTION_END;
		_rewards = BASE_RATE * (_time - _lastUpdate) / 86400;
	}
}