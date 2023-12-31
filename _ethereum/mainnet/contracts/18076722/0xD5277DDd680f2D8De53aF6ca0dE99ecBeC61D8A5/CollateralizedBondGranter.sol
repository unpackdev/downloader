// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./SafeERC20Upgradeable.sol";
import "./BondGranter.sol";

/**
 * @title CollateralizedBondGranter
 * @dev This contract contains functions related to the emission or withdrawal of
 * the bonds with collateral
 * @author Ethichub
 */
abstract contract CollateralizedBondGranter is BondGranter {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable private _collateralToken;

    uint256 public collateralMultiplier;
    uint256 public totalCollateralizedAmount;

    mapping(uint256 => uint256) public collaterals;

    event CollateralMultiplierUpdated(uint256 collateralMultiplier);
    event CollateralAssigned(uint256 tokenId, uint256 collateralAmount);
    event CollateralReleased(uint256 tokenId, uint256 collateralAmount);
    event CollateralExcessRemoved(address indexed destination);

    error MultiplierIndexLesserOrEqualZero();
    error NotEnoughCollateral();

    function __CollateralizedBondGranter_init(
        address collateralToken,
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    internal initializer {
        collateralMultiplier = 5;
        _collateralToken = IERC20Upgradeable(collateralToken);
        __BondGranter_init(_interests, _maturities);
    }

    function collateralTokenAddress() external view returns (address) {
        return address(_collateralToken);
    }

    /**
     * @dev Sets the number by which the amount of the collateral must be multiplied.
     * In this version will be 5
     * @param multiplierIndex uint256
     */
    function setCollateralMultiplier(uint256 multiplierIndex) external onlyRole(COLLATERAL_BOND_SETTER) {
        if (multiplierIndex <= 0) revert MultiplierIndexLesserOrEqualZero();
        collateralMultiplier = multiplierIndex;
        emit CollateralMultiplierUpdated(collateralMultiplier);
    }

    /**
     * @dev Function to withdraw the rest of the collateral that remains in the contract
     * to a specified address
     * @param destination address
     */
    function removeExcessOfCollateral(address destination) external onlyRole(COLLATERAL_BOND_SETTER) {
        uint256 excessAmount = _collateralToken.balanceOf(address(this)) - totalCollateralizedAmount;
        _collateralToken.safeTransfer(destination, excessAmount);
        emit CollateralExcessRemoved(destination);
    }

    /**
     * @dev Issues a bond with calculated collateral
     * @param tokenId uint256
     * @param maturity uint256 seconds
     * @param principal uint256 in wei
     * @param imageCID string
     *
     * Requirement:
     *
     * - The contract must have enough collateral
     */
    function _issueBond(
        uint256 tokenId,
        uint256 maturity,
        uint256 principal,
        string memory imageCID
    ) internal virtual override {
        if (! _hasCollateral(principal)) revert NotEnoughCollateral();
        super._issueBond(tokenId, maturity, principal, imageCID);
        uint256 collateralAmount = principal * collateralMultiplier;
        totalCollateralizedAmount = totalCollateralizedAmount + collateralAmount;
        collaterals[tokenId] = collateralAmount;
        emit CollateralAssigned(tokenId, collateralAmount);
    }

    /**
     * @dev Updates totalCollateralizedAmount when a bond is redeemed
     * @param tokenId uint256
     */
    function _redeemBond(uint256 tokenId) internal virtual override returns (uint256) {
        uint256 bondValue = super._redeemBond(tokenId);
        uint256 collateralAmount = collaterals[tokenId];
        totalCollateralizedAmount = totalCollateralizedAmount - collateralAmount;
        emit CollateralReleased(tokenId, collateralAmount);
        return bondValue;
    }

    /**
     * @dev Return true if the balace of the contract minus totalCollateralizedAmount is greater or equal to
     * the amount of the bond's collateral
     * @param principal uint256
     */
    function _hasCollateral(uint256 principal) internal view returns (bool) {
        if (_collateralToken.balanceOf(address(this)) - totalCollateralizedAmount >= principal * collateralMultiplier) {
            return true;
        }
        return false;
    }

    /**
     * ///////// [v1.0, v1.1] /////////
     * 1 _collateralToken
     * 1 collateralMultiplier
     * 1 totalCollateralizedAmount
     * 1 collaterals
     * 49 __gap
     * 53 (v1.0 mistakenly deployed with 53 store gaps)
     * --------------------------
     * ///////// [v1.2] /////////
     * 1 _collateralToken
     * 1 collateralMultiplier
     * 1 totalCollateralizedAmount
     * 1 collaterals
     * 24 __gap
     * 28 (v1.1 deployed reduced to 28 store gaps)
     */
    uint256[24] private __gap; // deployed with 28 store gaps
}