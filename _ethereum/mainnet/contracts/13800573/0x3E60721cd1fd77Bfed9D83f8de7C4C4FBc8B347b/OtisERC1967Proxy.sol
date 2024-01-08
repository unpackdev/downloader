// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/*                                                                                
   ____  __  _     
  / __ \/ /_(_)____
 / / / / __/ / ___/
/ /_/ / /_/ (__  ) 
\____/\__/_/____/  
                   

OTIS Minting Contract Proxy
*/

import "./ERC1967Proxy.sol";

contract OtisERC1967Proxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data)
        payable
        ERC1967Proxy(_logic, _data)
    {}
}
