pragma solidity ^0.5.16;

import "./Initializable.sol";
// import "./Initializable.sol";
import "./Ownable.sol";
import "./UniversalERC20.sol";


contract FundsManager is Initializable, Ownable {
    using UniversalERC20 for IToken;

    // Initializer – Constructor for Upgradable contracts
    function initialize() public initializer {
        Ownable.initialize();  // Initialize Parent Contract
    }

    function initialize(address payable newOwner) public initializer {
        Ownable.initialize(newOwner);  // Initialize Parent Contract
    }


    function withdraw(address token, uint256 amount) public onlyOwner {
        if (token == address(0x0)) {
            owner.transfer(amount);
        } else {
            IToken(token).universalTransfer(owner, amount);
        }
    }

    function withdrawAll(address[] memory tokens) public onlyOwner {
        for(uint256 i = 0; i < tokens.length;i++) {
            withdraw(tokens[i], IToken(tokens[i]).universalBalanceOf(address(this)));
        }
    }

    uint256[50] private ______gap;
}