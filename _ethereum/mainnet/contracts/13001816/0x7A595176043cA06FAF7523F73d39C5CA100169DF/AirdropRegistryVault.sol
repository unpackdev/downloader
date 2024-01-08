// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // solhint-disable-line compiler-version

import "./Ownable.sol";
import "./Pausable.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ERC20OnApprove.sol";

/**
 * @dev `deposit` source token and `claim` target token from NonLinearTimeLock contract.
 */
contract AirdropRegistryVault is Ownable, Pausable, OnApprove {
    using SafeERC20 for IERC20;

    modifier onlyValidAddress(address account) {
        require(account != address(0), "zero-address");
        _;
    }

    //////////////////////////////////////////
    //
    // AirdropRegistry
    //
    //////////////////////////////////////////

    function setAirdropRegistry(address airdropRegistry, address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(airdropRegistry, type(uint256).max);
        }
    }

    //////////////////////////////////////////
    //
    // OnApprove
    //
    //////////////////////////////////////////

    function onApprove(
        address owner,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        spender;
        data;
        IERC20(msg.sender).safeTransferFrom(owner, address(this), amount);
        return true;
    }

    //////////////////////////////////////////
    //
    // Circuit Breaker
    //
    //////////////////////////////////////////

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function claimToken(address token_) public onlyOwner whenPaused {
        if (address(token_) == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }

        IERC20(token_).safeTransfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }

    function claimTokens(address[] calldata tokens) external onlyOwner whenPaused {
        for (uint256 i = 0; i < tokens.length; i++) {
            claimToken(tokens[i]);
        }
    }
}
