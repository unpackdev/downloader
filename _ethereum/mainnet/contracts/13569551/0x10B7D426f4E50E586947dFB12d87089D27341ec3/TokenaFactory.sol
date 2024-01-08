// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Clones.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IStaking.sol";
import "./ITokenaFactory.sol";

/**
 * @title A factory for creating staking and LM
 */
contract TokenaFactory is ITokenaFactory, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	uint256 public lastLMId;
	uint256 public lastStakingId;
	address public masterStaking;

	uint8 private feePercentage;
	uint8 private feeReferal;
	uint8 private counterStaking;
	uint8 private counterLM;
	address private feeTaker;
	uint256 private delta;

	address[] public dexFactory;
	address[] public stakings;
	address[] public liquidityMinings;
	mapping(address => uint256[]) public userStakings;
	mapping(address => uint256[]) public userLMs;
	mapping(address => bool) public promotedStakings;
	mapping(address => bool) public promotedLM;
	mapping(address => bool) public whitelistAddress;

	modifier onlyAdmin {
        address sender = _msgSender();
        require(
            hasRole(DEFAULT_ADMIN_ROLE, sender),
            "Access error"
        );
        _;
    }

	function initialize(
		address _feeTaker,
		uint8 _feePercentage,
		uint8 _feeReferal,
		uint256 _delta,
		address[] calldata _dexFactory
	) external initializer {
		require(_feeTaker != address(0), "Not valid feeTaker address");
		require(_feeReferal <= 100, "Invalid referal fee");
		require(_feePercentage <= 100, "Invalid referal fee");
		for (uint256 i = 0; i < _dexFactory.length; i++) {
			require(_dexFactory[i] != address(0), "Wrong dex address");
		}
		feeTaker = _feeTaker;
		dexFactory = _dexFactory;
		feePercentage = _feePercentage;
		feeReferal = _feeReferal;
		delta = _delta;
		__AccessControl_init();
		__ReentrancyGuard_init();
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/**
	 * @notice create stake/LM for user
	 * @param isLM: true if LM
	 * @param stakedToken: address of staked token
	 * @param rewardToken: address of reward token
	 * @param rewardTokenAmounts: amount of tokens for reward
	 * @param startBlock: start time in blocks
	 * @param endBlock: estimate time of life for pool in blocks
	 */
	function createStaking(
		bool isLM,
		address referalAddress,
		address stakedToken,
		address[] calldata rewardToken,
		uint256[] memory rewardTokenAmounts,
		uint256 startBlock,
		uint256 endBlock,
		IStaking.ProjectInfo calldata info
	) external {
		if (isLM) {
			require(checkValidLpAddress(stakedToken), "Is not valid LP token");
		}
		require(bytes(info.name).length != 0, "Must set name");
		require(info.themeId > 0 && info.themeId < 10, "Wrong theme id");
		require(startBlock >= block.number && endBlock > startBlock, "Is not valid time");
		require(rewardToken.length == rewardTokenAmounts.length, "Unvalid length of reward");
		require(stakedToken != address(0), "staked token 0x0");
		address newStaking = Clones.clone(masterStaking);
		for (uint256 i; i < rewardToken.length; i++) {
			if (!whitelistAddress[rewardToken[i]]) {
				uint256 feeAmount = (rewardTokenAmounts[i] * feePercentage) / 100;
				uint256 referalAmount;

				if (referalAddress != address(0)) {
					referalAmount = (rewardTokenAmounts[i] * feePercentage * feeReferal) / 10000;
					feeAmount = feeAmount - referalAmount;
					IERC20Upgradeable(rewardToken[i]).safeTransferFrom(msg.sender, referalAddress, referalAmount);
				}
				IERC20Upgradeable(rewardToken[i]).safeTransferFrom(msg.sender, feeTaker, feeAmount);
			}

			IERC20Upgradeable(rewardToken[i]).safeTransferFrom(msg.sender, newStaking, rewardTokenAmounts[i]);
			rewardTokenAmounts[i] = IERC20Upgradeable(rewardToken[i]).balanceOf(newStaking);
		}
		IStaking(address(newStaking)).initialize(stakedToken, rewardToken, rewardTokenAmounts, startBlock, endBlock, info, msg.sender);
		if (isLM) {
			liquidityMinings.push(newStaking);
			userLMs[msg.sender].push(lastLMId);
			lastLMId++;
		} else {
			stakings.push(newStaking);
			userStakings[msg.sender].push(lastStakingId);
			lastStakingId++;
		}
	}

	/**
	 * @notice setting master staking contract
	 * @param adr: address of master staking
	 */
	function setMasterStaking(address adr) external onlyAdmin {
		require(adr != address(0), "master staking wrong address");
		masterStaking = adr;
	}

	/**
	 * @notice setting address of fee taker
	 * @param _feeTaker: address of fee taker
	 */
	function setFeeTaker(address _feeTaker) external onlyAdmin {
		require(_feeTaker != address(0), "Cannot set zero address");
		feeTaker = _feeTaker;
	}

	/**
	 * @notice change whitelist token
	 * @param token: address of token
	 * @param flag: true if add to whitelist, false if remove from whitelist
	 */
	function changeWhitelist(address token, bool flag) external onlyAdmin {
		require(token != address(0), "Cannot set zero address");
		require(whitelistAddress[token] != flag, "Already set");
		whitelistAddress[token] = flag;
	}

	/**
	 * @notice set fee percentage
	 * @param _feePercentage: fee percentage in range [0,100)
	 */
	function setFeePercentage(uint8 _feePercentage) external onlyAdmin {
		require(_feePercentage < 100, "Cannot set fee this high");
		feePercentage = _feePercentage;
	}

	/**
	 * @notice Set percentages from referal program
	 * @param _feeReferal: percentages in range [0,100)
	 */
	function setFeeReferal(uint8 _feeReferal) external onlyAdmin {
		require(_feeReferal < 100, "Invalid fee referal");
		feeReferal = _feeReferal;
	}

	/**
	 * @notice Set delta time in which reward may be pending after end
	 * @param _delta: delta time
	 */
	function setDelta(uint256 _delta) external onlyAdmin {
		delta = _delta;
	}

	/**
	 * @notice Change promoted stake
	 * @param pool: address of staking
	 * @param flag: true if set, false if unset
	 */
	function changePromotedStaking(address pool, bool flag) external onlyAdmin {
		require(pool != address(0), "Must be valid address");
		if (flag) {
			require(counterStaking < 5, "Already has 5 promoted");
			require(!promotedStakings[pool], "Already promoted");
			counterStaking++;
			promotedStakings[pool] = flag;
		} else {
			require(counterStaking != 0, "There are no promoted");
			require(promotedStakings[pool], "Already not promoted");
			counterStaking--;
			promotedStakings[pool] = flag;
		}
	}

	/**
	 * @notice Change promoted LM
	 * @param pool: address of LM
	 * @param flag: true if set, false if unset
	 */
	function changePromotedLM(address pool, bool flag) external onlyAdmin {
		require(pool != address(0), "Must be valid address");
		if (flag) {
			require(counterLM < 5, "Already has 5 promoted");
			require(!promotedLM[pool], "Already promoted");
			counterLM++;
			promotedLM[pool] = flag;
		} else {
			require(counterLM != 0, "There are no promoted");
			require(promotedLM[pool], "Already not promoted");
			counterLM--;
			promotedLM[pool] = flag;
		}
	}

	/**
	 * @notice staking pool
	 * @param user: address of user
	 * @return temp: tete
	 */
	function getUserStakings(bool isLM, address user) external view returns (address[] memory) {
		if (isLM) {
			address[] memory temp = new address[](userLMs[user].length);
			for (uint256 i = 0; i < userLMs[user].length; i++) {
				temp[i] = liquidityMinings[userLMs[user][i]];
			}
			return temp;
		} else {
			address[] memory temp = new address[](userStakings[user].length);
			for (uint256 i = 0; i < userStakings[user].length; i++) {
				temp[i] = stakings[userStakings[user][i]];
			}
			return temp;
		}
	}

	/**
	 * @notice Return all pool
	 * @param isLM: true if LM, false if stake
	 */
	function getAllStakings(bool isLM) external view returns (address[] memory) {
		if (isLM) {
			return liquidityMinings;
		} else {
			return stakings;
		}
	}

	/**
	 * @notice get fee taker address
	 * @return address of fee taker
	 */
	function getFeeTaker() external view override returns (address) {
		return feeTaker;
	}

	/**
	 * @notice get fee percentage
	 * @return fee percentage
	 */
	function getFeePercentage() external view override returns (uint256) {
		return feePercentage;
	}

	/**
	 * @notice return how long users can takes they reward after pool end
	 * @return delta
	 */
	function getDelta() external view override returns (uint256) {
		return delta;
	}

	/**
	 * @notice checking that token is LP token in which we can call .factory() and compare for address of know factory
	 * @param token: address of token
	 * @return true if address is valid LP token
	 */
	function checkValidLpAddress(address token) public view returns (bool) {
		require(token != address(0), "lp token address 0x0");
		address token0;
		try IUniswapV2Pair(token).token0() returns (address _token0) {
			token0 = _token0;
		} catch (bytes memory) {
			return false;
		}

		address token1;
		try IUniswapV2Pair(token).token1() returns (address _token1) {
			token1 = _token1;
		} catch (bytes memory) {
			return false;
		}

		for (uint256 i = 0; i < dexFactory.length; i++) {
			address goodPair = IUniswapV2Factory(dexFactory[i]).getPair(token0, token1);
			if (goodPair == token) {
				return true;
			}
		}
		return false;
	}
}
