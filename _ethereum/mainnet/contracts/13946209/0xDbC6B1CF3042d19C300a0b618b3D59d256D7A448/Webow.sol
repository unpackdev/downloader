// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./draft-ERC20Permit.sol";
import "./Ownable.sol";

contract Webow is ERC20, ERC20Permit, Ownable {
    using SafeERC20 for IERC20;

    // TODO name and symbol
    constructor(uint256 _initialSupply, address _receiver) ERC20("WeBow Token", "WBW") ERC20Permit("WeBow Token") {
        _mint(_receiver, _initialSupply);
    }

    function recoverFunds(address _token, address _receiver) external onlyOwner {
        IERC20(_token).safeTransfer(_receiver, IERC20(_token).balanceOf(address(this)));
    }
}
