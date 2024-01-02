// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4 <0.9.0;

/// @notice A minimal spec in the spirit of ERC-7281, generalized to any minter/burner
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/ERC7281/IERC7281Min.sol)
/// @author Modified from defi-wonderland (https://github.com/defi-wonderland/xERC20/blob/main/solidity/interfaces/IXERC20.sol)
interface IERC7281Min {
    /**
     * @notice Emits when a limit is set
     *
     * @param issuer The address of the issuer on which we are setting limits
     * @param mintingLimit The minting limit we are setting on the issuer
     * @param burningLimit The burning limit we are setting on the issuer
     */
    event IssuerLimitsSet(address indexed issuer, uint256 mintingLimit, uint256 burningLimit);

    /**
     * @notice Reverts when a user with too low of a limit tries to call mint/burn
     */
    error ERC7281_LimitExceeded();

    /**
     * @notice Updates the limits of an issuer
     * @dev Can only be called by the owner
     * @param issuer The address of the issuer on which we are setting limits
     * @param mintingLimit The minting limit we are setting on the issuer
     * @param burningLimit The burning limit we are setting on the issuer
     */
    function setIssuerLimits(address issuer, uint256 mintingLimit, uint256 burningLimit) external;

    /**
     * @notice Returns the max limit of an issuer
     */
    function mintingMaxLimitOf(address issuer) external view returns (uint256);

    /**
     * @notice Returns the max limit of a bridge
     */
    function burningMaxLimitOf(address issuer) external view returns (uint256);

    /**
     * @notice Returns the current limit of a issuer
     */
    function mintingCurrentLimitOf(address issuer) external view returns (uint256);

    /**
     * @notice Returns the current limit of a bridge
     */
    function burningCurrentLimitOf(address issuer) external view returns (uint256);

    /**
     * @notice Mints tokens for a user
     * @dev Can only be called by an issuer
     * @param to The address of the user who needs tokens minted
     * @param value The amount of tokens being minted
     */
    function mint(address to, uint256 value) external;

    /**
     * @notice Burns tokens for a user
     * @dev Can only be called by an issuer
     * @param from The address of the user who needs tokens burned
     * @param value The amount of tokens being burned
     */
    function burn(address from, uint256 value) external;
}
