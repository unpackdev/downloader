// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/** A big thanks to everyone at OpenZeppelin 👏👏👏 */
import "./ERC20.sol";

/**
                                                                        ╓▌
                                    ,▄▓▓▓▓▓▓▄▄▓▓▓▄▓███▀▓▀█▌_           ▄██▄
                                   ]█▌░▒▒╠╠╠╬█▓╣╟█▄▒▒▒▒▒▒▄█           ▓█▓██
                                    ╙█████▀▀▀╟███▌╙▀▀▀▀▀▀╙          ,██▓▓▓██
                           ,╓▄▄▄╖          ,╓▓█╬█▌        ▄▓▓▓▄▄,  ╓█▓▓▓▓▓█▌
                       ╓▓██▀╙└,╫█▌    ,▄▓████▀██████▄,    ██▄ ╙▌█▓▓█▓▓▓▓▓█▀
                  ,▄▓█▀▀─▐█▄▄█▀`    ▄███▀─    ╓▄▄▄▄████▄    ╙█▓╬╦▓█╫▓▓▓▓█╙
               ╓▓█▀╙ ╓#▒╬╬╬╢█▌    ▄██▀_  ,▄▓█████████████    ▓█╣██╣▓▓╬██▌
             ▄█▀─,φ▒╠╬╬╬╬╬╬██    ▓██▒  ╓▓████▓▓▓▓▓▓▓▓▓▄╙██µ  ▐██▌▓╬╬╬██ ▓█_
           ,▓█_╓▒╠╬╬╬╬╬╬╬╬╣╬█▌  ███░░_▄█████▓▓▓▓██▓▓▓╣██╙██µ╓██╬▓╬╬╣██▓╬ε╟█_
          ,█▀,╬╠▓█╬╬╬╬╬╬╣▓▓▓╬█████░▒_▐██████▓▓▓███▓▓▓╣██⌐╙████╔╬╬╬▓█╬╬▓██▒▓█_
          █▌╔╬▓██▓╬╬╬╬╣▓▓▓▓▓▓▓███░░▒_▓██████▓▓▓▓██▓▓▓▓██▒ ██▌φ╬╬╬▓█▓╬╬╬███╠█▌
         ▓█á╣█▓█▓╬╬╣╣▓▓▓▓▓▓████████▓▄╚███████▓▓▓▓▓▓▓▓╬╬▓▓▄▓▀╬╠╠╠▓▓▓▓▓▓╬╬██▓▓█
         █▌╬▓███╬╬╣╬▓▓▓▓▓████╬╬╠╠,╙▀██▌▀▀████████████████▓░╠╠╠╟▓▓█▓████▓▓█▀█▀
        ▐█▒▓█╫█╬╣╣██▀██▓███╬╬╠▒░░░╔  ██▌               ▓▓╓╠╠╠╫▓▓███▓███▓██
         ▀▀╙  █▓╣▓██▄▓█▓██╬╬╬╬▒▒▒░░_ ▐██▓▀▓█▓▓▓▓▓▓▓Γ  ]▀╔╠╠╠╣╬███████████
              ╙██╬╣███▓▓█████▓▓▓▓▓▓▓████╬╬╠╠╠▒▄╬╬╬╣▓╣▌╜φ╠╠╠╣▓╙╙███████╙╙
                ▀███╨████████████▓▀▀╬▓██▓▓▓╬▓█╬╬▒▒▒╫╬▌╬╬╠╬╬µ ` ,⌠████▌
                     ╟█▓███▓██╬╬╬╬╠▒╬╬▀▀▀████▌╙╙▓▓▄╬╣▓▓▓▓▓▓▄µ≥░░φ╟███⌐
                      ▓█▓██_███╬╬╣╬╠╠▒╠╠╠╠███╬░░└└╙▀█▓╬▀▓▒░╠▀█▓╬╬▓███
                       ▓███_ ▀███▓╬╣╣╬╬╬╬╠██▌╬▒░░│││'╙▀██▄▒░▓█╬╬▓██¬
                        ▀██    ▐█████████████╬╬╠▒░░░░░░░│╠███▓███▀
                               ███╬╬╬╬╬╬▀▀▀███▒╬╬╬╠╠╠╠╠╠╬██████_
                             ╒█╙█▓▓╬▒▒▒▒▒▒▒▓████▓▓▓▓▓▓▓████▄▓██µ
                             ╙█╓███████████▌ ╟█▌▀▀█▀▀███████▀██▌
                              ██▒╬▒░││││││╙█▄██   █▄▄█▒░░││││╫██
                            ╓▓███▓█▓▄││││││'██▌    ██▌╬▒░││'▄▓██
                          ,███╬╩░░│'╙▀▄'││││██▌    ██▌╬▒░▄▓▀╙╙▀███╖
                          ███▒╬░░│││││└▀│││╓██⌐    ╟██▄▒╠▄▄▄▄▄▄▄▓██
                           ▀█████████████████▀      ╙▀████████▀▀▀╙
                                  └└└└└─

    ____            _     ___     __                 
    | __ )  __ _ ___| |__ (_) \   / /__ _ __ ___  ___ 
    |  _ \ / _` / __| '_ \| |\ \ / / _ \ '__/ __|/ _ \
    | |_) | (_| \__ \ | | | | \ V /  __/ |  \__ \  __/
    |____/ \__,_|___/_| |_|_|  \_/ \___|_|  |___/\___|

    PREAMBLE

    The black sun exudes vibrance beyond that of all horizons combined. Being 
    neither a star nor planet, some call it the nebulous gateway serving as the 
    bridge between our world and the high heavens, the digital galaxy of 
    BashiVerse built with ❤ and courage by Outer Heaven.

    MISSION

    The world is changing... Are you ready for what is coming? This is a call to
    all who want to change it for the better. We are without borders and our 
    purpose defined by the era we live in. The end game is to establish our 
    community in what will soon become the early days of the MegaVerse.

    In all, Truth prevails. Meet us at https://www.outerheaven.foundation/

    - 0xBigBoss
    - 0xJuggernaut

    BashiVerseCore

    A humble beginning... A simple ERC20 contract to be the jetfuel for our 
    mission. All other contracts in the BashiVerse will be developed from this.

    A fixed supply of 1_337_000_000, this ERC20 contract is as vanilla as it gets.
    It aims to be the currency of the BashiVerse.

    @title BashiVerse Core ERC20 Token
    @author 0xBigBoss
    @custom:security-contact 0xbigboss@protonmail.com
*/
contract BashiVerseCore is ERC20 {
    constructor() ERC20("BashiVerse Core Token", "BVX") {
        _mint(msg.sender, 1_337_000_000 * 10**decimals());
    }
}
