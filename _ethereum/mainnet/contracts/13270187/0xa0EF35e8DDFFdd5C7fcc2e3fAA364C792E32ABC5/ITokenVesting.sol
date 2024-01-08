// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

interface ITokenVesting {
	event Released(
		address indexed token,
		address vestingBeneficiary,
		uint256 amount
	);
	event LogTokenAdded(
		address indexed token,
		address vestingBeneficiary,
		uint256 vestingPeriodInDays
	);

	event LogBeneficiaryUpdated(
		address indexed token,
		address vestingBeneficiary
	);

	struct VestingInfo {
		address vestingBeneficiary;
		uint256 totalBalance;
		uint256 beneficiariesCount;
		uint256 start;
		uint256 stop;
	}

	struct Beneficiary {
		address beneficiary;
		uint256 proportion;
		uint256 streamId;
		uint256 remaining;
	}

	function addToken(
		address _token,
		address[3] calldata _beneficiaries,
		uint256[3] calldata _proportions,
		uint256 _vestingPeriodInDays
	) external;

	function release(address _token, address _beneficiary) external;

	function releaseableAmount(address _token) external view returns (uint256);

	function releaseableAmountByAddress(address _token, address _beneficiary)
		external
		view
		returns (uint256);

	function vestedAmount(address _token) external view returns (uint256);

	function getVestingInfo(address _token)
		external
		view
		returns (VestingInfo memory);

	function setVestingAddress(
		address _vestingBeneficiary,
		address _token,
		address _newVestingBeneficiary
	) external;

	function setVestingReferral(
		address _vestingBeneficiary,
		address _token,
		address _vestingReferral
	) external;

	function getAllTokensByBeneficiary(address _beneficiary)
		external
		view
		returns (address[] memory);

	function releaseAll(address _beneficiary) external;
}
