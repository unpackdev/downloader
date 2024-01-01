// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title Node Haven
 * @dev ERC20 Token for KASNODE, used within the Node Haven rental ecosystem.
 * This token represents the utility token for renting nodes in the Kaspa network.
 * The initial supply is minted to the deployer's address, who can then distribute accordingly.
 * Trading is initially disabled and can be enabled by the owner, allowing for a controlled launch.
 */
contract KASNODE is ERC20, Ownable {
    bool private launching;

    constructor() ERC20("Node Haven", "KASNODE") Ownable(msg.sender) {
        uint256 _totalSupply = 28700000000 * (10 ** decimals());
        launching = true;
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev Overrides the _update function to restrict trading while the token is launching.
     * Trading can only occur between regular users once the owner has called enableTrading.
     * Until then, only the owner can transfer tokens, such as for initial distribution or liquidity provisioning.
     */
    function _update(address from, address to, uint256 amount) internal override {
        if (launching) {
            require(to == owner() || from == owner(), "Trading is not yet active");
        }
        super._update(from, to, amount);
    }

    /**
     * @dev Allows the owner to enable trading of the KASNODE token.
     * Once enabled, it cannot be disabled again.
     */
    function enableTrading() external onlyOwner {
        launching = false;
    }

    
}
