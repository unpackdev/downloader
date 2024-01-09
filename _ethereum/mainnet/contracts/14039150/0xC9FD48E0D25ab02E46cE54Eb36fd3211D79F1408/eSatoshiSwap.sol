// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract eSatoshiSwap is ERC20Pausable, Ownable {
    mapping(address => bool) public whitelisted;

    constructor() ERC20("memeToken", "MEME") {
        _mint(_msgSender(), 1_000_000_000_000 * (10**uint256(decimals())));
    }

    /**
     * @dev Transfer should be happening only between whitelisted buyers.
     *
     * Transfers from and to the owner address should be also whitelisted. e.g: For initial mint and transfer to LBP pool
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(from == owner() || to == owner() || (whitelisted[from] && whitelisted[to]), "Address not whitelisted");
    }

    /**
     * @dev Approve new buyers
     * @param newBuyers: list of the new buyer addresses
     */
    function addToWhitelisted(address[] calldata newBuyers) external onlyOwner {
        for (uint256 i = 0; i < newBuyers.length; i++) {
            whitelisted[newBuyers[i]] = true;
        }
    }

    /**
     * @dev Revoke transfer permissions from old buyers
     * @param oldBuyers: list of the old buyer addresses
     */
    function removeFromWhitelisted(address[] calldata oldBuyers) external onlyOwner {
        for (uint256 i = 0; i < oldBuyers.length; i++) {
            whitelisted[oldBuyers[i]] = false;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
