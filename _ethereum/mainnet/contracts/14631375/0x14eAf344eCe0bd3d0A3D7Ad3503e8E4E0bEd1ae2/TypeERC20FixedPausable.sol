// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PresetFixedSupply.sol";
import "./Ownable.sol";
import "./ERC20Pausable.sol";
import "./CryptoGenerator.sol";

// Fixed && Burnable && Pausable
contract TypeERC20FixedPausable is ERC20PresetFixedSupply, ERC20Pausable, Ownable, CryptoGenerator  {
    constructor(address _owner, string memory _name, string memory _symbol, uint _initialSupply, address payable _affiliated) ERC20PresetFixedSupply(_name, _symbol, _initialSupply * (10 ** 18), _owner) CryptoGenerator(_owner, _affiliated) payable {
        if (msg.sender != _owner) {
            transferOwnership(_owner);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
