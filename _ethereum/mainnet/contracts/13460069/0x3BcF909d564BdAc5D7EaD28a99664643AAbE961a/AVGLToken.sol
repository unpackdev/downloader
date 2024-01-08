// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract AVGLToken is ERC20("AVGL", "AVGL"), Ownable {
    using SafeMath for uint256;

    uint256 public constant BASE_RATE = 10 ether;
    uint256 constant public END = 1956441600;
    uint256 constant public OG_START = 1634785200;
    uint256 constant public NO_CLAIM_UNTIL = 1635087600;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    IERC721 public avyc;

    event RewardPaid(address indexed user, uint256 reward);

    function setAVYCAddress(address _avyc) external onlyOwner {
        avyc = IERC721(_avyc);
    }

    constructor(address _avyc) {
        avyc = IERC721(_avyc);
        _mint(msg.sender, 10000 ether);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

    // called when minting many NFTs
    function updateRewardOnMint(address _user) external {
        require(msg.sender == address(avyc), "error");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];
		if (timerUser > 0) {
			rewards[_user] = rewards[_user].add(avyc.balanceOf(_user).mul(BASE_RATE.mul((time.sub(timerUser)))).div(86400));
        }
		lastUpdate[_user] = time;
    }

    // called on transfers
    function updateReward(address _from, address _to) external {
        require(msg.sender == address(avyc));
        uint256 time = min(block.timestamp, END);
        uint256 timerFrom = (lastUpdate[_from] == 0) ? OG_START : lastUpdate[_from];
        if (timerFrom > 0)
            rewards[_from] += avyc.balanceOf(_from).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);
        if (timerFrom != END)
            lastUpdate[_from] = time;
        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];
            if (timerTo > 0)
                rewards[_to] += avyc.balanceOf(_to).mul(BASE_RATE.mul((time.sub(timerTo)))).div(86400);
            if (timerTo != END)
                lastUpdate[_to] = time;
        }
    }

    function getReward(address _to) external {
        require(msg.sender == address(avyc));
        require(block.timestamp >= NO_CLAIM_UNTIL, "claim not start");
        uint256 reward = rewards[_to];
        if (reward > 0) {
            rewards[_to] = 0;
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == address(avyc));
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 realLastUpdate = (lastUpdate[_user] == 0) ? OG_START : lastUpdate[_user];
        uint256 time = min(block.timestamp, END);
		uint256 pending = avyc.balanceOf(_user).mul(BASE_RATE.mul((time.sub(realLastUpdate)))).div(86400);
		return rewards[_user] + pending;
    }
}
