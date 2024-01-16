// SPDX-License-Identifier: institutoibi.org.br License
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract InstitutoIBIToken is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Instituto IBI", "IBI") {
        _mint(
            0xa8fAc7871f389E199c95ff75EA96fe63557363a1,
            10000000000 * 10**decimals()
        );
    }

    function decimals() public view virtual override returns (uint8) {
        return 5;
    }

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
