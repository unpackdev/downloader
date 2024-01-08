pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";


/*
*    .oooooo.                                oooo                       .o88o. oooooooooo.                  .o88o.  o8o
*   d8P'  `Y8b                               `888                       888 `" `888'   `Y8b                 888 `"  `"'
*  888      888 oooo d8b  .oooo.    .ooooo.   888   .ooooo.   .ooooo.  o888oo   888      888  .ooooo.      o888oo  oooo
*  888      888 `888""8P `P  )88b  d88' `"Y8  888  d88' `88b d88' `88b  888     888      888 d88' `88b      888    `888
*  888      888  888      .oP"888  888        888  888ooo888 888   888  888     888      888 888ooo888      888     888
*  `88b    d88'  888     d8(  888  888   .o8  888  888    .o 888   888  888     888     d88' 888    .o .o.  888     888
*   `Y8bood8P'  d888b    `Y888""8o `Y8bod8P' o888o `Y8bod8P' `Y8bod8P' o888o   o888bood8P'   `Y8bod8P' Y8P o888o   o888o
*                                                                                                  
*
* This is the beta token for oracleofde.fi project.
* For more information about the projects check out https://oracleofde.fi or its Docs on
* https://docs.oracleofde.fi.
*
* Follow us on Twitter on https://twitter.com/oracleofde_fi
*/

contract ODFBeta is Ownable, ERC20 {

    mapping(address => bool) public allowedSenders;

    constructor() ERC20("OracleofDe.fi Beta", "ODF-Beta"){
        allowedSenders[msg.sender] = true;
        _mint(msg.sender, 100000000000000000000);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(_validSender(from), "Only whitelisted senders can send ODFBeta token");
    }

    function _validSender(address from) private view returns (bool) {
        return allowedSenders[from] || from == address(0);
    }
}
