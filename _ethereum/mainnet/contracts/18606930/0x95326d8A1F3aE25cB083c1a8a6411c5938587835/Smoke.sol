// SPDX-License-Identifier: MIT

/*
                             888              
                             888              
                             888              
.d8888b 88888b.d88b.  .d88b. 888  888 .d88b.  
88K     888 "888 "88bd88""88b888 .88Pd8P  Y8b 
"Y8888b.888  888  888888  888888888K 88888888 
     X88888  888  888Y88..88P888 "88bY8b.     
 88888P'888  888  888 "Y88P" 888  888 "Y8888  
 
*/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

// Need to Burn for more $moke
contract Smoke is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("$moke", "MOKE")
        ERC20Permit("$moke")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 42019711020 * 10 ** decimals());
    }
}
/*
                                       _
     |_|       |  |_/            _  _ (_)    _  |
     | | (` \) .  | \ (` (` |)  (_ (_)   ,-.(_) | o o o
            /               |            `-'
               _
              (_)            *
   .|,    *              O
   -x-
   '|`       \ \ |//             |           *
         ( %%%)%%%/%%%   %      -+-     O
     _   %\%%%%%%%%(%%%%%/       |
      %%%%%%%%%%)%%%)%(%%\         _
       %%/ __^_   _^__ \%%%       (_)    _|_          )
      |"\=(((@))=((@)))=/"|%              |     (
     %\_( ,`--'(_)`--'. )_/ %                    \  )
    /%%( /______I______\ )%  )                    )  ,
  _/%%%%\\\_|_|_|_|_|_///%%%       ,----.-._     (  /
    %% %%\ `|_|_|_|_|' /%\%%\     /  __  `.``.    \(
  -%% %%%%`---.___,---'%%%%  )   /  / _`.__))))____`
   (  %% %             %%  \       ( @)__,._      :%##
      %                 %           \  .'  )`-----.%##
      /                              `'  ,'

 -- ZZ
*/
