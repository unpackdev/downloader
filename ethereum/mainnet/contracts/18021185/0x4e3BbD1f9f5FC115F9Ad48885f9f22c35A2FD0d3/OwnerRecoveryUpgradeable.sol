// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

abstract contract OwnerRecoveryUpgradeable is OwnableUpgradeable {
    function recoverLostETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverLostTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    uint256[50] private __gap;
}