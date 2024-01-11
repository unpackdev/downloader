// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Pausable.sol";

contract Staking is Ownable, Pausable {
    ELO elo;
    STRANGERS strangers;

    uint256 public rewardsPerDay = 10 ether;
    mapping(uint256 => uint256) public stakedOn;

    constructor(address _eloAddress, address _strangersAddress) {
        _pause();

        elo = ELO(_eloAddress);
        strangers = STRANGERS(_strangersAddress);
    }

    function startAccumulate(uint256[] memory _tokens) external whenNotPaused {
        for (uint256 i; i < _tokens.length; i++) {
            if (
                stakedOn[_tokens[i]] == 0 &&
                strangers.ownerOf(_tokens[i]) == msg.sender
            ) {
                stakedOn[_tokens[i]] = block.timestamp;
            }
        }
    }

    function getReward(uint256 _token) public view returns (uint256) {
        if (stakedOn[_token] == 0) return 0;
        return ((block.timestamp - stakedOn[_token]) * rewardsPerDay) / 1 days;
    }

    function getRewards(uint256[] memory _tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory rewards = new uint256[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++)
            rewards[i] = getReward(_tokens[i]);
        return rewards;
    }

    function claim(uint256[] memory _tokens) external whenNotPaused {
        uint256 rewards;
        for (uint256 i; i < _tokens.length; i++) {
            if (msg.sender == strangers.ownerOf(_tokens[i])) {
                rewards += getReward(_tokens[i]);
                stakedOn[_tokens[i]] = block.timestamp;
            }
        }
        elo.mint(msg.sender, rewards);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRewards(uint256 _rewards) external onlyOwner {
        rewardsPerDay = _rewards;
    }

    function setElo(address _address) external onlyOwner {
        elo = ELO(_address);
    }

    function setStrangers(address _address) external onlyOwner {
        strangers = STRANGERS(_address);
    }
}

interface ELO {
    function mint(address to, uint256 amount) external;
}

interface STRANGERS {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
