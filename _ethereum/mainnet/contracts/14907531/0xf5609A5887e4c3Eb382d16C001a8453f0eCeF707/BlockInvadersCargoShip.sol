pragma solidity 0.8.6;
// SPDX-License-Identifier: MIT
import "./Ownable.sol";

//
//
//                              ///                                      
//                           ////////                                    
//                         /////////////                                 
//                     //////////////////                               
//                   ///////////////////////                            
//                ////////////////////////////                          
//    &&&&&&&&&     ////////////////////////     &&&&&&&&&&             
//                     ///////////////////                              
//      &&&&&&&&&&&      //////////////      &&&&&&&&&&&&               
//      &&&&&&&&&&&&&&      /////////     &&&&&&&&&&&&&&&               
//                &&&&&&      ////      &&&&&&&                         
//                  &&&&&&&          &&&&&&&                            
//            &&&&&    &&&&&&      &&&&&&&   &&&&&                      
//               &&&&&   &&&&&&&&&&&&&&    &&&&&                        
//                 &&&&&    &&&&&&&&&   &&&&&                           
//                    &&&&&   &&&&    &&&&&                             
//                      &&&&&      &&&&&                                
//                         &&&&& &&&&&                                  
//                           &&&&&&                                     
//                             &&                                       
//                                                                      
//                                                                      
//                      &&&     &&&&&    &&                             
//                    &&   &&   &&   &&  &&                             
//                   &&     &&  &&&&&&&  &&                             
//                    &&   &&   &&&   && &&                             
//                      &&&     &&&& &&  &&            
//
//========================================================================
// ONCHAIN BLOCK INVADERS - Upgradable Colors Storage contract

