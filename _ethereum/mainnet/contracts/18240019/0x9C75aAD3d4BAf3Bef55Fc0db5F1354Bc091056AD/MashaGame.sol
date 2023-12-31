// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ShuffleId.sol";
import "./IERC20.sol";

contract MashaGame is Ownable{

    event GameFinish(address indexed _user, uint256 winAmount, uint256 number, uint256 bidResult);

    struct GameItem {
        address user;
        uint256 amount;
        uint256 targetNumber;
        uint256 realNumber;
        uint256 winAMount;
    }

    IERC20 public token;

    struct PrizeRule {
        uint256 min;
        uint256 max;
        uint256 multiply;
    }

    PrizeRule[11] public rules;

    GameItem[] private games;

    uint256 private totalBids;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor (address _token) {
        token = IERC20(_token);

        rules[0] = PrizeRule(0, 350, 0);
        rules[1] = PrizeRule(351, 480, 105);
        rules[2] = PrizeRule(481, 580, 110);
        rules[3] = PrizeRule(581, 650, 115);
        rules[4] = PrizeRule(651, 730, 120);
        rules[5] = PrizeRule(731, 800, 131);
        rules[6] = PrizeRule(801, 860, 140);
        rules[7] = PrizeRule(861, 910, 165);
        rules[8] = PrizeRule(911, 950, 170);
        rules[9] = PrizeRule(951, 980, 180);
        rules[10] = PrizeRule(981, 999, 200);
    }

    function getTotalGames() external view returns(uint256)
    {
        return games.length - 1;
    }

    function getBid(uint256 _number) external view returns(GameItem memory)
    {
        require(games.length - 1 >= _number, 'Error: out of bounds');
        return games[_number];
    }

    function bid(uint256 _amount, uint256 _number) external {
        require(token.allowance(msg.sender, address(this)) >= _amount, 'Error: low allowance amount');
        require(token.balanceOf(msg.sender) >= _amount, 'Error: low balance');
        require(_number <= 10, 'Error: number to large');

        uint256 gameResult = _getPercent();

        if (gameResult < _number) {
            token.transferFrom(msg.sender, address(this), _amount);
            games.push(GameItem(msg.sender, _amount, _number, gameResult, 0));

            emit GameFinish(msg.sender, 0, _number, gameResult);
            return;
        }

        uint256 winAmount = _amount * rules[_number].multiply / 100;
        uint256 transferAmount = 0;
        games.push(GameItem(msg.sender, _amount, _number, gameResult, winAmount));

        if (winAmount > _amount) {
            transferAmount = winAmount - _amount;
            uint256 feeAmount = transferAmount * 5 / 100;

            token.transfer(deadAddress, feeAmount);
            token.transfer(owner(), feeAmount);

            token.transfer(msg.sender, transferAmount - (2 * feeAmount));
        } else if (_amount > winAmount) {
            transferAmount = _amount - winAmount;
            token.transferFrom(msg.sender, address(this), transferAmount);
        }

        emit GameFinish(msg.sender, winAmount, _number, gameResult);
    }

    function _getPercent() internal returns(uint256)
    {
        totalBids++;
        uint256 random = uint256(ShuffleId.diceRoll(1000, totalBids));

        for (uint256 i = 0; i < rules.length; i ++) {
            if (random >= rules[i].min && random <= rules[i].max) {
                return i;
            }
        }
        return 0;
    }

    function updateRule(uint256 _number, uint256 _min, uint256 _max, uint256 _multiply) external onlyOwner
    {
        require(_number <= 10, 'Error: rule number must be less or equal 10');
        rules[_number].min = _min;
        rules[_number].max = _max;
        rules[_number].multiply = _multiply;
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner
    {
        IERC20 withdrawToken = IERC20(_token);
        withdrawToken.transfer(owner(), _amount);
    }
}
