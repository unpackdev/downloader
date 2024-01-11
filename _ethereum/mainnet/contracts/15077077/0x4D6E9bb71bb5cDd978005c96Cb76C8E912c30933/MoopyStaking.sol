// SPDX-License-Identifier: MIT
/*                
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@......@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%&@@@....@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%#((%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%@@@@@@@((((((((((%@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@(  ((((((((((@@(%%%%%%%%@@           @@(((((((%%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@     ((((((((((((((%%%%@.      @@@       @&(((((%%.@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@    ((((((((((((((%%@..    @&&&&&&@      @(((%%%..@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@    ((((((((((((((@...   @&**&&&%,@.     @((%%....&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@ @*(((((((((((((@...     @@**   &@      @%%......,@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@   ((((((((((((@....      .@*  &&@     @&.........@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@     ((((((((((#@....    @ ,,,,,&@     @*.........#@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@      ((((((((((%@....    @@@@@       @*@..........@@@@@@@@@@@@@@@@
@@@@@@@@@@@@(     (((((((((((((@@..........@@@@@@%............,%%@@@@@@@@@@@@@@@
@@@@@@@@@@@@@((((((((((((((((((@@#(((((((&@@ /@@@............%%%%&@@@@@@@@@@@@@@
@@@@@@@@@@@@@((((((((((((((((((((((((((((@  ****@@..........%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@(((((((((((((((((((((((((((@&   ***@........%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@#(((((((((((((((((((((((((((@  ****@((/...%%%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@(((((((((((((#(((((((((((((@  ****@((((((((%%%%%%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((%%%......(((((((((((@   .**@(((((((((((((%%%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%%%%.............(((((((((@  ***@((((((((((((((((%@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%%....%%............((((((((@@&(((((((((((((@@((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%.....@@...............(((((((((((((((((((((@@((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@......@@...................(((((((((((((((((@(((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%.....@@................         /((((((((((@((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@%%%#...@@...........                        @@((((@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@%%%%%%%@@...                                @((((@@@@@@@@@@@@@@@@                
*/
/****************************************
 * @author: 0xlunes              		*
 * @team:   Moopy	                    *
 ****************************************
 * NFT Staking implementation for Moopy	*
 *										*
 * Reward distribution based on 		*
 * Masterchef implementation			*
 ****************************************/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";

// Additional method available for Mooney
interface IMooney is IERC20 {
	function mint(address to, uint256 amount) external;
}

// Additional methods available for sMoopy
interface ISmoopy is IERC721 {
	function mint(address to, uint256 id) external;
	function burn(address from, uint256 tokenId) external;
}

