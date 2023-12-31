// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 * @title Token: Perform operations like mint, burn, pause etc. on Token
 */

contract Token is ERC20, ERC20Burnable, Pausable, Ownable {
    bool public mintingFinished = false;

    event MintFinished();

    modifier canMint() {
        require(!mintingFinished, "Token: Minting not Allowed!");
        _;
    }

    constructor(string memory tokenName, string memory tokensSymbol, uint256 tokenSupply, address _owner)
        ERC20(tokenName, tokensSymbol)
    {
        _mint(msg.sender, tokenSupply);
        transferOwnership(_owner);
    }

    /**
     * @dev Pauses token transfers.
     * Can only be called by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses token transfers.
     * Can only be called by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Mints new tokens and assigns them to the specified address.
     * Can only be called by the contract owner.
     * @param to The address to which the minted tokens will be assigned.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner canMint {
        _mint(to, amount);
    }

    /**
     * @dev Finish token minting.
     * Can only be called by the contract owner.
     * @return A boolean indicating if the token minting was finished successfully.
     */
    function finishMinting() external onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function burnRemainingSaleTokens(uint256 utilizedTokens) external onlyOwner returns (bool) {
        uint256 totalDistributedIcoTokens = (totalSupply() * 65) / 100;
        burn(totalDistributedIcoTokens - utilizedTokens);
        return true;
    }
}
