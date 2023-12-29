// SPDX-License-Identifier: MIT
/*

 _______       __       ___      ___  _______   __          ______        __        ________  __    __   
|   _  "\     /""\     |"  \    /"  ||   _  "\ |" \        /" _  "\      /""\      /"       )/" |  | "\  
(. |_)  :)   /    \     \   \  //   |(. |_)  :)||  |      (: ( \___)    /    \    (:   \___/(:  (__)  :) 
|:     \/   /' /\  \    /\\  \/.    ||:     \/ |:  |       \/ \        /' /\  \    \___  \   \/      \/  
(|  _  \\  //  __'  \  |: \.        |(|  _  \\ |.  |       //  \ _    //  __'  \    __/  \\  //  __  \\  
|: |_)  :)/   /  \\  \ |.  \    /:  ||: |_)  :)/\  |\     (:   _) \  /   /  \\  \  /" \   :)(:  (  )  :) 
(_______/(___/    \___)|___|\__/|___|(_______/(__\_|_)     \_______)(___/    \___)(_______/  \__|  |__/  
       
       
       https://t.me/bambicash
       Twitter: @bambicashcrypto
    https://bambi.cash/
                                                                                                         

*/

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./Ownable.sol";

contract Bambi is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {
    constructor() ERC20("Bambi", "BAM") ERC20Permit("Bambi") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}