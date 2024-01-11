// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

interface IStakingRewards {
    /// @dev List of bond nfts staked by address and token id
    function stakedBonds(address _holder, uint256 _bondId)
        external
        view
        returns (
            uint128 balance,
            uint128 pendingYield,
            uint256 pendingRevDis,
            uint256 yieldPerTokenPaid,
            uint256 revDisPerTokenPaid
        );

    /// @notice Returns ILV staking rewards pool token.
    /// @dev Standard value queried by Staking V2 Pool Factory when
    /// registering a new staking pool.
    function poolToken() external view returns (address);

    /// @notice Tells the Pool Factory that this isn't a
    /// flash pool contract.
    /// @dev Standard value queried by Staking V2 Pool Factory when
    /// registering a new pool.
    function isFlashPool() external pure returns (bool);

    /// @notice Returns latest timestamp to be applied for yield calculations.
    /// @dev If staking v2 has ended, it returns the ending timestamp.
    /// @dev It's required to check if lastTimeYieldApplicable() < lastYieldDistribution
    /// when updating state, so the contract knows if yield rewards have started or not.
    function lastTimeYieldApplicable() external view returns (uint256);

    /// @notice Returns pending yield rewards for a given staked bond.
    function pendingYieldFor(address _who, uint256 _tokenId) external view returns (uint256);

    /// @notice Returns pending revenue distribution for a given staked bond.
    /// @param _who address owning the staked bond
    /// @param _tokenId bond nft identifier
    function pendingRevDisFor(address _who, uint256 _tokenId) external view returns (uint256);

    /// @notice Returns latest yield per token value.
    /// @dev If there isn't any ILV underlying supplied to the contract, or yield
    /// rewards haven't started we just return current stored value.
    /// @dev Yield per token value is calculating by checking how many seconds have passed
    /// since last distribution, checks how much ilv per second the contract is receiving
    /// from staking v2, by using {factory.ilvPerSecond} and {factory.totalWeight} and checking
    /// against this contract's weight and finally dividing by the total amount of ILV tokens
    /// represented.
    function yieldPerToken() external view returns (uint256);

    /// @notice Returns the underlying supplied value.
    /// @dev Value used by Illuvium's Vault contract to calculate revenue
    /// distributions.
    function poolTokenReserve() external view returns (uint256);

    /// @notice Called by staking v2 pool factory, updates the contract rewards
    /// allocation weight.
    /// @param _weight new pool weight to be set
    function setWeight(uint32 _weight) external;

    /// @notice Pauses critical functionality in the contract.
    /// @dev Can be called by the eDAO multisig in case the contract needs to be paused
    /// in an emergency and unpaused later.
    /// @param _shouldPause whether the contract needs to be paused/unpaused
    function setPauseState(bool _shouldPause) external;

    /// @notice Updates Vault contract address stored.
    /// @dev Can only be called by the owner (eDAO multisig)
    /// @param _vault Vault contract address
    function setVaultContract(address _vault) external;

    /// @notice Stakes a bond of given token id for yield and revenue distributions.
    /// @dev Bonds without pending payout (i.e pending locked tokens to be claimed) must not be staked.
    /// This should never happen but we assert just to make sure.
    /// @dev Update reward modifier must be included every time we mutate a Bond.Stake.
    /// @param _tokenId bond nft identifier
    function stake(uint256 _tokenId) external;

    /// @notice Automatically stakes a bond from the bonds registry when purchasing.
    /// @dev Only the bonds registry contract can call this function when the auto stake flag
    /// is set to true when buying locked ILV tokens (and minting a non fungible bond).
    function stake(address _tokenOwner, uint256 _tokenId) external;

    /// @notice Unstakes a bond of given token id and auto claims rewards in ILV or sILV2.
    /// @dev We auto claim pending rewards so we can delete the whole Bond.Stake before
    /// transferring back the ERC721 token.
    /// @param _tokenId staked bond nft identifier
    /// @param _useSILV whether yield should be claimed in ILV or sILV2
    function unstake(uint256 _tokenId, bool _useSILV) external;

    /// @notice Claim pending yield rewards in ILV or sILV.
    /// @param _tokenId staked bond nft identifier
    /// @param _useSILV whether yield should be claimed in ILV or sILV2
    function claimRewards(uint256 _tokenId, bool _useSILV) external;

    /// @notice Asks for underlying tokens from the vault contract and distributes
    /// revenue.
    /// @dev Only the vault contract is able to trigger this function.
    /// @param _reward underlying reward to be distributed as revdis.
    function receiveVaultRewards(uint256 _reward) external;
}
