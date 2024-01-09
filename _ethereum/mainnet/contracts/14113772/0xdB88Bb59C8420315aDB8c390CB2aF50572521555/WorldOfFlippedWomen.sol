// SPDX-License-Identifier: MIT

/*
//                 .}}}}}}{{,               //
//               .}}}}}}}{{{{{              //
//              }}}}{{{{{  {{{{             //
//             {{{{{ _   _ }}}}}            //
//            }}}}}  m   m  }}}}            //
//            {{{{{    ^    C{{{{           //
//           }}}}}}/  '='  \}}}}}}          //
//          {{{{{{{{;.___.;{{{{{{{{         //
//         }}}}}}}}}}(   )}}}}}}}}}         //
//         {{{{{{{{{{:   :'}}}}}{{{{        //
//        }}}}}}{{{ `WoFW` }}}}}}{{{        //
//           }}}}}}}}}    {{{{{{{{{         //
//            {{{{{{{{{  }}}}}}}}           //
//              }}}}}}  {{{{{{{{            //
//                {{{{  }}}}}               //
//                 }}    {{{                //                                                                                                     
*/


pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721.sol";
 
contract WorldOfFlippedWomen is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant maxSupply = 10000;

    uint256 public totalSupply = 0;

    string public baseUri = "https://worldofflippedwomen.art/api/metadata?id=";

    constructor() ERC721("World Of Flipped Women", "WOFW") {}

    function mint(uint256 _numTokens) external payable {
        
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= maxSupply, "Maximum supply of women has been reached.");

        if(_numTokens>1){
            uint256 cumulative_cost = 0;
            for (uint256 n = 1; n <= _numTokens; n++) {
                cumulative_cost += 0.07 ether;
            }
            require(cumulative_cost <= msg.value, "You didn't send enough ETH to mint.");
        }else{
            require(0.07 ether <= msg.value, "You didn't send enough ETH to mint.");
        }
        
        for (uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }

        totalSupply += _numTokens;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        (bool withdrawEth, ) = payable(0xe5435A0835aA9ADf644ef27F842183715F7CDF5e).call{value: balance}(""); 
        require(withdrawEth, "Transfer failed.");
    }

    // INTERNAL FUNCTIONS
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}