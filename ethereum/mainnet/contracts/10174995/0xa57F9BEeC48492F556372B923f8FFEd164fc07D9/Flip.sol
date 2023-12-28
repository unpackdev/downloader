pragma solidity ^0.5.0;

contract RemoteBase {
    IERC20 internal _remoteToken;
    address internal _remoteContractAddress;
    address internal _contractAddress;
    address internal _devAddress;
    constructor (address remoteContractAddress) internal{
        _remoteContractAddress = remoteContractAddress;
        _remoteToken = IERC20(_remoteContractAddress);
        _contractAddress = address(this);
        _devAddress = msg.sender;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 
interface IERC20 {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
 
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}




contract RemoteRead is RemoteBase {
    function remoteBalanceOf(address owner) external view returns (uint256) {
        return _remoteToken.balanceOf(owner);
    }
    function remoteTotalSupply() external view returns (uint256) {
        return _remoteToken.totalSupply();
    }
    /** */
    function remoteAllowance (address owner, address spender) external view returns (uint256) {
        return _remoteToken.allowance(owner, spender);
    }
    /**
    @dev remoteBalanceOfThis Return tokens from the balance of this contract.
    @return balance
     */
    function remoteBalanceOfThis () external view
        returns(uint256 balance) {
        balance = _remoteToken.balanceOf(_contractAddress);
    }
    /**
    * @dev contractDetails
    * @return address contractAddress
    * @return address remoteContractAddress
     */
    function contractDetails() external view returns (
        address contractAddress,
        address remoteContractAddress) {
        contractAddress = _contractAddress;
        remoteContractAddress = _remoteContractAddress;
    }
}
contract Flip is RemoteRead {
	using SafeMath for uint256;
	uint public payPercentage = 98;
	uint public devPercentage = 2;
	// Maximum amount to bet in WEIs
	uint public maxAmountToBetInTokens = (32) * (10**uint(18));
	uint public minAmountToBetInTokens = (1) * (10**uint(18));
	uint playedGamesCount;
	event Status (
		string _msg,
		address indexed user,
		uint bet,
		uint amount,
		bool winner
	);
	constructor (address remoteContractAddress) public payable
		RemoteBase(remoteContractAddress)
		{

		}
	function PlayWithTokens(uint256 amountOfTokens) public {
		address from = msg.sender;
		uint256 amountAllowed = _remoteToken.allowance(from, _contractAddress);
		require(amountAllowed > 0, "No allowance has been set");
		uint256 amountBalance = _remoteToken.balanceOf(from);
		require(amountBalance >= amountOfTokens, "Your balance must be equal or more than the amount you wish to send");
		require(amountAllowed >= amountOfTokens, "Your allowance must be equal or more than the amount you wish to send");
		require(amountOfTokens >= minAmountToBetInTokens,
		"You have not requested enough Switch");
		require(amountOfTokens <= maxAmountToBetInTokens,
		"You have requested too many Switch");
		_playWithTokens(from, amountOfTokens);
	}
	function () external payable {
		revert();
	}
	function potentialTokenPrize (uint amountWager) external view returns(uint prize) {
		require(amountWager >= minAmountToBetInTokens,
		"You have not requested enough Switch");
		require(amountWager <= maxAmountToBetInTokens,
		"You have requested too many Switch");
		uint _prize = (amountWager.mul(100 + payPercentage)) / 100;
		uint bankTokenBalance = _remoteToken.balanceOf(_contractAddress);
		if (bankTokenBalance < (_prize)) {
			_prize = (bankTokenBalance);
		}
		return _prize;
	}
	function _playWithTokens (address from, uint amountInTokens) internal {
		uint amountWager = amountInTokens;
		// The prize at this stage does not include wager
		uint _prize = (amountWager.mul(payPercentage)) / 100;
		uint bankTokenBalance = _remoteToken.balanceOf(_contractAddress);
		require(bankTokenBalance > 0, "The Switch Flip fund doesn't have any ESH.");
		if (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, playedGamesCount))) % 2 == 0){
			if (bankTokenBalance < (_prize)) {
				require(_remoteToken.transfer(from, bankTokenBalance), "Transfer must succeed.");
				// We do not have enough funds to pay for the prize, so we transfer everything we have
				emit Status ("Congratulations, you flipped your Switch! Sorry, we didn't have enough rewards, we will give you everything we have!",
				from, amountWager, bankTokenBalance, true);
			} else {
				require(_remoteToken.transfer(from, _prize), "Transfer must succeed.");
				emit Status ("Congratulations, you flipped your Switch!",
				from, amountWager, _prize, true);
			}
			playedGamesCount++;
		}
		else {
			uint _devFund = (amountWager.mul(devPercentage)) / 100;
			require(_remoteToken.transferFrom(from, _contractAddress, (amountWager.sub(_devFund))), "Transfer must succeed");
			require(_remoteToken.transfer(_devAddress, _devFund), "Transfer must succeed");
			emit Status ("Sorry, your Switch didn't flip! Switch donated to House and Dev.", from, amountWager, (amountWager.sub(_devFund)), false);
			playedGamesCount++;
		}
	}
	function getGameCount () public view returns (uint) {
		return playedGamesCount;
	}
}