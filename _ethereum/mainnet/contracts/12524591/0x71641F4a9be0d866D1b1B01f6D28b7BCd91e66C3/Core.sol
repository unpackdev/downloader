// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./Permissions.sol";
import "./ICore.sol";
import "./Rusd.sol";
import "./Ring.sol";

/// @title Source of truth for Ring Protocol
/// @author Ring Protocol
/// @notice maintains roles, access control, rusd, ring, genesisGroup, and the RING treasury
contract Core is ICore, Permissions, Initializable {

    /// @notice the address of the RUSD contract
    IRusd public override rusd;
    
    /// @notice the address of the RING contract
    IERC20 public override ring;

    /// @notice the address of the GenesisGroup contract
    address public override genesisGroup;
    /// @notice determines whether in genesis period or not
    bool public override hasGenesisGroupCompleted;

    function init() external override initializer {
        _setupGovernor(msg.sender);
        
        Rusd _rusd = new Rusd(address(this));
        _setRusd(address(_rusd));

        Ring _ring = new Ring(address(this), msg.sender);
        _setRing(address(_ring));
    }

    /// @notice sets Rusd address to a new address
    /// @param token new rusd address
    function setRusd(address token) external override onlyGovernor {
        _setRusd(token);
    }

    /// @notice sets Ring address to a new address
    /// @param token new ring address
    function setRing(address token) external override onlyGovernor {
        _setRing(token);
    }

    /// @notice sets Genesis Group address
    /// @param _genesisGroup new genesis group address
    function setGenesisGroup(address _genesisGroup)
        external
        override
        onlyGovernor
    {
        genesisGroup = _genesisGroup;
        emit GenesisGroupUpdate(_genesisGroup);
    }

    /// @notice sends RING tokens from treasury to an address
    /// @param to the address to send RING to
    /// @param amount the amount of RING to send
    function allocateRing(address to, uint256 amount)
        external
        override
        onlyGovernor
    {
        IERC20 _ring = ring;
        require(
            _ring.balanceOf(address(this)) >= amount,
            "Core: Not enough Ring"
        );

        _ring.transfer(to, amount);

        emit RingAllocation(to, amount);
    }

    /// @notice marks the end of the genesis period
    /// @dev can only be called once
    function completeGenesisGroup() external override {
        require(
            !hasGenesisGroupCompleted,
            "Core: Genesis Group already complete"
        );
        require(
            msg.sender == genesisGroup,
            "Core: Caller is not Genesis Group"
        );

        hasGenesisGroupCompleted = true;

        // solhint-disable-next-line not-rely-on-time
        emit GenesisPeriodComplete(block.timestamp);
    }

    function _setRusd(address token) internal {
        rusd = IRusd(token);
        emit RusdUpdate(token);
    }

    function _setRing(address token) internal {
        ring = IERC20(token);
        emit RingUpdate(token);
    }
}
