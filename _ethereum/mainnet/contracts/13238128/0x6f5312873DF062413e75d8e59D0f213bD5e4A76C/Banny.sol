// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

import "./Ownable.sol";

contract Banny is ERC20, ERC20Permit, Ownable {
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    constructor() ERC20("Banny", "BANNY") ERC20Permit("Banny") {}

    function mint(address _account, uint256 _amount) external onlyOwner {
        return _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOwner {
        return _burn(_account, _amount);
    }
}
