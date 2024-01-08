// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// import "./Ownable.sol";
// import "./IERC20.sol";
// import "./SafeERC20.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract AnrkeyGameLPStaking is Ownable {
    
    using SafeERC20 for IERC20;
    address[] private poolAddresses;
    bool public isGameStopped;
    
    struct Lpstake {
        address teamAddress;
        uint256 stakeAmount;
        uint256 createStakeTime;
        uint256 gameEndTime;
        bool staked;
    }
    
    address private immutable adminWallet;
    address[] private stakedAddress;
    mapping(address => uint256) private poolTotalStakeAmount;
    mapping(address => Lpstake) private userStakeInfo;
    
    event StakeLPTokens(address indexed poolAddress, address indexed player, uint amount, uint indexed gameTime);
    event UnstakeLPTokens(address indexed poolAddress, address indexed player, uint indexed gameTime);
    event Restake(address indexed player, uint indexed newGameTime);
    event ClaimLPTokens(address indexed player, address indexed poolAddress, uint amount);

    constructor(address admin) {
        require(admin != address(0), "anrkeyGameLPStaking: admin cannot be zero address");
        adminWallet = admin;
    }

    function addPoolAddresses(address[] calldata pools) external onlyOwner returns(bool) {
        poolAddresses = pools;
        return true;
    }

    function changeGameStatus(bool status) external onlyOwner returns(bool) {
        isGameStopped = status;
        return true;
    }

    function doesPoolExist(address poolAddr) internal view returns(bool) {
        uint256 i;
        uint poolAddrLength = poolAddresses.length;
        while (i < poolAddrLength) {
            if(poolAddr == poolAddresses[i]) return true;
            i += 1;
        }
        return false;
    }
    
    //stake lp tokens
    function stakeLpTokens(address _uniswapTokenAddress, uint256 amount, uint256 gameEndTime)external returns(bool) {
        require(doesPoolExist(_uniswapTokenAddress), "Pool address not in accepted pools");
        IERC20 uniswaptoken;
        if(userStakeInfo[msg.sender].staked){
            require(userStakeInfo[msg.sender].teamAddress == _uniswapTokenAddress, "stakeLpTokens: Trying to stake to different pool");
            uniswaptoken = IERC20(_uniswapTokenAddress);
            uniswaptoken.safeTransferFrom(msg.sender, address(this), amount);
            userStakeInfo[msg.sender].stakeAmount = userStakeInfo[msg.sender].stakeAmount + amount;
            poolTotalStakeAmount[_uniswapTokenAddress] = poolTotalStakeAmount[_uniswapTokenAddress] + amount;
            return true;
        }
        stakedAddress.push(msg.sender);
        uniswaptoken = IERC20(_uniswapTokenAddress);
        uniswaptoken.safeTransferFrom(msg.sender, address(this), amount);
        
        Lpstake memory newStake = Lpstake({
            teamAddress: _uniswapTokenAddress,
            stakeAmount: amount,
            createStakeTime: block.timestamp,
            gameEndTime: gameEndTime,
            staked: true
        });
        userStakeInfo[msg.sender] = newStake;
        poolTotalStakeAmount[_uniswapTokenAddress] = poolTotalStakeAmount[_uniswapTokenAddress] + amount;
        emit StakeLPTokens(_uniswapTokenAddress, msg.sender, amount, gameEndTime);
        return true;
    }
    
    //unstaking tokens
    function unstakeLpTokens() external returns(bool) {
        require(userStakeInfo[msg.sender].staked, "Error: No token staked found");
        IERC20 uniswaptoken;
        uint256 gameEndTime = userStakeInfo[msg.sender].gameEndTime;
        address poolAddress = userStakeInfo[msg.sender].teamAddress;
        uniswaptoken = IERC20(poolAddress);
        uint256 amount = userStakeInfo[msg.sender].stakeAmount;
        poolTotalStakeAmount[poolAddress] = poolTotalStakeAmount[poolAddress] - amount;
        if(block.timestamp > gameEndTime){
            uniswaptoken.safeTransfer(msg.sender, amount);
            delete userStakeInfo[msg.sender];
            return true;
        }
        uint256 fees = amount / 100;
        uint256 refundAmount = amount - fees;
        uniswaptoken.safeTransfer(adminWallet, fees);
        uniswaptoken.safeTransfer(msg.sender, refundAmount);
        delete userStakeInfo[msg.sender];
        emit UnstakeLPTokens(poolAddress, msg.sender, gameEndTime);
        return true;
    }
    
    
    function getUserStakeInfo() public view returns(Lpstake memory) {
        return userStakeInfo[msg.sender];
    }
    

    function claimLpTokens() external returns(bool) {
        require(isGameStopped, "Cannot call this function, game is still running");
        IERC20 uniswaptoken;
        uint256 amount = userStakeInfo[msg.sender].stakeAmount;
        address poolAddress = userStakeInfo[msg.sender].teamAddress;
        uniswaptoken = IERC20(poolAddress);
        uniswaptoken.safeTransfer(msg.sender, amount);
        poolTotalStakeAmount[poolAddress] -= amount;
        delete userStakeInfo[msg.sender];
        emit ClaimLPTokens(msg.sender, poolAddress, amount);
        return true;
    }
    
    // fetch total stake in poolAddress
    function fetchTotalPoolStakeAmount(address poolAddress)external view returns(uint256) {
        return poolTotalStakeAmount[poolAddress];
    }
    
    function reStakeAmount(uint256 newGameTime) external returns(uint256) {
        userStakeInfo[msg.sender].gameEndTime = newGameTime;
        emit Restake(msg.sender, newGameTime);
        return newGameTime;
    }
}