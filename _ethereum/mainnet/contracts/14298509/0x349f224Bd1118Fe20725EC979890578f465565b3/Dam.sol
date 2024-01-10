// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./BuildingBeaverz.sol";

contract Dam is ERC20("DAM", "Dam") {
    using SafeMath for uint256;

    uint256 public constant BASE_RATE = 1 ether;
    uint256 public constant INITIAL_ISSUANCE = 1 ether;
    // Tue Mar 18 2031 17:46:47 GMT+0000
    uint256 public constant END = 1931622407;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    BuildingBeaverz public beaverContract;

    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _contract) {
        beaverContract = BuildingBeaverz(_contract);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // called when minting many NFTs
    function updateRewardOnMint(address _user, uint256 _amount) external {
        require(msg.sender == address(beaverContract), "Can't call this");
        uint256 time = min(block.timestamp, END);
        uint256 timerUser = lastUpdate[_user];
        if (timerUser > 0)
            rewards[_user] = rewards[_user].add(
                beaverContract
                    .balanceGen(_user)
                    .mul(BASE_RATE.mul((time.sub(timerUser))))
                    .div(86400)
                    .add(_amount.mul(INITIAL_ISSUANCE))
            );
        else rewards[_user] = rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));
        lastUpdate[_user] = time;
    }

    // called on transfers
    function updateReward(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(msg.sender == address(beaverContract), "Cant call this");
        if (_tokenId < 10001) {
            uint256 RATE = BASE_RATE;
            if(beaverContract.isAlpha(_tokenId)) {
                RATE = 2;
            }
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];
            if (timerFrom > 0)
                rewards[_from] += beaverContract
                    .balanceGen(_from)
                    .mul(RATE.mul((time.sub(timerFrom))))
                    .div(86400);
            if (timerFrom != END) lastUpdate[_from] = time;
            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];
                if (timerTo > 0)
                    rewards[_to] += beaverContract
                        .balanceGen(_to)
                        .mul(RATE.mul((time.sub(timerTo))))
                        .div(86400);
                if (timerTo != END) lastUpdate[_to] = time;
            }
        }
    }

    function getReward(address _to) external {
        require(msg.sender == address(beaverContract), "Cant call this");
        uint256 reward = rewards[_to];
        if (reward > 0) {
            rewards[_to] = 0;
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == address(beaverContract), "Cant call this");
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns (uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 pending = beaverContract
            .balanceGen(_user)
            .mul(BASE_RATE.mul((time.sub(lastUpdate[_user]))))
            .div(86400);
        return rewards[_user] + pending;
    }
}
