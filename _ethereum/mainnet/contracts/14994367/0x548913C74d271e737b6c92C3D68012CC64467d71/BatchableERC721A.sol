//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";

/**
Powered by
  _____      _       ____      _____   
 |_ " _| U  /"\  uU |  _"\ u  |_ " _|  
   | |    \/ _ \/  \| |_) |/    | |    
  /| |\   / ___ \   |  _ <     /| |\   
 u |_|U  /_/   \_\  |_| \_\   u |_|U   
 _// \\_  \\    >>  //   \\_  _// \\_  
(__) (__)(__)  (__)(__)  (__)(__) (__)   . cafe      
 *
 [INFO]
 *- ERC721A is an implementation of IERC721 with significant gas savings for minting multiple NFTs in a single transaction.
 *- https://www.azuki.com/erc721a for more info.
 */

contract BatchableERC721A is ERC721A, Ownable {
    string public baseURI = "";
    uint256 public mintPrice = 0.0 ether;

    constructor() ERC721A("CoinBoy", "COINBOY") {
        _safeMint(msg.sender, 145);
        baseURI = "https://tart.mypinata.cloud/ipfs/QmWsrAQozeRksaofUF7Vbz6bdTFfDjsR54ierdQwqEzAXf/";
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
}
