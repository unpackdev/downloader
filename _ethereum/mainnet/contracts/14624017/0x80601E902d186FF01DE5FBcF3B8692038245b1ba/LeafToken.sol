// SPDX-License-Identifier: MIT

/******************************************************************************
                  .,felLLEEEAAALLFFLlef,.                  
              .:lLeLll:,',  : : : .;:llLLLe:.              
           .fAeLl;..  :  :  : i :  :  :  .,lAeAf.           
         ,lELf.....   :  :  :EAe:  :  :    ...:Ael,         
       ,AEl,..   ..,..:  : 'eFFA:  :  :....   ..'leA,       
     .lLA'.   ...:      .: AllAle' :      :.,..  .'lEl.     
    ;eE:.  ...:    .....: fAleLLAl.;.....     :...  .;ee;    
   fLL'  ..:   ....;     .eFAllEFL;     :.,..    :.  .ALf   
  fLA....,'  ..:     ....llFLl;LFAA....     :..  .;....ALf  
 ;LL.    lLA;:   ....:  .LFFe;'AFFL,  :....   :'eLA.   .LL: 
.eL;.....'EFlA:' :      ;LFFL,.lAFll      : .;lAFA:.....,Ee.
lAe       fllELlel' ....flFFL,.lAFAl.... .fLAAEAAl.      eAl
LL;........eeLAAlAlL:.  flFFL'.lAFAl.  ,AAAAlALeA........;LL
Ee.        .:LFALEAFAL' :AFFL,.lAFAe .elFlLLlFle.        .eL
LL...........fLFALLLAAe.'EFFe,.lFFl:.llleAEAFll...........eA
Le.          :'lAAlLlALl'AFFE:,AFFE,fLLllAFlL;:          .eA
EL;.......,  :  .fLLel::'flFLl:eFAl';:fLLee,  :  ,.......,LE
lle       :  : ..';fee;. .LFALlEFL,  ,ell;,'. :  :       lll
,LE,...,  :.,feLAALELe:...;LAALlll...;lAELAlEll;.:  ,...'eL;
 elA.  .;lLLEEEeeEEeLlf,.  llFAAA. .,:eLeELEeEEELee;'. .lle.
 .Lle..:leELLeLLAlAef:eAl;;'eAlL,,;fAlffeAlAAeALALeAf'.eAL. 
  .Lll.   :    :..  .eAeALA..',. eLAeAA'   ..:   :   .lAL.  
   .AAe,  :...   :. feEeEe;      .AEeEEl. .:   ..:  'LAA.   
    .fLLe.   :.,  :.ALLEl'....,....lELLe,.:  ..:  .lLLl.    
      'AAEl.   :.. .eAe:..,   :   ,.,LlL;  ..:  .lEAA'      
        ,AALl;.  :..;;.   :   :   :   ,;..:  .,lLAA,        
          'eEAEl:.    :   :   :   :   :   .;lEAEe'          
            .,lLLLell;'.. :   :   :..';lleLLLl,.            
                .;lAeLLLEeLLAAAALLeELLLeAl;.                
                    ..;llLeEEELLEeLll;'.                    

        _______ _______ _______ _______  _____  _____ __   _
 |      |______ |_____| |______ |       |     |   |   | \  |
 |_____ |______ |     | |       |_____  |_____| __|__ |  \_|
*******************************************************************************/    

pragma solidity ^0.8.0;

import "./ERC1363.sol";

contract LeafToken is ERC1363 {
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 420e9 * (10**uint256(_decimals)); //420,000,000,000

    constructor() ERC20("LeafCoin", "LEAF") {
        _mint(msg.sender, _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}