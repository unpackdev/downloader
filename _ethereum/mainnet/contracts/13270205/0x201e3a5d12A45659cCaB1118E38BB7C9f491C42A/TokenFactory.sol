// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";

import "./SocialMoney.sol";
import "./ITokenVesting.sol";

/**
 * @title TokenFactory contract for creating tokens from token proposals
 * @dev For creating tokens from pre-set parameters. This can be understood as a contract factory.
 */
contract TokenFactory is Initializable, OwnableUpgradeable {
	using SafeMath for uint256;

	address public rollWallet;
	ITokenVesting public TokenVestingInstance;

	event LogTokenCreated(
		string name,
		string symbol,
		address indexed token,
		address vestingBeneficiary
	);

	// ===============================
	// Aux functions
	// ===============================
	function calculateProportions(
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint8 _initialPlatformPercentage,
		uint8 _referralPercentage
	) public pure returns (uint256[4] memory proportions) {
		proportions[0] = (_totalSupply).mul(_initialPercentage).div(100); //Initial Supply to Creator
		proportions[1] = 0; //Supply to Platform
		proportions[3] = 0; //Supply to Referral
		proportions[2] = (_totalSupply).sub(proportions[0]); // Remaining Supply to vest on
	}

	function validateProportions(
		uint256[4] memory proportions,
		uint256 _totalSupply
	) private pure {
		require(
			proportions[0].add(proportions[1]).add(proportions[2]).add(
				proportions[3]
			) == _totalSupply,
			"The supply must be same as the proportion, sanity check."
		);
	}

	function validateTokenVestingOwner(address a1, address a2) public view {
		require(
			OwnableUpgradeable(a1).owner() == a2,
			"new TokenVesting not owned by TokenFactory"
		);
	}

	/**
	 * @dev Scale some percentages to a new 100%
	 * @dev Calculates the percentage of each param as part of a total. If all are zero consider the first one as a 100%.
	 */
	function scalePercentages(
		uint256 _totalSupply,
		uint8 p0,
		uint8 p1,
		uint8 p2
	) public pure returns (uint256[3] memory proportions) {
		uint256 _vestingSupply = _totalSupply.sub(
			(_totalSupply).mul(p0).div(100)
		);

		proportions[1] = 0;
		proportions[2] = 0;
		if (p1 > 0) {
			proportions[1] = _totalSupply.mul(p1).div(100);
		}
		if (p2 > 0) {
			proportions[2] = _totalSupply.mul(p2).div(100);
		}
		proportions[0] = _vestingSupply.sub(proportions[1]).sub(proportions[2]);
	}

	/**
	 * @dev Constructor method
	 * @param _tokenVesting address Address of tokenVesting contract. If set to address(0), it will create one instead.
	 * @param _rollWallet address Roll Wallet address for sending out proportion of tokens alloted to it.
	 */
	function initialize(address _tokenVesting, address _rollWallet)
		public
		initializer
	{
		require(
			_rollWallet != address(0),
			"Roll Wallet address must be non zero"
		);
		__Ownable_init();
		rollWallet = _rollWallet;
		TokenVestingInstance = ITokenVesting(_tokenVesting);
	}

	/**
	 * @dev Create token method
	 * @param _name string Name parameter of Token
	 * @param _symbol string Symbol parameter of Token
	 * @param _decimals uint8 Decimals parameter of Token, restricted to < 18
	 * @param _totalSupply uint256 Total Supply paramter of Token
	 * @param _initialPercentage uint8 Initial percentage of total supply that the Vesting Beneficiary will receive from launch, restricted to < 100
	 * @param _vestingPeriodInDays uint256 Number of days that the remaining of total supply will be linearly vested for, restricted to > 1
	 * @param _vestingBeneficiary address Address of the Vesting Beneficiary
	 * @param _initialPlatformPercentage Roll 1.5
	 * @return token address Address of token that has been created by those parameters
	 */
	function createToken(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint256 _vestingPeriodInDays,
		address _vestingBeneficiary,
		uint8 _initialPlatformPercentage,
		address _referral,
		uint8 _referralPercentage
	) public onlyOwner returns (address token) {
		uint256 totalPerc =
			uint256(_initialPercentage)
				.add(uint256(_initialPlatformPercentage))
				.add(uint256(_referralPercentage));

		require(
			_initialPercentage == 100 ||
				(_initialPercentage < 100 && _vestingPeriodInDays > 0),
			"Not valid vesting percentage"
		);

		uint256[4] memory proportions =
			calculateProportions(
				_totalSupply,
				_initialPercentage,
				_initialPlatformPercentage,
				_referralPercentage
			);
		validateProportions(proportions, _totalSupply);
		SocialMoney sm =
			new SocialMoney(
				_name,
				_symbol,
				_decimals,
				proportions,
				_vestingBeneficiary,
				rollWallet,
				address(TokenVestingInstance),
				_referral
			);

		if (_vestingPeriodInDays > 0) {
			TokenVestingInstance.addToken(
				address(sm),
				[_vestingBeneficiary, rollWallet, _referral],
				scalePercentages(
					_totalSupply,
					_initialPercentage,
					_initialPlatformPercentage,
					_referralPercentage
				),
				_vestingPeriodInDays
			);
		}
		token = address(sm);
		emit LogTokenCreated(_name, _symbol, address(sm), _vestingBeneficiary);
	}

	function setPlatformWallet(address _newPlatformWallet) external onlyOwner {
		require(_newPlatformWallet != address(0), "Wallet can't be ZERO");
		rollWallet = _newPlatformWallet;
	}

	function migrateTokenFactory(address _newTokenFactory) external onlyOwner {
		OwnableUpgradeable(address(TokenVestingInstance)).transferOwnership(
			_newTokenFactory
		);
	}

	function setTokenVesting(address _newTokenVesting) external onlyOwner {
		validateTokenVestingOwner(_newTokenVesting, address(this));
		TokenVestingInstance = ITokenVesting(_newTokenVesting);
	}

	function getTokenVesting() external view returns (address) {
		return address(TokenVestingInstance);
	}

	function setVestingAddress(
		address _vestingBeneficiary,
		address _token,
		address _newVestingBeneficiary
	) external onlyOwner {
		TokenVestingInstance.setVestingAddress(
			_vestingBeneficiary,
			_token,
			_newVestingBeneficiary
		);
	}

	function setVestingReferral(
		address _vestingBeneficiary,
		address _token,
		address _vestingReferral
	) external onlyOwner {
		TokenVestingInstance.setVestingReferral(
			_vestingBeneficiary,
			_token,
			_vestingReferral
		);
	}
}
