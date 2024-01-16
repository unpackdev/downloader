// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @title Mock VSP.
 */
contract MockVSP is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @dev Mint VSP. Only owner can mint
    function mint(address _recipient, uint256 _amount) external onlyOwner {
        _mint(_recipient, _amount);
    }
}
