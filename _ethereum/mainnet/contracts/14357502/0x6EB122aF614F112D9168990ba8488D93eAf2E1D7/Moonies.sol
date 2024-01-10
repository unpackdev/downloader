// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
                                                                                                                                                
                                                                                                                                                
MMMMMMMM               MMMMMMMM     OOOOOOOOO          OOOOOOOOO     NNNNNNNN        NNNNNNNNIIIIIIIIIIEEEEEEEEEEEEEEEEEEEEEE   SSSSSSSSSSSSSSS 
M:::::::M             M:::::::M   OO:::::::::OO      OO:::::::::OO   N:::::::N       N::::::NI::::::::IE::::::::::::::::::::E SS:::::::::::::::S
M::::::::M           M::::::::M OO:::::::::::::OO  OO:::::::::::::OO N::::::::N      N::::::NI::::::::IE::::::::::::::::::::ES:::::SSSSSS::::::S
M:::::::::M         M:::::::::MO:::::::OOO:::::::OO:::::::OOO:::::::ON:::::::::N     N::::::NII::::::IIEE::::::EEEEEEEEE::::ES:::::S     SSSSSSS
M::::::::::M       M::::::::::MO::::::O   O::::::OO::::::O   O::::::ON::::::::::N    N::::::N  I::::I    E:::::E       EEEEEES:::::S            
M:::::::::::M     M:::::::::::MO:::::O     O:::::OO:::::O     O:::::ON:::::::::::N   N::::::N  I::::I    E:::::E             S:::::S            
M:::::::M::::M   M::::M:::::::MO:::::O     O:::::OO:::::O     O:::::ON:::::::N::::N  N::::::N  I::::I    E::::::EEEEEEEEEE    S::::SSSS         
M::::::M M::::M M::::M M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N N::::N N::::::N  I::::I    E:::::::::::::::E     SS::::::SSSSS    
M::::::M  M::::M::::M  M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N  N::::N:::::::N  I::::I    E:::::::::::::::E       SSS::::::::SS  
M::::::M   M:::::::M   M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N   N:::::::::::N  I::::I    E::::::EEEEEEEEEE          SSSSSS::::S 
M::::::M    M:::::M    M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N    N::::::::::N  I::::I    E:::::E                         S:::::S
M::::::M     MMMMM     M::::::MO::::::O   O::::::OO::::::O   O::::::ON::::::N     N:::::::::N  I::::I    E:::::E       EEEEEE            S:::::S
M::::::M               M::::::MO:::::::OOO:::::::OO:::::::OOO:::::::ON::::::N      N::::::::NII::::::IIEE::::::EEEEEEEE:::::ESSSSSSS     S:::::S
M::::::M               M::::::M OO:::::::::::::OO  OO:::::::::::::OO N::::::N       N:::::::NI::::::::IE::::::::::::::::::::ES::::::SSSSSS:::::S
M::::::M               M::::::M   OO:::::::::OO      OO:::::::::OO   N::::::N        N::::::NI::::::::IE::::::::::::::::::::ES:::::::::::::::SS 
MMMMMMMM               MMMMMMMM     OOOOOOOOO          OOOOOOOOO     NNNNNNNN         NNNNNNNIIIIIIIIIIEEEEEEEEEEEEEEEEEEEEEE SSSSSSSSSSSSSSS   
                                                                                                                                                
                                                            by coinmoonbase.com                                                                                   
                                                                                                                                                
*/

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";

contract Moonies is Initializable, ERC20Upgradeable {
    function initialize() public initializer {
        __ERC20_init('Moonies', 'MOONIES');
        // Initially mint 1'000'000'000'000 to the creator contract
        _mint(msg.sender, 1000000000000 * 10**decimals());
    }
}
