/*
WELCOME TO $CLOUD
Cloud Chuckle kept on floating by, as he drifted, he changed. 
Bigger and fuller. 
Soon he just couldn't hold it in. He burst into tears. 
Laughing and crying he melted away, filling the cracks in the dry earth below. 
It felt good to merge with a sprout.

W : https://cloudchuckle.com/
TG: https://t.me/CloudChucklePortal
X : https://twitter.com/CloudChuckle
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract CLOUD is ERC20 {
    constructor() ERC20("Cloud Chuckle","CLOUD") { 
        _mint(msg.sender, 420_690_000 * 10**18);
    }
}