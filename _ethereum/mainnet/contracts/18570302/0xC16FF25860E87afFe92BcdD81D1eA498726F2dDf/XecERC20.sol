// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./draft-ERC20Permit.sol";

contract XecERC20 is ERC20Permit {
    /**
     * The address of the Xec.sol contract instance.
     */
    address public immutable owner;

    /**
     * Sets the owner address.
     * Called from within the Xec.sol constructor.
     */
    constructor() ERC20("Xec Token", "Xec") ERC20Permit("Xec Token") {
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
        require(msg.sender == owner, "Xec: caller is not Xec contract.");
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
