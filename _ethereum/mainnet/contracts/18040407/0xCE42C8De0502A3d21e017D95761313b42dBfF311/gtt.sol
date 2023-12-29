// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract GreateTicket is ERC20 {
    address internal _metaTxProcessor;

    constructor(address metaTxProcessor) ERC20("Great E Ticket", "GET") {
        _mint(msg.sender, 100000000000);

        _metaTxProcessor = metaTxProcessor;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function isValidSender(address from) internal view returns(bool) {
        return from == address(0) || _msgSender() == from || isMetaTx();
    }

    function isMetaTx() internal view returns(bool) {
        return _msgSender() == _metaTxProcessor;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual { 
         // 当mint的时候from是给0地址，目标地址会是发送地址
         require(isValidSender(from), "NOT_AUTHORIZED");
         require(from != address(0) || to != address(0), "both from and to were zero address");
         require(amount != 0, "amount equal zero");
     }

     function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        if(!isMetaTx())
        {
            uint256 allowAmt = allowance(sender, _msgSender());
            require(allowAmt >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), amount);
        }
        return true;
    }
}