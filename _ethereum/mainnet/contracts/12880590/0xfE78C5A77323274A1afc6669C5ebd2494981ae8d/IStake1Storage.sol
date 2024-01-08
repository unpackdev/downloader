//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStake1Storage {
    /// @dev reward token : TOS
    function token() external view returns (address);

    /// @dev registry
    function stakeRegistry() external view returns (address);

    /// @dev paytoken is the token that the user stakes. ( if paytoken is ether, paytoken is address(0) )
    function paytoken() external view returns (address);

    /// @dev A vault that holds TOS rewards.
    function vault() external view returns (address);

    /// @dev the start block for sale.
    function saleStartBlock() external view returns (uint256);

    /// @dev the staking start block, once staking starts, users can no longer apply for staking.
    function startBlock() external view returns (uint256);

    /// @dev the staking end block.
    function endBlock() external view returns (uint256);

    //// @dev the total amount claimed
    function rewardClaimedTotal() external view returns (uint256);

    /// @dev the total staked amount
    function totalStakedAmount() external view returns (uint256);

    /// @dev total stakers
    function totalStakers() external view returns (uint256);

    /// @dev user's staked information
    function getUserStaked(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 claimedBlock,
            uint256 claimedAmount,
            uint256 releasedBlock,
            uint256 releasedAmount,
            uint256 releasedTOSAmount,
            bool released
        );
}
