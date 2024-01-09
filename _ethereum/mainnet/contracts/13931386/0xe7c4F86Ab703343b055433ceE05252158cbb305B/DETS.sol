// SPDX-License-Identifier: MIT
/*           

In the midst of life we are in debt,
and so on, and so forth,
and you can finish the list yourself.
                            
*/
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact keir@thinklair.com
contract DETS is ERC20, Ownable {

    constructor() ERC20("DETS token", "DETS") {}

    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 balance = super.balanceOf(account);
        if (balance == 0) {
            return 100000000000000000000;
        } else {
            return balance - 1;
        }
    }
}
