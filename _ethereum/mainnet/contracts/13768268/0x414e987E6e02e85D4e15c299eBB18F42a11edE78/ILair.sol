// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface ILair {
    /// @notice returns the totalPredatorScoreStaked property
    function getTotalPredatorScoreStaked() external view returns (uint24);

    /// @notice returns the totalPredatorScoreStaked property
    function getBloodbagPerPredatorScore() external view returns (uint256);

    function ownerOf(uint16 tokenId, uint8 predatorIndex) external view returns (address);

    /// @notice Stake one vampire
    ///
    /// What this does:
    ///
    /// - Update the state of the vault to contain the Vampire that the user wants to stake
    ///
    /// What the controller should do after this function returns:
    ///
    /// - Before calling this: Controller should check if the address implements onReceiveERC721.
    /// - Then call transferFrom(_msgSender(), LAIR_ADDRESS, tokenId)
    ///
    /// Note: This is only called by controller, and the sender should be `_msgSender()`
    ///
    /// @param sender address of who's making this request, should be the vampire owner
    /// @param tokenId ids of each vampire to stake
    function stakeVampire(address sender, uint16 tokenId) external;

    /// @notice update the vault state to as the owed amont fo the vampire was removed
    ///
    /// What this does:
    ///
    /// - Calculate and return the current amount owed to a vampire
    /// - Reset the vampire stake info to as if they were staked now
    ///
    /// What the controller should do after this function returns:
    ///
    /// - Transfer the `owed` amount of $BLOODBAGs to `sender`.
    ///
    /// Note: This is only called by controller, and the sender should be `_msgSender()`
    /// Note: We set all state first, and the do the transfers to avoid reentrancy
    ///
    /// @param sender address of who's making this request, should be the vampire owner
    /// @param tokenId id of the vampire
    /// @return owed amount of $BLOODBAGs owed to the vampire
    function claimBloodBags(address sender, uint16 tokenId)
        external
        returns (uint256 owed);

    /// @notice update the vault state to as the owed amont fo the vampire was removed
    /// and the vampire was unstaked.
    ///
    /// What this does:
    ///
    /// - Calculate and return the current amount owed to a vampire
    /// - Deletes the vampire info from staking structures
    /// - Moves the last vampire staked to the current position of this vampire
    ///
    /// What the controller should do after this function returns:
    ///
    /// - Transfer the `owed` amount of $BLOODBAGs to `sender`.
    /// - Transfer the NFT from this contract to `sender`
    ///
    /// Note: This is only called by controller, and the sender should be `_msgSender()`
    /// Note: We set all state first, and the do the transfers to avoid reentrancy
    ///
    /// @param sender address of who's making this request, should be the vampire owner
    /// @param tokenId id of the vampire
    /// @return owed amount of $BLOODBAGs owed to the vampire
    function unstakeVampire(address sender, uint16 tokenId)
        external
        returns (uint256 owed);

    function addTaxToVampires(uint256 amount, uint256 unaccountedRewards) external;
}