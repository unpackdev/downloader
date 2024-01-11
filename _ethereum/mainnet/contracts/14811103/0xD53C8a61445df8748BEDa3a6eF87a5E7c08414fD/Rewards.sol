// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC20.sol";
import "./Ownable.sol";
import "./Bank.sol";

/**
 * @title StakingRewards
 * @dev Implementation of StakingRewards
 */
contract Rewards is Ownable {
   
    uint256 public totalBalance;
    uint256 initialTime = 1643157691;
    uint256[] public etherBalance;
    uint256[] public rewardTime;
    uint256[] public totalSupply;
    uint256[] public rewardPerToken;
  
    mapping(address => uint256) public countUser;

    Bank public bank;

    constructor(address _bankAddress) payable {
        require(
            _bankAddress != address(0),
            "Reward Billionaire Club: Bank address is zero"
        );
        bank = Bank(_bankAddress);
    }


    function setInitialTime(uint256 _initialTime) external onlyOwner{
        initialTime = _initialTime;
    }
    
    function earn(address _account) public view returns (uint256) {
        require(
            _account != address(0),
            "Reward Billionaire Club: account is the zero address"
        );
        uint256 _reward = 0;
        uint256 nb_tokens = bank.getNFT(_account).length;
        uint256 nb_count = rewardPerToken.length;
        uint256 staking_time;
        for (uint256 i = countUser[_account]; i < nb_count; i++) {
            for (uint256 j = 0; j < nb_tokens; j++) {
                staking_time = bank.getNFT(_account)[j].staking_time;
                if ((staking_time < rewardTime[i]) && (staking_time > 0)) {
                    _reward = _reward + (rewardPerToken[i] * (block.timestamp - staking_time))
                    /(block.timestamp - initialTime) ;
                }
            }
        }
        return _reward;
    }

    function getReward() external {
        uint256 _reward = earn(msg.sender);
        require (_reward > 0, "reward is zero");
        countUser[msg.sender] = rewardPerToken.length;
        payable(msg.sender).transfer(_reward);
        
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        require(
            _balance > 0,
            "Reward Billionaire Club: contract balance is zero"
        );
        uint256 nb_count = rewardPerToken.length;
        for (uint256 i = 0; i < nb_count; i++) {
            rewardPerToken[i] = 0;
        }
        payable(msg.sender).transfer(_balance);
    }

    receive() external payable {
        etherBalance.push(msg.value);
        rewardTime.push(block.timestamp);
        totalBalance = totalBalance + msg.value;
        uint256 _totalSupply = bank.totalPartyApe();
        totalSupply.push(_totalSupply);
        rewardPerToken.push(msg.value / _totalSupply);
    }
}
