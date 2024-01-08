// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ISecretBridge.sol";
import "./ISwapRouter.sol";
import "./ISwapFactory.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Round {
    struct RoundInfo {
        uint256 startTime;
        uint256 depositDuration;
        uint256 stakeDuration;
        uint256 totalDeposit;
        uint256 totalWithdrawn;
        uint256 totalReward;
        bool withdrawnToSecretNetwork;
        bool withdrawnByAdmin;
        bool depositedBack;
    }
}

contract Manager is Ownable, Pausable, Round {
    uint256 public totalRounds;
    mapping(uint256 => RoundInfo) public rounds;

    event RoundStarted(
        uint256 indexed roundId,
        uint256 indexed startTime,
        uint256 indexed duration
    );

    function adminAddRound(uint256 _startTime, uint256 _depositDuration, uint256 _stakeDuration)
        external
        whenNotPaused()
        onlyOwner()
    {
        RoundInfo memory newRound;
        newRound.startTime = _startTime;
        newRound.depositDuration = _depositDuration;
        newRound.stakeDuration = _stakeDuration;
        newRound.depositedBack = false;
        newRound.withdrawnToSecretNetwork = false;
        newRound.withdrawnByAdmin = false;
        rounds[totalRounds] = newRound;
        totalRounds = totalRounds + 1;
    }

    function adminUpdateRound(uint256 _roundId, uint256 _startTime, uint256 _depositDuration, uint256 _stakeDuration)
        external
        whenNotPaused()
        onlyOwner()
    {
        RoundInfo memory round = rounds[_roundId];
        require(0 < round.startTime &&  round.startTime < block.timestamp, "Can-not-update");
        round.startTime = _startTime;
        round.depositDuration = _depositDuration;
        round.stakeDuration = _stakeDuration;
        rounds[_roundId] = round;
    }

    function stop() external onlyOwner() {
        require(!paused(), "Already-paused");
        _pause();
    }

    function start() external onlyOwner() {
        require(paused(), "Already-start");
        _unpause();
    }

}


