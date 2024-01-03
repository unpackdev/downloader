/*
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Pausable.sol";
import "./FundsManager.sol";

import "./IERC20.sol";

/**
 * @title TokenSwaps
 * @dev This contract allowed 1:1 swap of one ERC20 token to another
 */
contract TokenSwaps is Pausable, FundsManager {
    // token from user
    IERC20 public tokenFrom;

    // token to user
    IERC20 public tokenTo;

    // swapped amount
    uint256 public swapped;

    // wallet for tokenTo
    address public wallet;

    /**
     * @param _tokenFrom Token from user
     * @param _tokenTo Token to user
     * @param _wallet Wallet address for tokenTo
     **/
    constructor(
        IERC20 _tokenFrom,
        IERC20 _tokenTo,
        address _wallet
    ) public {
        tokenFrom = _tokenFrom;
        tokenTo = _tokenTo;
        wallet = _wallet;
    }

    /**
     * @notice Token must be pre-approved
     * @dev Swap token with ratio 1:1 for sender
     * @param _amount The amount of tokens to swap
     **/
    function swap(uint256 _amount) public {
        swapToAddress(_amount, msg.sender);
    }

    /**
     * @notice Token must be pre-approved
     * @dev Swap token with ratio 1:1 from sender to _to address
     * @param _amount The amount of tokens to swap
     * @param _to Token recipient address
     **/
    function swapToAddress(uint256 _amount, address _to) public whenNotPaused {
        tokenFrom.transferFrom(msg.sender, wallet, _amount);
        tokenTo.transfer(_to, _amount);

        swapped += _amount; // safe: SafeMath is not required
    }

    /**
     * @dev Pauses token swaps.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses token swaps.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Set a new wallet address.
     */
    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    receive() external payable {
        revert("TokenSwaps: sending eth is prohibited");
    }
}
