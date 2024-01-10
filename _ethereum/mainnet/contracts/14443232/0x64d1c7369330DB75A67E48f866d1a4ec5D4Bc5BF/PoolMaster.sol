// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PoolMetadata.sol";
import "./PoolRewards.sol";

contract PoolMaster is PoolRewards, PoolMetadata {
    // CONSTRUCTOR

    /**
     * @notice Upgradeable contract constructor
     * @param manager_ Address of the Pool's manager
     * @param currency_ Address of the currency token
     */
    function initialize(address manager_, IERC20Upgradeable currency_)
        external
        initializer
    {
        __PoolBaseInfo_init(manager_, currency_);
    }

    // OVERRIDES

    function _mint(address account, uint256 value)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._mint(account, value);
    }

    function _burn(address account, uint256 value)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._burn(account, value);
    }

    function decimals()
        public
        view
        override(ERC20Upgradeable, PoolMetadata)
        returns (uint8)
    {
        return super.decimals();
    }
}
