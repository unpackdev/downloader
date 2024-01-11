// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC20.sol";

/// @title ContractSafe
/// @author Metacrypt (https://www.metacrypt.org/)
abstract contract OwnableClaimable is Ownable {
    function claimNative() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function claimToken(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}
