// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./Position.sol";
import "./IBondsRegistry.sol";

interface IVesting {
    /// @notice Returns total underlying vested for given holder.
    /// @dev It won't take into account if the holder has enough balance available to unlock,
    /// for that scenario use {availableUnderlyingFor} function.
    /// @param _tokenId position nft identifier
    /// @return vestedUnderlying the number of tokens vested
    function vestedUnderlyingFor(uint256 _tokenId) external view returns (uint256);

    /// @notice Returns total underlying available to be unlocked for given holder.
    /// @dev It compares the vested value to the position available balance and returns
    /// the highest amount of underlying that is available to be unlocked.
    /// @dev Availability might be less than the vested amount of the position holder
    /// offers some underlying to the Bonds contract.
    /// @param _tokenId position nft identifier
    /// @return availableUnderlying the number of tokens available to be unlocked (vested or balance)
    function availableUnderlyingFor(uint256 _tokenId) external view returns (uint256 availableUnderlying);

    /// @notice Returns pending revenue distribution claim for given position.
    /// @param _tokenId position nft identifier
    function pendingRevDisFor(uint256 _tokenId) external view returns (uint256);

    /// @notice Returns the underlying supplied value.
    /// @dev Value used by Illuvium's Vault contract to calculate revenue
    /// distributions.
    function poolTokenReserve() external view returns (uint256);

    /// @notice Returns whether spender is the position owner or an approved address.
    /// @param _spender Address using the position nft
    /// @param _tokenId position nft identifier
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool);

    /// @notice Pauses critical functionality in the contract.
    /// @dev Can be called by the eDAO multisig in case the contract needs to be paused
    /// in an emergency and unpaused later.
    /// @param _shouldPause whether the contract needs to be paused/unpaused
    function setPauseState(bool _shouldPause) external;

    /// @notice Enables/disables ERC721 transfer functionality.
    /// @dev Only owner (the eDAO) is able to enable/disable the ERC721
    /// transfer functionality. By default it's disabled for all position NFT
    /// holders, only the owner is able to do it, in order to be able to call
    /// {setPositions()}.
    function setTransferState(bool _shouldAllow) external;

    /// @notice Updates ERC721 base URI value.
    function setBaseURI(string memory _newBaseURI) external;

    /// @notice Updates Bonds contract address stored.
    /// @dev Can only be called by the owner (eDAO multisig)
    /// @param _bondsRegistry Bonds contract address
    function setBondsContract(IBondsRegistry _bondsRegistry) external;

    /// @notice Updates Vault contract address stored.
    /// @dev Can only be called by the owner (eDAO multisig)
    /// @param _vault Vault contract address
    function setVaultContract(address _vault) external;

    /// @notice Sets vesting positions for an array of addresses.
    /// @dev Only the contract owner (eDAO gnosis multisig) is able to add new positions.
    /// @param _holders an array of locked token holders addresses
    /// @param _positions position data for each holder address
    function setPositions(address[] calldata _holders, Position.InitParams[] calldata _positions) external;

    /// @notice Unlocks vested tokens for the given position.
    /// @dev If holder has less available balance than the vested underlying (due to bonds),
    /// it should unlock the whole balance.
    /// @dev It's expected that holders are able to move tokens to Bonds contract
    /// and bring back unsold underlying and keep unlocking at the same rate.
    /// @param _tokenId position nft identifier
    function unlock(uint256 _tokenId) external;

    /// @notice Claims pending revenue distribution for the given position.
    /// @dev Only approved address or token owner can request the revdis claim.
    /// @dev Position's revdis values must be updated before proceeding to the claim,
    /// in order to keep correct calculations.
    /// @param _tokenId position nft identifier
    function claimRevenueDistribution(uint256 _tokenId) external;

    /// @notice Hook called by the bonds contract after a position balance
    /// is offered.
    /// @dev Important checks are performed, only the token owner or an approved party
    /// is able to offer a part of or the whole position underlying balance to be
    /// sold in the bonds contract.
    /// @dev Call is restricted to the bonds contract.
    /// @dev It should remove the underlying value supplied to become an offer.
    /// @param _caller address who initiated the call in the bonds contract
    /// @param _tokenId position nft identifier
    /// @param _value number of underlying tokens to be offered
    function afterUnderlyingOffer(
        address _caller,
        uint256 _tokenId,
        uint256 _value
    ) external;

    /// @notice Hook called by the bonds contract after a position holder
    /// offer in the contract is resigned.
    /// @dev Important checks are performed, only the token owner or an approved party
    /// is able to resign a previously created offer and bring back the leftover underlying.
    /// @dev It returns to the position the remaining underlying, tokens that haven't
    /// been sold as bonds.
    /// @param _caller address who initiated the call in the bonds contract
    /// @param _tokenId position nft identifier
    /// @param _value number of underlying tokens to be returned
    function afterOfferResignation(
        address _caller,
        uint256 _tokenId,
        uint256 _value
    ) external;

    /// @notice Asks for underlying tokens from the vault contract and distributes
    /// revenue.
    /// @dev Only the vault contract is able to trigger this function.
    /// @param _reward underlying reward to be distributed as revdis.
    function receiveVaultRewards(uint256 _reward) external;
}
