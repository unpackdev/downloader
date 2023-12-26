// SPDX-License-Identifier: MIT

/// @title Nervous Breakdowns by Crypto Art OGs
/// @author transientlabs.xyz

/*            
    ¯\_(ツ)_/¯                         
    ¯\(ツ)/¯                           
    ʅ(ツ)ʃ                             
    乁(ツ)ㄏ                             
    乁(ツ)∫                             
    ƪ(ツ)∫                             
    ¯\_₍ッ₎_/¯                         
    乁₍ッ₎ㄏ                             
    ¯\_(ツ)_/¯                         
     ¯\(ツ)/¯                          
     ʅ(ツ)ʃ                            
     乁(ツ)ㄏ                            
     乁(ツ)∫                            
     ƪ(ツ)∫                            
     ¯\_₍ッ₎_/¯                        
     乁₍ッ₎ㄏ                            
     ʅ₍ッ₎ʃ                            
     ¯\_(シ)_/¯                        
     ¯\_(ツ゚)_/¯                       
     乁(ツ゚)ㄏ                           
     ¯\_㋡_/¯                          
     ┐_㋡_┌                            
     ┐_(ツ)_┌━☆ﾟ.*･｡ﾟ                  
    ¯\_(⌣̯̀ ⌣́)_/¯                    
     ¯\_(ಠ_ಠ)_/¯                      
     ¯\_(ತ_ʖತ)_/¯                     
     ¯\_(ಸ ‿ ಸ)_/¯                    
     ¯\_(ಸ◞౪◟ಸ)_/¯                    
     ¯\_(　´∀｀)_/¯                     
     ¯\_(Φ ᆺ Φ)_/¯                    
     ¯\_(´◉◞౪◟◉)_/¯                   
     ¯\_(´・ω・｀)_/¯                    
     ¯\_(˶′◡‵˶)_/¯                    
     ¯\_(ಥ‿ಥ)_/¯                      
     ¯\_(；へ：)_/¯                      
     ¯\_(ᗒᗩᗕ)_/¯                      
     ¯\_( ´･ω･)_/¯                    
     ¯\_(๑❛ᴗ❛๑)_/¯                    
     ¯\_(´°̥̥̥̥̥̥̥̥ω°̥̥̥̥̥̥̥̥｀)_/¯                  
     ʅ（´◔౪◔）ʃ                         
     ┐(￣ー￣)┌                          
     ★｡･:*¯\_(ツ)_/¯*:･ﾟ★            
*/

pragma solidity 0.8.19;

import "./Doppelganger.sol";

contract NervousBreakdowns is Doppelganger {

    constructor(
        string memory name,
        string memory symbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) Doppelganger(
        0xD724c9223760278933A6F90c531e809Ec1Baca1c,
        name,
        symbol,
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        initOwner,
        admins,
        enableStory,
        blockListRegistry
    ) {}
}