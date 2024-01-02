// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IFeeExecutorStorage.sol";

interface IFeeExecutor is IFeeExecutorStorage {
    /**
     * @dev Sets tier bonuses for a specific bucket.
     * @param _bucket The address of the bucket.
     * @param _tiers The array of tier values.
     * @param _bonuses The array of NFT bonus parameters.
     */
    function setTierBonus(address _bucket, uint256[] calldata _tiers, NFTBonusParams[] calldata _bonuses) external;

    /**
     * @dev Updates the accumulatedAmount and the lastUpdatedIndex of the existing ActivatedBonus. Called by the Debt-Token
     * @param _user User for which the bonus will be updated. If user doesn't have the bonus for paused
     * @param _oldScaledBalance Balance of the user before the operation at which the updateBonus function was called (e.g mint/burn)
     * @param _bucket The Bucket to which the ActivatedBonus relates
     **/
    function updateBonus(address _user, uint256 _oldScaledBalance, address _bucket, uint256 _currentIndex) external;

    /**
     * @dev Updates the accumulatedAmount and the lastUpdatedIndex of the existing ActivatedBonus. Called directly by the user
     * @param _nftId Id of activated token
     **/
    function updateBonus(uint256 _nftId) external;

    /**
     * @dev Updates the accumulatedAmount and the lastUpdatedIndex of the existing ActivatedBonus. Called by the P-Token or Debt-Token
     * @param _users Array of the users for whom the bonus will be updated.
     * @param _oldBalances Array of the balances before the operation at which the updateBonus function was called (e.g mint/transfer)
     * @param _bucket The Bucket to which the ActivatedBonus relates
     **/
    function updateBonuses(
        address[] memory _users,
        uint256[] memory _oldBalances,
        address _bucket,
        uint256 _currentIndex
    ) external;

    /**
     * @dev Returns accumulated amount of p-tokens at the moment
     * @param _user The user for which the accumatedAmount will return. If the bonus does not exist will return 0.
     * If the NFT does not exist will throw an error
     * @param _nftId Id of activated token
     * @return The accumulated amount.
     */
    function getAccumulatedAmount(address _user, uint256 _nftId) external returns (uint256);

    /**
     * @dev Returns the available amount (accumulated - claimedAmount) of p-tokens at the moment.
     * @param _user The user for which the available amount will return. If the bonus does not exist will return 0.
     * If the NFT does not exist will throw an error
     * @param _nftId Id of activated token
     **/
    function getAvailableAmount(address _user, uint256 _nftId) external returns (uint256);

    /**
     * @dev Retrieves the bonus information for a user and NFT.
     * @param _user The address of the user.
     * @param _nftId The ID of the NFT.
     * @return bonus The activated bonus information.
     */
    function getBonus(address _user, uint256 _nftId) external view returns (ActivatedBonus memory);
}
