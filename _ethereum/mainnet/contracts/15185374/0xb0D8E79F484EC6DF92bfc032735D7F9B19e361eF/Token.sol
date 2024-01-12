// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract Token is ERC20, Ownable, ReentrancyGuard {
    constructor(address owner, uint256 _amount) ERC20("ZEROGAS", "0GAS") {
        _mint(owner, _amount);
    }

    /**
     * @notice allow owner withdraw tokens, transfered to this contract (by mistake)
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
        nonReentrant
    {
        TransferHelper.safeTransfer(tokenAddress, owner(), tokenAmount);
    }
}
