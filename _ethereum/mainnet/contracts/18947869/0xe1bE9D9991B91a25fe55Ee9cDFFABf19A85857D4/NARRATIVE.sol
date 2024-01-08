// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// THE ONLY NARRATIVE YOU'LL NEED. 0/0 TAX. STEALTH LAUNCH. LIQUIDITY 100% BURNED.

import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./DEXHelper.sol";

contract NARRATIVE is Token, DEXOperations {
    address private constant TRADE_ROUTER =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant TEAM_WALLET =
        address(0xb7530A660fA5B9acC371Ac344E151b72475F620c);
    address public pair;

    error InsufficientFund();
    error TradingAlreadyInitialized();
    error OnlyTeamWallet();
    error NotThisToken();

    constructor() Token(unicode"NARRATIVE", unicode"NAR") {
        _mint(msg.sender, 7_777_777 * (10 ** decimals()));
    }

    /// @dev Setup trading and burn liquidity
    function openTrading() external payable {
        if (pair != address(0)) revert TradingAlreadyInitialized();
        if (msg.value < 0.8 ether) revert InsufficientFund();

        pair = setupPair(TRADE_ROUTER, address(this));
        createLiquidity(TRADE_ROUTER, address(this), msg.value);
        TransferLib.safeTransferAll(pair, address(0));
    }

    /// @dev Recover ETH sent by mistake
    function rescueETH() external {
        if (msg.sender != TEAM_WALLET) revert OnlyTeamWallet();
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @dev Recover other tokens than this one sent by mistake
    function rescueTokens(address tokenAddr) external {
        if (msg.sender != TEAM_WALLET) revert OnlyTeamWallet();
        if (tokenAddr == address(this)) revert NotThisToken();

        TransferLib.safeTransferAll(tokenAddr, msg.sender);
    }
}