contract BlockInvadersCargoShip is  Ownable {
    struct paintStruct{
        string[] eyesColor;
        string[] color;
        string[] backgroundColor;
        string[] colName;
        string   effect;
        string  chromaName;
    }
    mapping(uint256 => paintStruct) paint;
    
    event ColorStorred();


    constructor() Ownable() {

    //Light Pallete
    paint[0].eyesColor = ["JyM3NkE3QjMn", "JyNDM0U2REEn", "JyM3RjlBQzYn", "JyM4NjhCQjAn", "JyNEQkI2QUQn", "JyNGRkFDOTkn", "JyNGRkU4OTgn", "JyNFNjY1NEMn"];
    paint[0].colName = ["U2lsdmVy", "RGVzZXJ0", "U2VycGVudGluZSAg", "U29saXMg", "SmFkZSAg", "Q29iYWx0", "T2NlYW4g", "RW1lcmFsZCAg", "SmFzcGVy", "SW5kaWdv", "QXNo", "VGl0YW5pdW0g", "Q2FyYm9u", "U2NhcmxldCAg", "Q29yYWwg", "QnJhc3Mg", "QXp1cmUg", "Q3JpbXNvbiAg"];
    paint[0].color = ["JyNkOGUyZWIn", "JyNEQkI2QUQn", "JyM3QUI4QjIn", "JyNmYWQ5OGMn", "JyM2RTlDQTYn", "JyM3MDgzQUYn", "JyM1MDczOEYn", "JyNiOGQ5Y2Un", "JyNDRkFDQTMn", "JyM3Mzc3OTcn", "JyM5NDkzOEYn", "JyM3MzdCOEIn", "JyNDNkNDQ0Yn", "JyNmMmEzOTEn", "JyNGNENEQ0Qn", "JyNDQ0MzQUYn", "JyM3RjlBQzYn", "JyNEODYxNDgn"];
    paint[0].backgroundColor = ["JyNmNGU0ZDYn", "JyNlYWViZTUn", "JyNGMEVCRTkn", "JyNGREVERTcn", "JyNGMEUzRTMn", "JyNFQ0YyRkIn", "JyNGREZERTgn", "JyNGMkYyRjIn"];
    paint[0].effect = "PGZpbHRlciBpZD0nbmVvbicgeT0nLTInIHg9Jy0xJyB3aWR0aD0nMzUwJyBoZWlnaHQ9JzM1MCc+PGZlRHJvcFNoYWRvdyBmbG9vZC1jb2xvcj0nIzhBNzk1RCcgZHg9JzAnIGR5PSc2JyBmbG9vZC1vcGFjaXR5PScwLjY1JyBzdGREZXZpYXRpb249JzIuNScgcmVzdWx0PSdzaGFkb3cnLz48ZmVPZmZzZXQgaW49J1N0cm9rZVBhaW50JyBkeD0nMCcgZHk9JzIuNCcgcmVzdWx0PSdvZmZTdHJQbnQnLz48ZmVGbG9vZCBmbG9vZC1jb2xvcj0nIzRBNDEzMicgZmxvb2Qtb3BhY2l0eT0nMicgcmVzdWx0PSdmbG9vZDEnIC8+PGZlT2Zmc2V0IGluPSdTb3VyY2VHcmFwaGljJyBkeD0nMCcgZHk9JzInIHJlc3VsdD0nb2ZmRmxvb2QnLz48ZmVPZmZzZXQgaW49J1NvdXJjZUdyYXBoaWMnIGR4PScwJyBkeT0nOScgcmVzdWx0PSdvZmZTaGFkb3cnLz48ZmVDb21wb3NpdGUgaW49J2Zsb29kMScgaW4yPSdvZmZGbG9vZCcgb3BlcmF0b3I9J2luJyAgcmVzdWx0PSdjbXBGbG9vZCcgLz48ZmVDb21wb3NpdGUgaW49J3NoYWRvdycgaW4yPSdvZmZTaGFkb3cnIG9wZXJhdG9yPSdpbicgcmVzdWx0PSdjbXBTaGEnIC8+PGZlR2F1c3NpYW5CbHVyIGluPSdvZmZTdHJQbnQnIHN0ZERldmlhdGlvbj0nMScgcmVzdWx0PSdiU3Ryb2tlUCcvPjxmZUdhdXNzaWFuQmx1ciBpbj0nY21wRmxvb2QnIHN0ZERldmlhdGlvbj0nMC42JyByZXN1bHQ9J2JGbG9vZCcvPjxmZUdhdXNzaWFuQmx1ciBpbj0nY21wU2hhJyBzdGREZXZpYXRpb249JzAuNicgcmVzdWx0PSdiU2hhZG93Jy8+PGZlTWVyZ2U+PGZlTWVyZ2VOb2RlIGluPSdiU3Ryb2tlUCcvPjxmZU1lcmdlTm9kZSBpbj0nYnNoYWRvdycvPjxmZU1lcmdlTm9kZSBpbj0nYkZsb29kJy8+PGZlTWVyZ2VOb2RlIGluPSdTb3VyY2VHcmFwaGljJy8+PC9mZU1lcmdlPjwvZmlsdGVyPiAg";


    //Light side
    paint[0].chromaName = 'TGlnaHQgU2lkZSAg';
    }
    
    function isCargoShip() external pure returns (bool) {return true;}
    
    function loadChroma(string memory _chromaName,string[] memory _eyesColor,string[] memory _color,string[] memory _bkpcolor,string[] memory _colName,string memory _effect,uint256 idx ) external onlyOwner {
        
        paint[idx].eyesColor = _eyesColor;
        paint[idx].color = _color;
        paint[idx].backgroundColor = _bkpcolor;
        paint[idx].colName = _colName;
        paint[idx].effect = _effect;
        paint[idx].chromaName = _chromaName;
        emit ColorStorred();
    }
    function unloadChroma(uint256 idx) external view returns (string[] memory,string[] memory,string[] memory,string[] memory,string memory,string memory){
        return (paint[idx].eyesColor,paint[idx].color,paint[idx].backgroundColor,paint[idx].colName,paint[idx].effect,paint[idx].chromaName);
    }
}