// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";


contract NarwhaleToken is ERC20("Narwhale", "NAWA"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (School).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}