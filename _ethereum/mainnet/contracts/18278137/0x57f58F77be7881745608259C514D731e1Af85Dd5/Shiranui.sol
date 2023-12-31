
/*
    Mai Shiranui - SHIRANUI
    
    Social Media:
    Website  :  https://maishiranui.com	
    Telegram :  https://t.me/MaiShiranuiEntry	
    Twitter  :  https://twitter.com/Shiranui_ERC20

                                       7##P5PBBB#&BJ~:.                                             
              .....:::::...:..        ^&&#BBBGGBB#&&B5?!^:                                          
           ..:^:::...:::...::^::::.   ?&&&B#J!5#BB&&&&#BGPY77!~^:.........                          
       .:::::..     ....  ....  .:^^: !&&&&B!GGBYP&&&&&&#BBB##&#GY!:.:..                            
     .::..   ...    .... .:.. .:::....^P&&&&BPPGGP5GBB####BBB####&&G?:   ...:.                      
  .^:.......  ...   ... .:.. .::.....:^^?J5####BG5PGBB##&#&&#####GB##B55J7!^.                       
 :^........... ...  ... ....::....:^^::...:B&&&##GPGGB#GG&#&&###&Y:::::^:                           
^?J?7^:..........  ..:.::..:...::^:... ...:?&BBBGGGP5Y!^~P##&&###&?.                                
..:~!?J?7~^.....:!!?7J??~?~:.:::.....:::^^^^P5G##BB#Y~::~JB#&#G##B5^                                
     .:^!7J??!^7?YJY!!77Y???~...::^^^^^^^::.!G###?~7~^:75PB#&BP&&?7^.                               
          .:~7??JYP7~?GPYJ??J!^^^:::..       7&GJ~^^::^?5B&&&#PYY~~.                                
                :^?775Y?JJ~. ..       .:::::^7GJJ?~^!???JPP#@BY?!~~^^^^:..                          
                  !GBG55JY7          :~~~~7?P?~7?Y5?~:. .~:~?7~7?J?7~~^^~~~^.                       
                   ~5###B5J~        ^~^:^~!7?P5~~?PP?^....       :!JJ?7~~^^~!~.                     
                     ~?G#BPGY^     :~:^~!????JPP?^!JJ?J?7!!!!~~^^^~!JYYJ?7!7?77.                    
                       ?&#&&&#^   .~^^!7?JJJJ??PP5~:!!!?JJJJJ?7!!!7??JYY5YYJ?!:                     
                       JB###GY^  :~:^~7JJJ??7777P557.~!!!!77?JY5YJJJJ?7!~^:.                        
                        .:JYJ!~~:~:^~7J?J??!^7?7YP55Y:^77~::^~7J5^..                                
                          ^Y?~^~7!~~7J7.~J?!!???JGBGBP~7J?~^~~7!5J                                  
                          .JJ7~^!JJJJ~  .??777?JYGBBB#G?YYJ??JYJBY                                  
                           ~YJ?!7JY?:    :?77!7?P######PJ55YYYYGB~                                  
                            ~?J?JJ~       ^?77!JBB######5J555P#P^                                   
                              :^^.         ^?7?GBB######BY5PBB?.                                    
                                            ^JPBBB####BGPGB#5.                                      
                              .............:^PPPPGGB####&&##7                                       
                       .^::::::.......:^~!?J5P55PPGBB#######J     

    She embodies the very essence of domination and desire. 
    As she sways and sashays, each move is a dance of power, 
    precision, and raw passion. In the sprawling metropolis of 
    digital currencies, Mai doesn't merely exist, she rules. 
    Enter the world of SHIRANUI, where her essence is infused into every facet.

    This token captures the allure of Mai's seductive prowess, 
    her relentless determination, and her captivating charisma. 
    But there's more than what meets the eye. Behind the entrancing dance 
    and the flirtatious smiles lies the heart of a warrior, unyielding and fierce. 
    
    SHIRANUI isn't just another token;it's an embodiment of Mai's spirit, 
    a reflection of her unquenchable fire. A world where every trade, every move, 
    every decision is driven with the same intensity, ferocity, 
    and intent that Mai brings to every battle.

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract Shiranui is ERC20 { 
    constructor() ERC20("Mai Shiranui", "SHIRANUI") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}