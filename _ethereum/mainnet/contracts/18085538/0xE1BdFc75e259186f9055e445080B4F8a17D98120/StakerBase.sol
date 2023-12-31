// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";

contract StakerBase is OwnableUpgradeable  {
    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {            
            IERC20(token).transfer(to, amount);
        }
    }
}
