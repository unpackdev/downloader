// SPDX-License-Identifier: MIT
// Clopr Contracts

pragma solidity 0.8.21;

/**
 * @title IStoryPotionTank
 * @author Pybast.eth - Nefture
 * @custom:lead Antoine Bertin - Clopr
 * @dev Handles the distribution and management of StoryPotions, vital ingredients required for creating and enhancing CloprStories.
 */
interface IStoryPotionTank {
    /// @notice thrown if the given vault is not delegated to the caller
    error InvalidDelegateVaultPairing();

    /// @notice thrown if the given fill price is not correct
    error BadFillPrice();

    /// @notice thrown if the StoryPotion tank is empty
    error EmptyStoryPotionTank();

    /// @notice thrown if there is no ether to withdraw from the contract
    error NothingToWithdraw();

    /// @notice thrown if the contract withdrawal has failed
    error FailedToWithdraw();

    /// @notice thrown if trying to withdraw funds to the zero address
    error CantWithdrawToZeroAddress();

    /// @notice thrown if trying to set the baseUri as an empty string
    error BaseUriCantBeNull();

    /// @notice emitted when the fillPrice is modified
    event NewFillPrice(uint64 fillPrice);

    /// @notice emitted when the base URI is modified
    event NewBaseUri(string newBaseUri);

    /**
     * ----------- EXTERNAL -----------
     */

    /// @notice Allows wallets with MODIFY_FILL_PRICE_ROLE to change the price to fill a CloprBottles with StoryPotion
    /// @dev Emits an event to enable tracking fill up price changes
    /// @param newPrice new price to fill a CloprBottles with StoryPotion
    function adminChangeFillPrice(uint64 newPrice) external;

    /// @notice Fill up a CloprBottles with StoryPotion
    /// @dev Here, an external call to the CloprBottles contract is made
    /// @param bottleTokenId token ID of the CloprBottles
    /// @param vault Delegate Cash vault to use as a delegated wallet
    function fillBottle(uint256 bottleTokenId, address vault) external payable;

    /**
     * ----------- ADMIN -----------
     */

    /// @notice allows owner to withdraw contract's ether to an arbitrary account
    /// @param receiver receiver of the funds
    function withdraw(address receiver) external;

    /// @notice Allows owner to change the base URI
    /// @dev Don't forget the trailing slash in the base URI as it will be concatenated with other information.
    ///      Emits an event to enable tracking base URI changes
    /// @param newBaseUri the new base URI
    function changeDefaultBaseUri(string memory newBaseUri) external;

    /**
     * ----------- ENUMERATIONS -----------
     */

    /// @notice Get the StoryPotion's remaining supply
    /// @return potionTankSupply_ the StoryPotion's remaining supply
    function getPotionTankSupply()
        external
        view
        returns (uint16 potionTankSupply_);

    /// @notice Get the price of a StoryPotion fill up
    /// @return fillPrice_ price of a StoryPotion fill up
    function getFillPrice() external view returns (uint64 fillPrice_);
}
