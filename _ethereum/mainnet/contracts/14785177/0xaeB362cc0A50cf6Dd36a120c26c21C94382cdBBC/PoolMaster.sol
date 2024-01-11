// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PoolMetadata.sol";
import "./PoolRewards.sol";
import "./PoolConfiguration.sol";

contract PoolMaster is PoolRewards, PoolConfiguration, PoolMetadata {
    /// @notice Version of the Pool Contract
    string public constant VERSION = "1.1.0";

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

    function _mint(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, PoolRewards)
    {
        super._burn(account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, PoolRewards) {
        super._transfer(from, to, amount);
    }

    function decimals()
        public
        view
        override(ERC20Upgradeable, PoolMetadata)
        returns (uint8)
    {
        return super.decimals();
    }

    function symbol()
        public
        view
        override(ERC20Upgradeable, PoolMetadata)
        returns (string memory)
    {
        return super.symbol();
    }
}
