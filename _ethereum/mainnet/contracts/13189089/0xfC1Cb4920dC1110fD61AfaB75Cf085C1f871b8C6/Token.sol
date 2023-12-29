// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Token is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable {
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    )
        ERC20(_name, _symbol)
        ERC20Burnable ()
        ERC20Snapshot() {
        _mint(msg.sender, _initialSupply);
    }



    function snapshot() external onlyOwner {
        _snapshot();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function mint (
        address to,
        uint256 amount
    ) external onlyOwner {
        _mint(to, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal whenNotPaused override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}