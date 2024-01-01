// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./draft-ERC20Permit.sol";

/**
 * Reward token contract to be used by the gdxen protocol.
 * The entire amount is minted by the main gdxen contract
 * (GDXen.sol - which is the owner of this contract)
 * directly to an account when it claims rewards.
 */
contract GDXenERC20 is ERC20Permit {
    /**
     * The address of the GDXen.sol contract instance.
     */
    address public immutable owner;

    /**
     * Sets the owner address.
     * Called from within the GDXen.sol constructor.
     */
    constructor() ERC20("GDXen Token", "GDXen") ERC20Permit("GDXen Token") {
        owner = msg.sender;
    }

    /**
     * The total supply is naturally capped by the distribution algorithm
     * implemented by the main gdxen contract, however an additional check
     * that will never be triggered is added to reassure the reader.
     *
     * @param account the address of the reward token reciever
     * @param amount wei to be minted
     */
    function mintReward(address account, uint256 amount) external {
        require(msg.sender == owner, "GDXen: caller is not GDXen contract.");
        require(
            super.totalSupply() < 5010000000000000000000000,
            "GDXen: max supply already minted"
        );
        _mint(account, amount);
    }
}
