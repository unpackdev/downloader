//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract Bits is ERC20, ERC20Pausable, Ownable {
    constructor(
        string memory _name, 
        string memory _symbol,
        address _tokensOwner,
        uint256 _tokensAmount
    ) ERC20(_name, _symbol) {
        _mint(_tokensOwner, _tokensAmount);
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }    
}