contract MoopyStaking is Ownable {
	using SafeERC20 for IERC20;

	// Info of each user.
    struct UserInfo {
        uint256 shares; // total Moopies staked     
        uint256 rewardDebt; // amount of Moonies claimed at last update
		mapping(uint256 => bool) stakedIds; // all tokens staked by the user
    }

	// Moopy Contract 
	IERC721 public moopy = IERC721(0xeEE01E9364C2bF5AfF24328FB5bDFb98fF5cEeE3);

	// Mooney Contract
	IMooney public mooney = IMooney(0x2A86C73326771795E7f7e6Fd1ea7fdAB993dEc9D);

	// Smoopy Contract
	ISmoopy public smoopy = ISmoopy(0x46421dA2579E1151212e11FDf61cCd836254b27D);

	// Treasury wallet address
	address public devAddress = 0x1111d7B4976cc9310b15BcB3123395b308451111;

	// Total Mooney emission per Ethereum block 
	uint256 public rewardsPerBlock = 27550000000000000000; // * 10e18
	
    // Block number when staking rewards starts.
    uint256 public startBlock = 1659013200;

	// Update rewards once per block
	uint256 public lastRewardBlock = startBlock;

	// Accumulated rewards per Moopy staked
	uint256 public accRewardsPerShare = 0;

	// Allows holders to stake Moopy
	bool public isStakingActive = false;

	// Details of all stakers
    mapping(address => UserInfo) public userInfo;
	
    event Deposit(address indexed user, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256[] tokenIds);
    event EmergencyWithdraw(address indexed user, uint256[] tokenIds);

	constructor() {}

	function updatePool() public {
		if(block.number < lastRewardBlock) {
			return;
		}

		uint256 totalShares = moopy.balanceOf(address(this));

		if(totalShares == 0) {
			lastRewardBlock = block.number;
			return;
		}

		uint256 duration = block.number - lastRewardBlock;
		uint256 accRewards = rewardsPerBlock * duration;
		
		mooney.mint(devAddress, accRewards * 3 / 20);
		mooney.mint(address(this), accRewards);

		accRewardsPerShare += accRewards / totalShares;
		lastRewardBlock = block.number;
	}

	function deposit(uint256[] calldata _tokenIds) public {
		require(isStakingActive, "staking not active");

		UserInfo storage user = userInfo[msg.sender];

		updatePool();

		if (user.shares > 0) {
			uint256 pending = user.shares * accRewardsPerShare  - user.rewardDebt;
			mooney.transfer(msg.sender, pending);
		}

		uint256 length = _tokenIds.length;
		for(uint256 i = 0; i < length; i++) {
			moopy.transferFrom(msg.sender, address(this), _tokenIds[i]);
			user.stakedIds[_tokenIds[i]] = true;	
			smoopy.mint(msg.sender, _tokenIds[i]);	
		}

		user.shares += length;
		user.rewardDebt = user.shares * accRewardsPerShare;

		emit Deposit(msg.sender, _tokenIds);
	}

	function withdraw(uint256[] calldata _tokenIds) public {
		UserInfo storage user = userInfo[msg.sender];

		updatePool();

		uint256 pending = user.shares * accRewardsPerShare - user.rewardDebt;

		mooney.transfer(msg.sender, pending);

		uint256 length = _tokenIds.length;	
		
		user.shares -= length;
		user.rewardDebt = user.shares * accRewardsPerShare;

		for (uint256 i; i < length; i++){
			require(user.stakedIds[_tokenIds[i]], "token not staked");
			moopy.transferFrom(address(this), msg.sender, _tokenIds[i]);
			user.stakedIds[_tokenIds[i]] = false;

			if (smoopy.ownerOf(_tokenIds[i]) != address(0)) {
				smoopy.burn(smoopy.ownerOf(_tokenIds[i]), _tokenIds[i]);
			}
		}

		emit Withdraw(msg.sender, _tokenIds);
	}

	function claimRewards() public {
		UserInfo storage user = userInfo[msg.sender];

		updatePool();

		uint256 pending = user.shares * accRewardsPerShare - user.rewardDebt;

		mooney.transfer(msg.sender, pending);

		user.rewardDebt = user.shares * accRewardsPerShare;
	}

	function emergencyWithdraw(uint256[] memory _tokenIds) public {
		UserInfo storage user = userInfo[msg.sender];

		uint256 length = _tokenIds.length;

		for (uint256 i; i < length; i++){
			require(user.stakedIds[_tokenIds[i]], "token not staked");
			moopy.transferFrom(address(this), msg.sender, _tokenIds[i]);
			user.stakedIds[_tokenIds[i]] = false;
		}

		user.shares = 0;
		user.rewardDebt = 0;

		emit EmergencyWithdraw(msg.sender, _tokenIds);
	}

	// public view
	function getStakedTokens(address _user) external view returns(uint256[] memory) {
		UserInfo storage user = userInfo[_user];

		require(user.shares > 0, "no staked tokens");
	
		uint256 count;
		uint256 quantity = user.shares;
		uint256 length = 5000;
		uint256[] memory wallet = new uint256[](quantity);
		for (uint256 i; i < length; i++) {
			if (user.stakedIds[i]) {
				wallet[count++] = i;
				if (count == quantity) break;
			}
		}
		return wallet;
	}

	function pendingRewards(address _user) external view returns(uint256) {
        UserInfo storage user = userInfo[_user];

		uint256 totalShares = moopy.balanceOf(address(this));

		uint256 _accRewardsPerShare = accRewardsPerShare;

		if(block.number >= lastRewardBlock && totalShares != 0) {
			uint256 duration = block.number - lastRewardBlock;
			uint256 accRewards = rewardsPerBlock * duration;

			_accRewardsPerShare += accRewards / totalShares;
		}

		return user.shares * _accRewardsPerShare - user.rewardDebt;

	}

	// only owner
	function setStartBlock(uint256 _startBlock) public onlyOwner {
		startBlock = _startBlock;
		lastRewardBlock = startBlock;
	}

	function setRewardsPerBlock(uint256 _rewardsPerBlock) public onlyOwner{
		rewardsPerBlock = _rewardsPerBlock;
	}

	function setStakingActive() public onlyOwner {
		isStakingActive = !isStakingActive;
	}

	function setMoopy(address _newMoopyAddress) public onlyOwner {
		moopy = IERC721(_newMoopyAddress);
	}

	function setSmoopy(address _newSmoopyAddress) public onlyOwner {
		smoopy = ISmoopy(_newSmoopyAddress);
	}
	
	function setMooney(address _newMooneyAddress) public onlyOwner {
		mooney = IMooney(_newMooneyAddress);
	}

	function setDevAddr(address _devAddr) public onlyOwner {
		devAddress = _devAddr;
	}
}