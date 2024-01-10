//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Pausable.sol";

contract MotormetaPreliminaryToken is
    ERC20,
    ERC20Capped,
    ERC20Pausable,
    Ownable
{
    constructor(address holder)
        ERC20("Preliminary Motormeta Token", "preMMT")
        ERC20Capped(500000000 ether)
    {
        _mint(holder, cap());
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
