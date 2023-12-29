// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ERC20Capped.sol";

/**
 * Token contract owned by ZXNProtocol contract
 */
contract ZXN is ERC20("ZXN", "ZXN"), ERC20Capped(1_000_000_000 ether) {

    /**
     * @dev ZXN contract address.
     */
    address public immutable owner;

    /**
     * @dev Constructor is called from ZXNProtocol
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev The total supply is 1,000,000,000 ZXN
     * @param to reward token reciever's address
     * @param amount wei to be minted
     */
    function mintReward(address to, uint256 amount) external {
        require(msg.sender == owner, "ZXN: Caller must be ZXNProtocol contract.");
        require(super.totalSupply() <= cap(), "ZXN: max supply already minted.");
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal override (ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}
