pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./Ownable.sol";

contract LuckyStaking is Ownable {
    using SafeMath for uint256;

    uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public PERCENTS_DAILY = 50;
    uint256 constant public TIME_STEP = 1 days;
	
	ERC20Interface LuckyToken;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 bonus;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _LuckyToken) public {
        LuckyToken = ERC20Interface(_LuckyToken);
    }

    function invest(uint256 amount) public {
        uint256 received = amount.mul(94).div(100);

		LuckyToken.transferFrom(msg.sender, address(this), amount);
		
        User storage user = users[msg.sender];

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(received, 0, block.timestamp));

        totalInvested = totalInvested.add(received);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, received);

    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(150).div(100)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(PERCENTS_DAILY).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(PERCENTS_DAILY).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(150).div(100)) {
                    dividends = (user.deposits[i].amount.mul(150).div(100)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = LuckyToken.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
		
		LuckyToken.transfer(msg.sender, totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }


    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(150).div(100)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(PERCENTS_DAILY).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(PERCENTS_DAILY).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(150).div(100)) {
                    dividends = (user.deposits[i].amount.mul(150).div(100)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);

            }

        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }


    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserDividends(userAddress);
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(150).div(100)) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function withdrawToken() onlyOwner public returns(bool) {
        uint256 contractBalance = LuckyToken.balanceOf(address(this));
        LuckyToken.transfer(msg.sender, contractBalance);
    }
}