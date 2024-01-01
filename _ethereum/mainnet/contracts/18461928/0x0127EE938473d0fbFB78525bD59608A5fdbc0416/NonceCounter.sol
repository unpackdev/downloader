// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./INonceCounter.sol";

contract NonceCounter is INonceCounter, OwnableUpgradeable, PausableUpgradeable {
    /* ----- Constants ----- */

    address public constant NATIVE_PLACEHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ----- State Variables ----- */

    mapping(address => bool) public isCrossChainRouter;
    mapping(uint16 => uint256) public outboundNonce;

    /* ----- Modifiers ----- */

    modifier onlyCrossChainRouter() {
        require(isCrossChainRouter[_msgSender()], "NonceCounter: not crossChainRouter");
        _;
    }

    /* ----- Constructor ----- */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ----- Functions ----- */

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function increment(uint16 dstChainId) external override onlyCrossChainRouter whenNotPaused returns (uint256) {
        return ++outboundNonce[dstChainId];
    }

    function setCrossChainRouter(address crossChainRouter, bool flag) external onlyOwner {
        isCrossChainRouter[crossChainRouter] = flag;
        emit CrossChainRouterUpdated(crossChainRouter, flag);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
