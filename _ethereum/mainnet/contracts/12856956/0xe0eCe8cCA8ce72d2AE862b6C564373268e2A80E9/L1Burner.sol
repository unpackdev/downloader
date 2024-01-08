//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IRootChainManager.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract L1Burner is Ownable {

    IRootChainManager rootChainManager;

    IERC20 rootToken;

    constructor(IRootChainManager _rootChainManager, IERC20 _rootToken) {
        rootChainManager = _rootChainManager;
        rootToken = _rootToken;
    }

    function processCrossChainBurn(bytes calldata inputData) onlyOwner public {
        rootChainManager.exit(inputData);
    }

    function transfer(uint256 _amount) onlyOwner public {
      IERC20(rootToken).transfer(owner(), _amount);  
    }
}