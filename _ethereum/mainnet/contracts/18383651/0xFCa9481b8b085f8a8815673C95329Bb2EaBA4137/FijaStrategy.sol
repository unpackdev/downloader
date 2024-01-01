// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma abicoder v2;

import "./Strings.sol";

import "./FijaERC4626Base.sol";
import "./IFijaStrategy.sol";

///
/// @title Strategy Base contract
/// @author Fija
/// @notice Used as template for implementing strategy
/// @dev there are methods with minimum or no functionality
/// it is responsibility of child contracts to override them
///
contract FijaStrategy is IFijaStrategy, FijaERC4626Base {
    bool internal _isEmergencyMode = false;

    constructor(
        IERC20 asset_,
        address governance_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_
    )
        FijaERC4626Base(
            asset_,
            governance_,
            address(0),
            tokenName_,
            tokenSymbol_,
            maxTicketSize_,
            maxVaultValue_
        )
    {}

    modifier emergencyModeRestriction() {
        if (_isEmergencyMode) {
            revert FijaInEmergencyMode();
        }
        _;
    }

    ///
    /// NOTE: only governance access
    /// @inheritdoc IFijaACL
    ///
    function addAddressToWhitelist(
        address addr
    ) public virtual override onlyGovernance returns (bool) {
        return super.addAddressToWhitelist(addr);
    }

    ///
    /// NOTE: only governance access
    /// @inheritdoc IFijaACL
    ///
    function removeAddressFromWhitelist(
        address addr
    ) public virtual override onlyGovernance returns (bool) {
        return super.removeAddressFromWhitelist(addr);
    }

    ///
    /// @inheritdoc IFijaStrategy
    ///
    function needRebalance() external view virtual override returns (bool) {
        return false;
    }

    ///
    /// NOTE: Only governance access; Not implemented
    /// emits IFijaStrategy.Rebalance
    /// @inheritdoc IFijaStrategy
    ///
    function rebalance()
        external
        virtual
        override
        onlyGovernance
        emergencyModeRestriction
    {
        emit Rebalance(block.timestamp, "");
    }

    ///
    /// @inheritdoc IFijaStrategy
    ///
    function needHarvest() external view virtual override returns (bool) {
        return false;
    }

    ///
    /// NOTE: Only governance access; Not implemented
    /// emits IFijaStrategy.Harvest
    /// @inheritdoc IFijaStrategy
    ///
    function harvest()
        external
        virtual
        override
        onlyGovernance
        emergencyModeRestriction
    {
        emit Harvest(block.timestamp, 0, 0, asset(), "");
    }

    ///
    /// @inheritdoc IFijaStrategy
    ///
    function needEmergencyMode() external view virtual override returns (bool) {
        return false;
    }

    ///
    /// NOTE: Only governance access; Not implemented
    /// emits IFijaStrategy.EmergencyMode
    /// @inheritdoc IFijaStrategy
    ///
    function setEmergencyMode(
        bool turnOn
    ) external virtual override onlyGovernance {
        _isEmergencyMode = turnOn;
        emit EmergencyMode(block.timestamp, turnOn);
    }

    ///
    /// @inheritdoc IFijaStrategy
    ///
    function emergencyMode() external view virtual override returns (bool) {
        return _isEmergencyMode;
    }

    ///
    /// @inheritdoc IFijaStrategy
    ///
    function status() external view virtual override returns (string memory) {
        string memory str = string(
            abi.encodePacked("totalAssets=", Strings.toString(totalAssets()))
        );

        return str;
    }

    ///
    /// NOTE: emergency mode check
    /// @inheritdoc FijaERC4626Base
    ///
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        payable
        virtual
        override(FijaERC4626Base, IERC4626)
        emergencyModeRestriction
        returns (uint256)
    {
        return super.deposit(assets, receiver);
    }

    receive() external payable virtual {}
}
