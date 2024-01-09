
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract IglooToken is Ownable, Pausable, ERC20("IGLOO", "IG"), ERC20Burnable {
    // 10 igloo per day on staking penguin

    constructor () {
        whitelist[0x9A31A088797157141BCB058E7eADEB04558603A0] = true; // whitelist staking contract
    }

    // mint limit
    uint mintingLimit = 1 * 1e9 * 1e18; // 1 Billion Supply = 1 * 9 zeros * 18 zeros = (1 * 9 zeros = 1 Billion) * (18 zeros = 18 decimals)

    function setMintingLimit(uint _mintingLimit) external onlyOwner {
        mintingLimit = _mintingLimit;
    }

    // minting
    bool public mintStopped = false;

    function mint(address account, uint256 amount) public onlyOwner {
        require(!mintStopped, "mint is stopped");
        _mint(account, amount);
        require(totalSupply() <= mintingLimit, "Increase the mint limit first.");   
    }

    function stopMint() public onlyOwner {
        mintStopped = true;
    }

    // white list
    mapping(address => bool) private whitelist;

    function setWhitelist(address[] calldata minters, bool allow) external onlyOwner {
        for (uint256 i; i < minters.length; i++) whitelist[minters[i]] = allow;
    }

    function whitelist_mint(address account, uint256 amount) external whenNotPaused {
        require(!mintStopped, "mint is stopped");
        require(whitelist[msg.sender], "Sender must be whitelisted");
        _mint(account, amount);
        require(totalSupply() <= mintingLimit, "Ask the owner to increase the mint limit first.");   
    }

    // ERC20Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
