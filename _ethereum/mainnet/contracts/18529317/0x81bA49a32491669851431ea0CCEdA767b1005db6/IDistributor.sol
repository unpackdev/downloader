// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC20.sol";

/**
 * @dev This struct tracks claim progress for a given beneficiary.
 * Because many claims are stored in a merkle root, this struct is only valid once initialized.
 * Users can no longer claim once their claimed quantity meets or exceeds their total quantity.
 * Note that admins may update the merkle root or adjust the total quantity for a specific
 * beneficiary after initialization!
 */
struct DistributionRecord {
  bool initialized; // has the claim record been initialized
  uint120 total; // total token quantity claimable
  uint120 claimed; // token quantity already claimed
}

interface IDistributor {
  event InitializeDistributor(
    IERC20 indexed token, // the ERC20 token being distributed
    uint256 total, // total distribution quantity across all beneficiaries
    string uri, // a URI for additional information about the distribution
    uint256 fractionDenominator // the denominator for vesting fractions represented as integers
  );

  // Fired once when a beneficiary's distribution record is set up
  event InitializeDistributionRecord(address indexed beneficiary, uint256 total);

  // Fired every time a claim for a beneficiary occurs
  event Claim(address indexed beneficiary, uint256 amount);

  /**
   * @dev get the current distribution status for a particular user
   * @param beneficiary the address of the beneficiary
   */
  function getDistributionRecord(
    address beneficiary
  ) external view returns (DistributionRecord memory);

  /**
   * @dev get the amount of tokens currently claimable by a beneficiary
   * @param beneficiary the address of the beneficiary
   */
  function getClaimableAmount(address beneficiary) external view returns (uint256);

  /**
   * @dev get the denominator for vesting fractions represented as integers
   */
  function getFractionDenominator() external view returns (uint256);

  /**
   * @dev get the ERC20 token being distributed
   */
  function token() external view returns (IERC20);

  /**
	* @dev get the total distribution quantity across all beneficiaries
	*/
  function total() external view returns (uint256);

	/**
	* @dev get a URI for additional information about the distribution
	*/
  function uri() external view returns (string memory);

	/**
	* @dev get a human-readable name for the distributor that describes basic functionality
	* On-chain consumers should rely on registered ERC165 interface IDs or similar for more specificity
	*/
  function NAME() external view returns (string memory);

	/**
	* @dev get a human-readable version for the distributor that describes basic functionality
	* The version should update whenever functionality significantly changes
	* On-chain consumers should rely on registered ERC165 interface IDs or similar for more specificity
	*/
  function VERSION() external view returns (uint256);
}
