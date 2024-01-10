// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract SoToken is ERC20Burnable, Pausable, Ownable, ReentrancyGuard {
    uint256 private constant MAX_SUPPLY = 100 * (10**9) * (10**18);
    mapping(address => bool) public transferWhitelist;

    constructor() ERC20('SomniLife', 'SO') {
        setTransferWhitelist(address(0), true);
        pause();
    }

    function mint(address account, uint256 amount) public virtual onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceed max supply');
        _mint(account, amount);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function setTransferWhitelist(address memeber, bool enable) public onlyOwner {
        transferWhitelist[memeber] = enable;
    }

    function setTransferWhitelist(address[] calldata memebers, bool enable) public onlyOwner {
        for (uint256 i; i < memebers.length; i++) {
            setTransferWhitelist(memebers[i], enable);
        }
    }

    function setTransferWhitelist(address[] calldata memebers, bool[] calldata enables) public onlyOwner {
        require(memebers.length == enables.length, 'length error');
        for (uint256 i; i < memebers.length; i++) {
            setTransferWhitelist(memebers[i], enables[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || transferWhitelist[from], 'Token transfer while paused');
    }
}