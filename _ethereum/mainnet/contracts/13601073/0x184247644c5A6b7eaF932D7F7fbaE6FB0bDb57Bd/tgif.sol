// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/*


TTTTTTTTTTTTTTTTTTTTTTT        GGGGGGGGGGGGGIIIIIIIIIIFFFFFFFFFFFFFFFFFFFFFF
T:::::::::::::::::::::T     GGG::::::::::::GI::::::::IF::::::::::::::::::::F
T:::::::::::::::::::::T   GG:::::::::::::::GI::::::::IF::::::::::::::::::::F
T:::::TT:::::::TT:::::T  G:::::GGGGGGGG::::GII::::::IIFF::::::FFFFFFFFF::::F
TTTTTT  T:::::T  TTTTTT G:::::G       GGGGGG  I::::I    F:::::F       FFFFFF
        T:::::T        G:::::G                I::::I    F:::::F             
        T:::::T        G:::::G                I::::I    F::::::FFFFFFFFFF   
        T:::::T        G:::::G    GGGGGGGGGG  I::::I    F:::::::::::::::F   
        T:::::T        G:::::G    G::::::::G  I::::I    F:::::::::::::::F   
        T:::::T        G:::::G    GGGGG::::G  I::::I    F::::::FFFFFFFFFF   
        T:::::T        G:::::G        G::::G  I::::I    F:::::F             
       T:::::T         G:::::G       G::::G  I::::I    F:::::F             
      TT:::::::TT        G:::::GGGGGGGG::::GII::::::IIFF:::::::FF           
      T:::::::::T         GG:::::::::::::::GI::::::::IF::::::::FF           
      T:::::::::T           GGG::::::GGG:::GI::::::::IF::::::::FF           
      TTTTTTTTTTT              GGGGGG   GGGGIIIIIIIIIIFFFFFFFFFFF           

    
    1. TGIF.
    2. Mondays burn.
    3. No more 9-to-5.


*/                                                               


contract TGIF is ERC20, ERC20Burnable {
    constructor() ERC20("TGIF", "TGIF") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}