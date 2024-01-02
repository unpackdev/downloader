//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./DotcStructures.sol";
import "./IDotcEscrow.sol";
import "./IDotc.sol";

/**
 * @title Interface for dOTC Manager contract (as part of the "SwarmX.eth Protocol")
 * @notice This interface provides methods for managing assets, fees, and linking core DOTC
 * components like the DOTC contract and the Escrow contract.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * Please read the Disclaimer featured on the SwarmX.eth website ("Terms") carefully before accessing,
 * interacting with, or using the SwarmX.eth Protocol software, consisting of the SwarmX.eth Protocol
 * technology stack (in particular its smart contracts) as well as any other SwarmX.eth technology such
 * as e.g., the launch kit for frontend operators (together the "SwarmX.eth Protocol Software").
 * By using any part of the SwarmX.eth Protocol you agree (1) to the Terms and acknowledge that you are
 * aware of the existing risk and knowingly accept it, (2) that you have read, understood and accept the
 * legal information and terms of service and privacy note presented in the Terms, and (3) that you are
 * neither a US person nor a person subject to international sanctions (in particular as imposed by the
 * European Union, Switzerland, the United Nations, as well as the USA). If you do not meet these
 * requirements, please refrain from using the SwarmX.eth Protocol.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * @dev Defines the interface for the DOTC Manager contract, outlining key functionalities
 * for managing DOTC configurations.
 * @author Swarm
 */
interface IDotcManager {
    /**
     * @notice Gets the base point scale used for calculations.
     * @return The base point scale (BPS) value.
     */
    function BPS() external view returns (uint256);

    /**
     * @notice Gets the standard decimal precision used in calculations.
     * @return The standard decimal precision value.
     */
    function DECIMALS() external view returns (uint256);

    /**
     * @notice Gets the current fee amount used in transactions.
     * @return The current transaction fee amount.
     */
    function feeAmount() external view returns (uint256);

    /**
     * @notice Gets the address of the DOTC contract.
     * @return The address of the DOTC contract.
     */
    function dotc() external view returns (IDotc);

    /**
     * @notice Gets the address of the DOTC Escrow contract.
     * @return The address of the DOTC Escrow contract.
     */
    function escrow() external view returns (IDotcEscrow);

    /**
     * @notice Gets the address where transaction fees are sent.
     * @return The address of the fee receiver.
     */
    function feeReceiver() external view returns (address);

    /**
     * @notice Checks if a given account is the owner of a specified asset.
     * @param asset The asset to check ownership of.
     * @param account The account to verify for ownership.
     * @return assetType The type of the asset if the account is the owner.
     */
    function checkAssetOwner(Asset memory asset, address account) external view returns (AssetType assetType);

    /**
     * @notice Checks if the specified account is the owner of the specified asset with standardized amount.
     * @param asset The asset to check.
     * @param account The account to verify ownership.
     * @return assetType The type of the asset if the account owns it.
     */
    function checkAssetOwnerStandardized(
        Asset calldata asset,
        address account
    ) external view returns (AssetType assetType);

    /**
     * @notice Standardizes the amount of an asset based on its type.
     * @param asset The asset to standardize.
     * @return amount The standardized amount of the asset.
     */
    function standardizeAsset(Asset calldata asset) external view returns (uint amount);

    /**
     * @notice Standardizes the amount of an asset based on its type with checking the ownership of this asset.
     * @param asset The asset to standardize.
     * @param assetOwner The address to check.
     * @return amount The standardized amount of the asset.
     */
    function standardizeAsset(Asset calldata asset, address assetOwner) external view returns (uint amount);

    /**
     * @notice Converts the standardized amount of an asset back to its original form.
     * @param asset The asset to unstandardize.
     * @return amount The unstandardized amount of the asset.
     */
    function unstandardizeAsset(Asset calldata asset) external view returns (uint amount);

    /**
     * @notice Standardizes a numerical amount based on token decimals.
     * @param amount The amount to standardize.
     * @param token The address of the token.
     * @return The standardized numerical amount.
     */
    function standardizeNumber(uint256 amount, address token) external view returns (uint256);

    /**
     * @notice Standardizes a numerical amount based on token decimals.
     * @param amount The amount to standardize.
     * @param decimals The decimals of the token.
     * @return The standardized numerical amount.
     */
    function standardizeNumber(uint256 amount, uint8 decimals) external view returns (uint256);

    /**
     * @notice Converts a standardized numerical amount back to its original form based on token decimals.
     * @param amount The amount to unstandardize.
     * @param token The address of the token.
     * @return The unstandardized numerical amount.
     */
    function unstandardizeNumber(uint256 amount, address token) external view returns (uint256);

    /**
     * @notice Converts a standardized numerical amount back to its original form based on token decimals.
     * @param amount The amount to unstandardize.
     * @param decimals The decimals of the token.
     * @return The unstandardized numerical amount.
     */
    function unstandardizeNumber(uint256 amount, uint8 decimals) external view returns (uint256);
}
