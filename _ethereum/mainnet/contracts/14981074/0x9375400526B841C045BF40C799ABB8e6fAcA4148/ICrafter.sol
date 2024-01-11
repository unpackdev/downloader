//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CraftLib.sol";

/**
 * @dev Pluggable Crafting Contract.
 */
interface ICrafter {
    /**
     * @notice Create recipe
     * @dev Configures crafting recipe with inputs/outputs
     * @param _admin Admin address to intialize ownership
     * @param _burnAddress Burn address for burn inputs
     * @param _inputs inputs for recipe
     * @param _outputs outputs for recipe
     */
    function initialize(
        address _admin,
        address _burnAddress,
        uint96 _craftableAmount,
        CraftLib.Ingredient[] calldata _inputs,
        CraftLib.Ingredient[] calldata _outputs
    ) external;

    /**
     * @notice Must be recipe creator
     * @dev Used to deposit recipe outputs
     * @param depositAmount How many times the recipe should be craftable
     * @param _outputsERC721Ids 2D-array of ERC721 tokens used in crafting
     */
    function deposit(uint96 depositAmount, uint256[][] calldata _outputsERC721Ids) external;

    /**
     * @notice Must be recipe creator
     * @dev Used to withdraw recipe outputs. Reverse logic as deposit().
     * @param withdrawAmount How many times the craft outputs should be withdrawn
     */
    function withdraw(uint96 withdrawAmount) external;

    /**
     * @notice Craft {craftAmount}
     * @dev Used to craft. Consumes inputs and transfers outputs.
     * @param craftAmount How many times to craft
     * @param _inputERC721Ids Array of pre-approved NFTs for crafting usage.
     */
    function craft(uint96 craftAmount, uint256[][] calldata _inputERC721Ids) external;
}
