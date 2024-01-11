// SPDX-License-Identifier: MIT
 
//                                                       *,                                 @@@@@@@@               
//                                                   @@@@  *@.     @@@@@@@@     @@@@@@@@@   (@@    @@@@            
//                                                 @@@           @@@      @@@ @@@      @@@  %@@      @@@           
//                                                @@@    ,@@@&   @@       @@@ @@       %@@  /@@       @@           
//                                                @@@    .   @@@ @@.      @@@ @@@      @@@  ,@@      @@@           
//                                                 @@@       @@@  @@@. #@@@&   @@@@@@@@@*    @@ *@@@@@             
//               &@@         @@@                    .@@@@@@@@@      .@@@#                    @@@@                  
//               @@@        @@@                                                                                    
//  @@%          @@@      .@@@         (@@@      @@       @@@     @@   @@@      @@&  @@@@@@@      @@@@@@@@%        
//  @@@          @@@      @@@        @@@@       @@@@@   @@@@@#    @@   @@@@@    @@   @@   ,@@@   @@/               
//   @@@                           @@@@        ,@@ %@@@@@@ @@@    @@&  @@&@@@# @@@   @@     @@@  @@@@@@%           
//    @@@                           (          @@@   @@@    @@@   @@@  @@/  @@@@@@   @@*    @@@       *@@@@.       
//              @@@@@@@@@@@@@@@                @@&          #@@   @@@  @@.   /@@@    @@&  @@@@           ,@@       
//         &@@@@              @@@@             @@            @@@   @@  @@            @@@@@@.     @@@@@@@@@@&       
//      .@@@                     @@@@                                                                .(/           
//     @@.                         @@@@                                                                            
//                                   @@@%   @@@@@@@@@@@@@@@@@@@@@@(           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&       
//             .@@@@@@@@@@@@           @@@                      @@#          @@@                                   
//                         @@@@          @@@                   @@@         @@@*                                    
//                           @@@           @@@@                @@&        @@@                                      
//                    @@      @@@           @@@@              @@@       @@@@                                       
//          @@@@*,%@@@(      &@@        @@@@@(               @@@      (@@@                                         
//                         @@@@         @@,                 @@@     @@@@                                           
//                    *@@@@@            @@@@@@@@@@@@      @@@.  *@@@@/                                             
//             @@@@@@@@&                        @@@@     @@@@@@@@@                                                 
//       (@@@@@@                             @@@@@/                                                                
//     @@@@                                 @@@@&@@@@@@                                                            
//    @@@                                           @@@                                                            
//    @@%            @@@@@@@@@@@@@@@@           @@@@@%                                                             
//    /@@(      @@@@@@             @@@     @@@@@@                                                                  
//      @@@@%@@@@               @@@@%       @@@                                                                    
//         %@@@@@@@@@@@@@@@@@@@@@           ,@@                                                                    
//         @@                                @@@                                                                   
//        @@@                                (@@                                                                   
//        /@@                                 @@@                                                                  
//         #@@@                               @@@                                                                  
//           @@@@&                           @@@                                                                   
//              .@@@@@@&                @@@@@@*                                                                    
//                     @@@@@@@@@@@@@@@@@@(                                                                         
                                                                                                                

pragma solidity ^0.8.0;

/// @author: Good Minds
/// @title: Good Minds Honoraries

import "./ERC721A.sol";
import "./Ownable.sol";

contract GoodMindsHonoraries is ERC721A, Ownable {
    string public tokenBaseURI;
    string public contractURI;

    event SetTokenBaseURI(string indexed tokenBaseURI);
    event SetContractURI(string indexed contractURI);

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {}

    function mintHonoraries(uint256 _quantity) external onlyOwner {
        _mint(msg.sender, _quantity);
    }

    function setTokenBaseURI(string memory _tokenBaseURI) external onlyOwner {
        tokenBaseURI = _tokenBaseURI;
        emit SetTokenBaseURI(tokenBaseURI);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
        emit SetContractURI(contractURI);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenBaseURI;
    }
}
