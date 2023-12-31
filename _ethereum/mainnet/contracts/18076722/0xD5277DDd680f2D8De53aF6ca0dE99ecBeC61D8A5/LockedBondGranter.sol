// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./BondGranter.sol";

/**
 * @title LockedBondGranter
 * @dev This contract contains functions related cooldown of the bonds
 * @author Ethichub
 */
abstract contract LockedBondGranter is BondGranter {
    uint256 public COOLDOWN;

    mapping(uint256 => uint256) public cooldowns;

    event CooldownStarted(uint256 tokenId, uint256 cooldown);

    error BondIsLocked();
    error CooldownCanNotBeActivated();

    function __LockedBondGranter_init(
        uint256 cooldown,
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    ) internal initializer {
        COOLDOWN = cooldown;
        __BondGranter_init(_interests, _maturities);
    }

    /**
     * @dev editable the cooldown seconds
     * @param cooldown cooldown seconds
     */
    function setCooldown(uint256 cooldown) external onlyRole(COOLDOWN_SETTER) {
        COOLDOWN = cooldown;
    }

    function activateCooldown(uint256 tokenId) public virtual {
        Bond memory bond = bonds[tokenId];
        if (cooldowns[tokenId] != 0 || (bond.maturity + bond.mintingDate) >= block.timestamp || _isUnlocked(tokenId)) revert CooldownCanNotBeActivated();
        cooldowns[tokenId] = block.timestamp + COOLDOWN;

        emit CooldownStarted(tokenId, block.timestamp);
    }

    /**
     * @dev Function to redeem bond
     * @param tokenId uint256
     */
    function _redeemBond(uint256 tokenId) internal virtual override returns (uint256) {
        if (! _isUnlocked(tokenId)) revert BondIsLocked();
        uint256 bondValue = super._redeemBond(tokenId);
        Bond memory bond = bonds[tokenId];
        uint256 timeElapsed = cooldowns[tokenId] - bond.mintingDate;
        bondValue = _bondValue(bond.principal, bond.interest, timeElapsed);
        emit BondRedeemed(msg.sender, tokenId, block.timestamp, bond.maturity, bondValue, bond.interest, bond.imageCID);
        return bondValue;
    }

    /**
     * @dev Checks if bond is unlock to redeemed
     * @param tokenId uint256
     */
    function _isUnlocked(uint256 tokenId) internal view returns (bool) {
        if (cooldowns[tokenId] != 0 && block.timestamp > cooldowns[tokenId]) {
            return true;
        }
        return false;
    }

    /**
     * ///////// [v1.0, v1.1] /////////
     * Non deployed
     * ///////// [v1.2] /////////
     * 1 COOLDOWN
     * 1 cooldowns
     * 23 __gap
     * 25 (v1.1 new deployed with 25 store gaps)
     */
    uint256[23] private __gap; // deployed with 25 store gaps
}