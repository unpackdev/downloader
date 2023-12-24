// contracts/GreenMetaverseToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/**
 * Green Metaverse Token
 * @author STEPN
 */
contract GreenMetaverseToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("GreenMetaverseToken", "GMT") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}
