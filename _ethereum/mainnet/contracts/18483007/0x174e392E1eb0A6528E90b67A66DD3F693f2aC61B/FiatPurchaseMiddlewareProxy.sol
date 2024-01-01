// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IPresalePurchases.sol";
import "./Storage.sol";

contract FiatPurchaseMiddlewareProxy is Ownable, Storage {
    address public activeImplementation;

    constructor(address _activeImplementation) Ownable(msg.sender) {
        activeImplementation = _activeImplementation;
    }

    function upgrade(address _newImplementation) public onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation address");
        activeImplementation = _newImplementation;
        _initialized = false;
    }

    fallback(bytes calldata inputs) external returns(bytes memory) {
        address implementation = activeImplementation;
        require(implementation != address(0), "Invalid implementation address");
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
        if (success) {
            return data;
        } else {
            revert(string(data));
        }
    }
}
