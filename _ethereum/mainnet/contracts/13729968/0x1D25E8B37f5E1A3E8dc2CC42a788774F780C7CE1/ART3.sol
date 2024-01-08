//                                                                                
//                                                                                
//                                                                                
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@              @@@@@@@@       @@@@@@@@              @@@@@@@@      
//       @@@@@@@@              @@@@@@@@       @@@@@@@@              @@@@@@@@      
//       @@@@@@@@              @@@@@@@@       @@@@@@@@              @@@@@@@@      
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@              @@@@@@@@       @@@@@@@@            @@@@@@@@/       
//       @@@@@@@@              @@@@@@@@       @@@@@@@@             @@@@@@@@@      
//       @@@@@@@@              @@@@@@@@       @@@@@@@@              @@@@@@@@      
//                                                                                
//                                                                                
//                                                                                
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                  @@@@@@@@                                   (@@@@@@@@@@%       
//                  @@@@@@@@                                 @@@@@@@@@@@          
//                  @@@@@@@@                               @@@@@@@@@@@@@@@@@      
//                  @@@@@@@@                               @@@@@@@@@@@@@@@@@      
//                  @@@@@@@@                               @@@@@@@@@@@@@@@@@      
//                  @@@@@@@@                  @@@@@@@@              @@@@@@@@      
//                  @@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                  @@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                  @@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      
//                                                                                
//                                                                                                                                                   
//                                               
//
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./console.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract ART3 is ERC20, Ownable {
    bool public transfersEnabled;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public ERC20("ART3", "ART3") {
        _mint(msg.sender, 1000000000000000);
        transfersEnabled = false;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(transfersEnabled || _msgSender() == owner(), "Transfers aren't enabled");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(transfersEnabled || _msgSender() == owner(), "Transfers aren't enabled");
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(transfersEnabled || _msgSender() == owner(), "Transfers aren't enabled");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function enableTransfers(bool _transfersEnabled) onlyOwner public {
        transfersEnabled = _transfersEnabled;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}