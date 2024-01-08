//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IRootChainManager.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract L1Burner is Ownable {

    IRootChainManager rootChainManager;

    ERC20Burnable rootToken;

    constructor(IRootChainManager _rootChainManager, ERC20Burnable _rootToken) {
        rootChainManager = _rootChainManager;
        rootToken = _rootToken;
    }

    function processCrossChainBurn(bytes calldata inputData) onlyOwner public {
        rootChainManager.exit(inputData);
        uint256 amount = ERC20Burnable(rootToken).balanceOf(address(this));
        rootToken.burn(amount);
    }

    function transfer(uint256 _amount) onlyOwner public {
      ERC20Burnable(rootToken).transfer(owner(), _amount);  
    }
}