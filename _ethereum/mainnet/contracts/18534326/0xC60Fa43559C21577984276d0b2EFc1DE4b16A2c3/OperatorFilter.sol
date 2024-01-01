// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

/**
 * @dev an operator filter inspired by https://github.com/ProjectOpenSea/operator-filter-registry/tree/main
 * will allow NFT contracts to filter out all but specific marketplace operators with toggleable functionality
 */
abstract contract OperatorFilter is Ownable {
    bool public operatorFilterIsActive = false;

    mapping(address => bool) operatorRegistry;

    constructor() {}

    modifier onlyAllowedOperator(address from) {
        if (operatorFilterIsActive) {
            if (from != _msgSender()) {
                _checkFilter(_msgSender());
            }
        }
        _;
    }

    function _checkFilter(address from) internal view {
        require(operatorRegistry[from], "Operator is not in registry");
    }

    function addToRegistry(address operator) public onlyOwner {
        operatorRegistry[operator] = true;
    }

    function removeFromRegistry(address operator) public onlyOwner {
        operatorRegistry[operator] = false;
    }

    function toggleOperatorFilterActive(bool active) public onlyOwner {
        operatorFilterIsActive = active;
    }
}
