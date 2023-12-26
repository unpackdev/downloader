// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/* ========== STRUCTS ========== */

/**
 * @notice global gradual struct
 * @member totalMaturedVotingPower total fully-matured voting power amount
 * @member totalMaturingAmount total maturing amount (amount of power that is accumulating every week for 1/156 of the amount)
 * @member totalRawUnmaturedVotingPower total raw voting power still maturing every tranche (totalRawUnmaturedVotingPower/156 is its voting power)
 * @member lastUpdatedTrancheIndex last (finished) tranche index global gradual has updated
 */
struct GlobalGradual {
	uint48 totalMaturedVotingPower;
	uint48 totalMaturingAmount;
	uint56 totalRawUnmaturedVotingPower;
	uint16 lastUpdatedTrancheIndex;
}

/**
 * @notice user tranche position struct, pointing at user tranche
 * @dev points at `userTranches` mapping
 * @member arrayIndex points at `userTranches`
 * @member position points at UserTranches position from zero to three (zero, one, two, or three)
 */
struct UserTranchePosition {
	uint16 arrayIndex;
	uint8 position;
}

/**
 * @notice user gradual struct, similar to global gradual holds user gragual voting power values
 * @dev points at `userTranches` mapping
 * @member maturedVotingPower users fully-matured voting power amount
 * @member maturingAmount users maturing amount
 * @member rawUnmaturedVotingPower users raw voting power still maturing every tranche
 * @member oldestTranchePosition UserTranchePosition pointing at the oldest unmatured UserTranche
 * @member latestTranchePosition UserTranchePosition pointing at the latest unmatured UserTranche
 * @member lastUpdatedTrancheIndex last (finished) tranche index user gradual has updated
 */
struct UserGradual {
	uint48 maturedVotingPower; // matured voting amount, power accumulated and older than FULL_POWER_TIME, not accumulating anymore
	uint48 maturingAmount; // total maturing amount (also maximum matured)
	uint56 rawUnmaturedVotingPower; // current user raw unmatured voting power (increases every new tranche), actual unmatured voting power can be calculated as unmaturedVotingPower / FULL_POWER_TRANCHES_COUNT
	UserTranchePosition oldestTranchePosition; // if arrayIndex is 0, user has no tranches (even if `latestTranchePosition` is not empty)
	UserTranchePosition latestTranchePosition; // can only increment, in case of tranche removal, next time user gradually mints we point at tranche at next position
	uint16 lastUpdatedTrancheIndex;
}

/**
 * @title Spool DAO Voting Token interface
 */
interface IVoSPOOL {
	/* ========== FUNCTIONS ========== */

	function mint(address, uint256) external;

	function burn(address, uint256) external;

	function mintGradual(address, uint256) external;

	function burnGradual(
		address,
		uint256,
		bool
	) external;

	function updateVotingPower() external;

	function updateUserVotingPower(address user) external;

	function getTotalGradualVotingPower() external returns (uint256);

	function getUserGradualVotingPower(address user) external returns (uint256);

	function getNotUpdatedUserGradual(address user) external view returns (UserGradual memory);

	function getNotUpdatedGlobalGradual() external view returns (GlobalGradual memory);

	function getCurrentTrancheIndex() external view returns (uint16);

	function getLastFinishedTrancheIndex() external view returns (uint16);

	/* ========== EVENTS ========== */

	event Minted(address indexed recipient, uint256 amount);

	event Burned(address indexed source, uint256 amount);

	event GradualMinted(address indexed recipient, uint256 amount);

	event GradualBurned(address indexed source, uint256 amount, bool burnAll);

	event GlobalGradualUpdated(
		uint16 indexed lastUpdatedTrancheIndex,
		uint48 totalMaturedVotingPower,
		uint48 totalMaturingAmount,
		uint56 totalRawUnmaturedVotingPower
	);

	event UserGradualUpdated(
		address indexed user,
		uint16 indexed lastUpdatedTrancheIndex,
		uint48 maturedVotingPower,
		uint48 maturingAmount,
		uint56 rawUnmaturedVotingPower
	);

	event MinterSet(address indexed minter, bool set);

	event GradualMinterSet(address indexed minter, bool set);
}
