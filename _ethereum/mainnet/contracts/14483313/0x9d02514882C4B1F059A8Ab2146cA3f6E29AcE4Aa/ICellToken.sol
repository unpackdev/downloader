// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";


/// @title  Contract creating fungible in-game utility tokens for the Sheet Fighter game
/// @author Overlord Paper Co
/// @notice This defines in-game utility tokens that are used for the Sheet Fighter game
/// @notice This contract is HIGHLY adapted from the Anonymice $CHEETH contract
/// @notice Thank you MouseDev for writing the original $CHEETH contract!
interface ICellToken is IERC20 {

    /// @notice Update the address of the SheetFighterToken contract
    /// @param _contractAddress Address of the SheetFighterToken contract
    function setSheetFighterTokenAddress(address _contractAddress) external;

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external;

    /// @notice Stake multiple Sheets by providing their Ids
    /// @param tokenIds Array of SheetFighterToken ids to stake
    function stakeByIds(uint256[] calldata tokenIds) external;

    /// @notice Unstake all of your SheetFighterTokens and get your rewards
    /// @notice This function is more gas efficient than calling unstakeByIds(...) for all ids
    /// @dev Tokens are iterated over in REVERSE order, due to the implementation of _remove(...)
    function unstakeAll() external;

    /// @notice Unstake SheetFighterTokens, given by ids, and get your rewards
    /// @notice Use unstakeAll(...) instead if unstaking all tokens for gas efficiency
    /// @param tokenIds Array of SheetFighterToken ids to unstake
    function unstakeByIds(uint256[] memory tokenIds) external;

    /// @notice Claim $CELL tokens as reward for staking a SheetFighterTokens, given by an id
    /// @notice This function does not unstake your Sheets
    /// @param tokenId SheetFighterToken id
    function claimByTokenId(uint256 tokenId) external;

    /// @notice Claim $CELL tokens as reward for all SheetFighterTokens staked
    /// @notice This function does not unstake your Sheets
    function claimAll() external;

    /// @notice Mint tokens when bridging
    /// @dev This function is only used for bridging to mint tokens on one end
    /// @param to Address to send new tokens to
    /// @param value Number of new tokens to mint
    function bridgeMint(address to, uint256 value) external;

    /// @notice Burn tokens when bridging
    /// @dev This function is only used for bridging to burn tokens on one end
    /// @param from Address to burn tokens from
    /// @param value Number of tokens to burn
    function bridgeBurn(address from, uint256 value) external;

    /// @notice View all rewards claimable by a staker
    /// @param staker Address of the staker
    /// @return Number of $CELL claimable by the staker
    function getAllRewards(address staker) external view returns (uint256);

    /// @notice View rewards claimable for a specific SheetFighterToken
    /// @param tokenId Id of the SheetFightToken
    /// @return Number of $CELL claimable by the staker for this Sheet
    function getRewardsByTokenId(uint256 tokenId) external view returns (uint256);

    /// @notice Get all the token Ids staked by a staker
    /// @param staker Address of the staker
    /// @return Array of tokens staked
    function getTokensStaked(address staker) external view returns (uint256[] memory);

    /// @notice Burn cell on behalf of an account
    /// @param account Address for account
    /// @param amount Amount to burn
    function burnFrom(address account, uint256 amount) external;
}