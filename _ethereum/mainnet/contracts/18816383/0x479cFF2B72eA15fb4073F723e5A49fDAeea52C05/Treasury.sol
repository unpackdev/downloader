// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./SafeERC20.sol";
import "./UUPSUpgradeable.sol";

import "./Whitelist.sol";

contract Treasury is UUPSUpgradeable, Whitelist {
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor() {
        _disableInitializers();
    }

    function initialize(address token_addr) external initializer {
        require(token_addr != address(0), 'Treasury: non-zero address required');
        token = IERC20(token_addr);

        __Ownable_init(_msgSender());
    }

    function withdraw(uint256 _amount) external onlyWhitelisted {
        token.safeTransfer(_msgSender(), _amount);
    }

    function withdrawTo(address _to, uint256 _amount) external onlyWhitelisted {
        require(_to != address(0), "address must be non-zero");
        token.safeTransfer(_to, _amount);
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
