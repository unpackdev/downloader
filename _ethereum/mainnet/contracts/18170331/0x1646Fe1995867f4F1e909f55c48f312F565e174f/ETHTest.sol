
      // SPDX-License-Identifier: MIT
      pragma solidity ^0.8.18;
      import "./SevenArtProxy.sol";
      
       
// 
// 
//  ________  ________   ______   ________ 
// /        |/        | /      \ /        |
// $$$$$$$$/ $$$$$$$$/ /$$$$$$  |$$$$$$$$/ 
//    $$ |   $$ |__    $$ \__$$/    $$ |   
//    $$ |   $$    |   $$      \    $$ |   
//    $$ |   $$$$$/     $$$$$$  |   $$ |   
//    $$ |   $$ |_____ /  \__$$ |   $$ |   
//    $$ |   $$       |$$    $$/    $$ |   
//    $$/    $$$$$$$$/  $$$$$$/     $$/    
//                                         
//                                         
//                                         
// 
// 
// 
      
      contract ETHTest is SevenArtProxy {
        constructor(
            address _sevenArtBase1155Slim,
            address sevenArt
        ) SevenArtProxy(_sevenArtBase1155Slim, sevenArt) {}
      }
      