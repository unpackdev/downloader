// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EtherealFragmentsStorage.sol";

contract EtherealFragments is EtherealFragmentsStorage {
	function getRewards(uint256 _tokenId, uint256 _time) internal returns(uint256 _reward) {
		_reward = BASE_RATE * (_time - lastUpdate[_tokenId]) / 86400;
		lastUpdate[_tokenId] = _time;	
	}

	function claimFragz(uint256[] calldata _tokens) external {
		uint256 _time = block.timestamp < DISTRIBUTION_END ? block.timestamp : DISTRIBUTION_END;
		uint256 reward;

        for (uint256 i = 0; i < _tokens.length; i++) {
			if(_tokens[0] > 344) {
				require(specialWorldsContract.ownerOf(_tokens[0]) == msg.sender, "Fragz: Not Owner");
				reward += getRewards(_tokens[i], _time) * 2;
			}
			else {
				require(worldsContract.ownerOf(_tokens[0]) == msg.sender, "Fragz: Not Owner");
				reward += getRewards(_tokens[i], _time);
			}
        }

		_mint(msg.sender, reward);
		emit FragzClaimed(msg.sender, _tokens, reward);
	}

	function burn(uint256 _amount, uint256 _concerning, string memory _extraData) external {
		_burn(msg.sender, _amount);
		emit FragzBurnt(msg.sender, _amount, _concerning, _extraData);
	}

	function getTotalClaimable(uint256 _tokenId) external view returns(uint256 _rewards) {
		uint256 _time = block.timestamp < DISTRIBUTION_END ? block.timestamp : DISTRIBUTION_END;

		_rewards = BASE_RATE * (_time -  lastUpdate[_tokenId]) / 86400;

		if(_tokenId > 344) {
			_rewards = _rewards * 2;
		}
	}
}