contract CataLystBridgeERC20 is Manager, ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for IERC20;

    mapping (address => mapping(uint256 => uint256)) public userFund;
    mapping (address => mapping(uint256 => uint256)) public userWithdrawnFund;
    mapping (address => mapping(uint256 => uint256)) public userReward;
    address public depositToken;
    address public rewardToken;
    uint256 public minDepositAmount;
    string public name;
    
    address public constant uniRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 public constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
	address public constant uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
	address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event UserDeposit(address indexed user, uint indexed roundId, uint indexed amount);
    event UserWithdrawn(address indexed user, uint indexed roundId, uint indexed amount);
   
    modifier isValidRound(uint256 _roundId) {
        require(rounds[_roundId].startTime > 0, "Invalid-round");
        _;
    }

    receive() external payable {
        
    }
    
    constructor(string memory _name,address _depositToken,address _rewardToken, uint256 _minDepositAmount) {
        depositToken = _depositToken;
        rewardToken = _rewardToken;
        minDepositAmount = _minDepositAmount;
        name = _name;
    }

    function userDeposit(uint256 _roundId, uint256 _amount) isValidRound(_roundId) external payable whenNotPaused() nonReentrant() { 
        RoundInfo memory round = rounds[_roundId];
        require(round.startTime <= block.timestamp && block.timestamp <= (round.startTime + round.depositDuration),"Can-not-deposit");
        uint fund;
        if(depositToken == address(0)) {// round accept ETH
            require(msg.value >= minDepositAmount, "Invalid-fund");
            fund = msg.value;
        } else {
            require(_amount >= minDepositAmount, "Invalid-fund");
            IERC20(depositToken).safeTransferFrom(msg.sender, address(this), _amount);
            fund  = _amount;
        } 
    
        userFund[msg.sender][_roundId] = userFund[msg.sender][_roundId] + fund;
        round.totalDeposit = round.totalDeposit + fund;
        rounds[_roundId] = round;
        emit UserDeposit(msg.sender, _roundId, fund);
    }
    
    function userWithDrawn(uint256 _roundId) isValidRound(_roundId) external whenNotPaused()  nonReentrant() {
        RoundInfo memory round = rounds[_roundId];
        uint256 fundOfUser = userFund[msg.sender][_roundId];
        require(fundOfUser > 0, "Invalid fund");
        require((block.timestamp <= round.startTime + round.depositDuration &&  round.totalWithdrawn == 0) ||
                (block.timestamp >= (round.startTime + round.depositDuration + round.stakeDuration) && round.totalWithdrawn > 0), "Can-not-withdrawn-now");
        uint256 amountToWithdrawn;
        uint rewardToUser;
        if (round.totalWithdrawn == 0) {
            amountToWithdrawn = fundOfUser;
            round.totalDeposit = round.totalDeposit - amountToWithdrawn;
            rounds[_roundId] = round;
        } else {
            amountToWithdrawn = fundOfUser * round.totalWithdrawn / round.totalDeposit;
            rewardToUser = fundOfUser * round.totalReward / round.totalDeposit;
            userWithdrawnFund[msg.sender][_roundId] = amountToWithdrawn;
            userReward[msg.sender][_roundId] = rewardToUser;
        }
        if(depositToken == address(0)) {
            payable(msg.sender).sendValue(amountToWithdrawn);
        } else { 
            IERC20(depositToken).safeTransfer(msg.sender, amountToWithdrawn); // transfer token to user
        }
        IERC20(rewardToken).safeTransfer(msg.sender, rewardToUser); // transfer reward to user
        emit UserWithdrawn(msg.sender, _roundId, amountToWithdrawn);
        delete userFund[msg.sender][_roundId];
    }
    
    function userReinvest(uint256 _oldRoundId,uint256 _newRoundId) isValidRound(_oldRoundId) external whenNotPaused()  nonReentrant() {
        RoundInfo memory oldRound = rounds[_oldRoundId];
        RoundInfo memory newRound = rounds[_newRoundId];
        uint256 fundOfUser = userFund[msg.sender][_oldRoundId];
        require(fundOfUser > 0, "Invalid fund");
        require(oldRound.totalWithdrawn > 0, "old-round-not-allow-to-withdraw-yet");
        require(newRound.startTime <= block.timestamp && block.timestamp <= (newRound.startTime + newRound.depositDuration),"new-round-closed-for-deposit");

        uint256 amountToReinvest = fundOfUser * oldRound.totalWithdrawn / oldRound.totalDeposit;
        uint rewardToUser = fundOfUser * oldRound.totalReward / oldRound.totalDeposit;
        userWithdrawnFund[msg.sender][_oldRoundId] = amountToReinvest;
        userReward[msg.sender][_oldRoundId] = rewardToUser;
        
        // transfer reward to user
        IERC20(rewardToken).safeTransfer(msg.sender, rewardToUser);
       
  
        userFund[msg.sender][_newRoundId] = userFund[msg.sender][_newRoundId] + amountToReinvest;
        newRound.totalDeposit = newRound.totalDeposit + amountToReinvest;
        rounds[_newRoundId] = newRound;
        
    
        delete userFund[msg.sender][_oldRoundId];
    }
    

    function adminCollectFund(uint256 _roundId) isValidRound(_roundId) external onlyOwner() whenNotPaused() {
        require((rounds[_roundId].startTime + rounds[_roundId].depositDuration) < block.timestamp, "Deposit-time-not-end-yet");
        require(rounds[_roundId].withdrawnToSecretNetwork == false, "already withdrawn to secret network");
        RoundInfo memory round = rounds[_roundId];
        uint256 collectValue = round.totalDeposit;
        round.withdrawnByAdmin = true;
        rounds[_roundId] = round;
        if(depositToken == address(0)) {
            payable(msg.sender).sendValue(collectValue);
        } else { 
            IERC20(depositToken).safeTransfer(msg.sender, collectValue); // transfer token to owner
        }
    }

    function adminDepositFund(uint256 _roundId, uint256 _amount, uint256 _rewardAmount) isValidRound(_roundId) external payable onlyOwner() whenNotPaused() {
        RoundInfo memory round = rounds[_roundId];
        require((round.startTime + round.depositDuration + round.stakeDuration) < block.timestamp, "Round-not-end-yet");
        uint256 depositValue;
        if(depositToken == address(0)) {
            depositValue = msg.value;
        } else { 
            IERC20(depositToken).safeTransferFrom(msg.sender, address(this), _amount);
            depositValue = _amount;
        }
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _rewardAmount);
        round.totalWithdrawn = depositValue;
        round.totalReward = _rewardAmount;
        round.depositedBack = true;
        rounds[_roundId] = round;
    }
    
    function getPath(address _tokenIn, address _tokenOut) private view returns (address[] memory path) {
		address pair = ISwapFactory(uniswapV2Factory).getPair(_tokenIn, _tokenOut);
		if (pair == address(0)) {
			path = new address[](3);
			path[0] = _tokenIn;
			path[1] = WETH;
			path[2] = _tokenOut;
		} else {
			path = new address[](2);
			path[0] = _tokenIn;
			path[1] = _tokenOut;
		}
	}
    
    
    function _uniswapETHForToken(
		address _tokenOut,
		uint256 expectedAmount,
		uint256 _deadline,
		uint256 _amount
	 ) internal {
		ISwapRouter(uniRouterV2).swapExactETHForTokens{ value: _amount }(expectedAmount, getPath(WETH, _tokenOut), address(this), _deadline); 
	}
    
    
    function adminDepositFundAndSwapRewards(uint256 _roundId, uint256 _rewardAmount) isValidRound(_roundId) external payable onlyOwner() whenNotPaused() {
        RoundInfo memory round = rounds[_roundId];
        require((round.startTime + round.depositDuration + round.stakeDuration) < block.timestamp, "round-not-end-yet");
        require(depositToken == address(0), "deposit-token-not-native");
        require(msg.value > _rewardAmount, "reward-amount-invalid");

     
        uint256 rewardBalanceBefore = IERC20(rewardToken).balanceOf(address(this));
        _uniswapETHForToken(rewardToken, 0, deadline, _rewardAmount);
        uint256 rewardAmountAfter = IERC20(rewardToken).balanceOf(address(this)) - rewardBalanceBefore;   
        round.totalWithdrawn = msg.value - _rewardAmount;
        round.totalReward = rewardAmountAfter;
  
        round.depositedBack = true;
        rounds[_roundId] = round;
    }
    

    function emergencyWithdawn(address _token) external onlyOwner() whenPaused() {
        if(_token == address(0)) {
            payable(msg.sender).sendValue((address(this).balance));
        } else { 
            uint balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, balance);
        }
    }
 
    function adminWithdrawToSecretBridge(
        address _secretBridge, 
        uint256 _roundId, 
        bytes memory _recipient)  
        isValidRound(_roundId)
        external onlyOwner() whenNotPaused() {
            require((rounds[_roundId].startTime + rounds[_roundId].depositDuration) < block.timestamp, "Deposit-time-not-end-yet");
            require(rounds[_roundId].withdrawnByAdmin == false, "already withdrawn");
            RoundInfo memory round = rounds[_roundId];
            uint256 collectValue = round.totalDeposit;
       
            if(depositToken == address(0)) {
                ISecretBridge(_secretBridge).swap{value: collectValue}(_recipient);
            }
            else {
                if(IERC20(depositToken).allowance(address(this),_secretBridge) == 0)
                {
                    IERC20(depositToken).safeApprove(_secretBridge, type(uint256).max);
                }
                
                ISecretBridge(_secretBridge).swapToken(_recipient, collectValue, depositToken);
            }
            round.withdrawnToSecretNetwork = true;
            rounds[_roundId] = round;
    }
}
