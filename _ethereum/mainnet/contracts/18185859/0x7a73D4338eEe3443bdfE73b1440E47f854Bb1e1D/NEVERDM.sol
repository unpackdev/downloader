/*
NEVER DM YOU FIRST, I MEAN NEVER

$$\   $$\ $$$$$$$$\ $$\    $$\ $$$$$$$$\ $$$$$$$\        $$$$$$$\  $$\      $$\ 
$$$\  $$ |$$  _____|$$ |   $$ |$$  _____|$$  __$$\       $$  __$$\ $$$\    $$$ |
$$$$\ $$ |$$ |      $$ |   $$ |$$ |      $$ |  $$ |      $$ |  $$ |$$$$\  $$$$ |
$$ $$\$$ |$$$$$\    \$$\  $$  |$$$$$\    $$$$$$$  |      $$ |  $$ |$$\$$\$$ $$ |
$$ \$$$$ |$$  __|    \$$\$$  / $$  __|   $$  __$$<       $$ |  $$ |$$ \$$$  $$ |
$$ |\$$$ |$$ |        \$$$  /  $$ |      $$ |  $$ |      $$ |  $$ |$$ |\$  /$$ |
$$ | \$$ |$$$$$$$$\    \$  /   $$$$$$$$\ $$ |  $$ |      $$$$$$$  |$$ | \_/ $$ |
\__|  \__|\________|    \_/    \________|\__|  \__|      \_______/ \__|     \__|
                                                                                
                                                                                
                                                                                
https://neverdm.com	 https://t.me/NEVERDMYOUFIRSTPortal	 https://twitter.com/NEVERDM_
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract NEVERDMYOUFIRST is ERC20 {
    constructor() ERC20("NEVER DM YOU FIRST", "NEVERDM") {
        _mint(msg.sender, 69_000_000_000 * 10**18);
    }
}