// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IJTrancheTokens.sol";
import "./IJAave.sol";
import "./IIncentivesController.sol";


contract JTrancheBToken is Ownable, ERC20, AccessControl, IJTrancheTokens {
	using SafeMath for uint256;

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	address public jAaveAddress;
	uint256 public protTrancheNum;

	constructor(string memory name, string memory symbol, uint256 _trNum) ERC20(name, symbol) {
		protTrancheNum = _trNum;
		// Grant the minter role to a specified account
        _setupRole(MINTER_ROLE, msg.sender);
	}

    function setJAaveMinter(address _jAave) external onlyOwner {
		jAaveAddress = _jAave;
		// Grant the minter role to a specified account
        _setupRole(MINTER_ROLE, _jAave);
	}

	/**
	 * @dev Internal function that transfer tokens from one address to another.
	 * Update SIR stakig details.
	 * @param from The address to transfer from.
	 * @param to The address to transfer to.
	 * @param value The amount to be transferred.
	 */
	function _transfer(address from, address to, uint256 value) internal override {
		// moving SIR rewards in protocol
		// claim and transfer rewards before transfer tokens. Be sure to wait for this function to be completed! 
		address incentivesControllerAddress = IJAave(jAaveAddress).getIncentivesControllerAddress();
        bool rewClaimCompleted = IIncentivesController(incentivesControllerAddress).claimRewardsAllMarkets(from);
		// decrease tokens after claiming rewards
        if (rewClaimCompleted && value > 0) {
			uint256 tempTime;
			uint256 tempAmount;
			uint256 tempValue = value;
			uint256 stkDetNum = IJAave(jAaveAddress).getSingleTrancheUserStakeCounterTrB(from, protTrancheNum);
			for (uint256 i = 1; i <= stkDetNum; i++){
				(tempTime, tempAmount) = IJAave(jAaveAddress).getSingleTrancheUserSingleStakeDetailsTrB(from, protTrancheNum, i);
				if (tempAmount > 0) {
					if (tempAmount <= tempValue) {
						IJAave(jAaveAddress).setTrBStakingDetails(protTrancheNum, from, i, 0, tempTime);
						IJAave(jAaveAddress).setTrBStakingDetails(protTrancheNum, to, i, tempAmount, block.timestamp);
						tempValue = tempValue.sub(tempAmount);
					} else {
						uint256 remainingAmount = tempAmount.sub(tempValue);
						IJAave(jAaveAddress).setTrBStakingDetails(protTrancheNum, from, i, remainingAmount, tempTime);
						IJAave(jAaveAddress).setTrBStakingDetails(protTrancheNum, to, i, tempValue, block.timestamp);
						tempValue = 0;
					}
				}
				if (tempValue == 0)
                break;
			}
		}
		super._transfer(from, to, value);
	}

    /**
	 * @dev function that mints tokens to an account
	 * @param account The account that will receive the created tokens.
	 * @param value The amount that will be created.
	 */
	function mint(address account, uint256 value) external override {
		require(hasRole(MINTER_ROLE, msg.sender), "JTrancheB: Caller is not a minter");
		require(value > 0, "JTrancheB: value is zero");
        super._mint(account, value);
    }

    /** 
	 * @dev Internal function that burns an amount of the token of a given account.
	 * @param value The amount that will be burnt.
	 */
	function burn(uint256 value) external override {
		require(hasRole(MINTER_ROLE, msg.sender), "JTrancheB: caller cannot burn tokens");
		require(value > 0, "JTrancheB: value is zero");
		super._burn(msg.sender, value);
	}

}