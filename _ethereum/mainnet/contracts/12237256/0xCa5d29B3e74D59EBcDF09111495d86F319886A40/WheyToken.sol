// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";

contract WheyToken is ERC20("WheyToken", "WHEY"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (WheyFarm).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}