// SPDX-License-Identifier: BUSL-1.1
// Note: The majority part of this code has been derived from the Sushiswap SushiBar code (MIT).
pragma solidity ^0.8.9;

import "./IERC20.sol";

import "./LibAppStorage.sol";
import "./Modifiers.sol";
import "./LibDiamond.sol";
import "./LibXPilgrimLockup.sol";
import "./XPilgrim.sol";

/// @title  A temple for pilgrims, this contract handles swapping to and from xPIL, Pilgrim's staking token.
///
/// @author rn.ermaid
///
/// @notice You come in with some PIL, and leave with more! The longer you stay, the more PIL you get.
///
contract PilgrimTempleFacet is Modifiers {
    AppStorage internal s;

    event Enter(address _sender, uint128 _pilIn, uint128 _xPilOut);
    event Leave(address _sender, uint128 _xPilIn, uint128 _pilOut);

    /// @notice Stake and lock PILs, earn some shares in xPIL.
    ///
    /// @dev    Lock PIL and mint xPIL
    ///
    /// @param  _amount  Amount of PIL token to be staked
    ///
    function enter(uint128 _amount) external onlyOneBlock {
        // Gets the amount of Pil locked in the contract
        uint256 totalPil = s.pilgrim.balanceOf(address(this));
        // Gets the amount of xPil in existence
        uint256 totalShares = s.xPilgrim.totalSupply();

        uint128 xPilOut;
        // If no xPil exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalPil == 0) {
            xPilOut = _amount;
        }
        // Calculate and mint the amount of xPil the Pil is worth. The ratio will change overtime, as xPil is burned/minted and Pil deposited + gained from fees / withdrawn.
        else {
            xPilOut = uint128(_amount * totalShares / totalPil);
        }
        s.xPilgrim.mint(msg.sender, xPilOut);
        LibXPilgrimLockup.enqueue(msg.sender, xPilOut);
        // Lock the Pil in the contract
        require(s.pilgrim.transferFrom(msg.sender, address(this), _amount));
        emit Enter(msg.sender, _amount, xPilOut);
    }

    /// @notice Leave the temple. Claim back your PILs.
    ///
    /// @dev    Unlock the staked + gained PILs and burn xPILs
    ///
    /// @param  _share  Amount of xPILs to be burned
    ///
    function leave(uint128 _share) external onlyOneBlock {
        uint256 _unlockedAmount = LibXPilgrimLockup.getUnlockedAmount(msg.sender);
        require(_unlockedAmount >= _share, "PilgrimTemple: leave amount exceeds unlocked balance");
        LibXPilgrimLockup.reduceUnlockedAmount(msg.sender, _share);

        // Gets the amount of xPil in existence
        uint256 totalShares = s.xPilgrim.totalSupply();
        // Calculates the amount of Pil the xPil is worth
        uint128 what = uint128(_share * s.pilgrim.balanceOf(address(this)) / totalShares);
        s.xPilgrim.burn(msg.sender, _share);
        require(s.pilgrim.transfer(msg.sender, what));
        emit Leave(msg.sender, _share, what);
    }

    /// @notice This method can be used to get current claimable xPIL shares for each holder
    ///
    /// @return _unlockedAmount Unlocked & non-claimed xPIL shares
    ///
    function getUnlockedAmount(address _holder) external view returns (uint128 _unlockedAmount) {
        return LibXPilgrimLockup.getUnlockedAmount(_holder);
    }

    /// @notice This method can be used to get extra claimable xPIL shares in the future
    ///
    /// @return _lockedAmount   Locked xPIL shares
    ///
    function getLockedAmount(address _holder) external view returns (uint128 _lockedAmount) {
        return LibXPilgrimLockup.getLockedAmount(_holder);
    }

}
