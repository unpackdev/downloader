/**
 *Submitted for verification at Etherscan.io - 2022-03-14
*/
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/*

888b     d888 8888888 888b    888 88888888888      8888888888 .d88888b.  8888888b.       888     888 888    d8P  8888888b.         d8888 8888888 888b    888 8888888888 
8888b   d8888   888   8888b   888     888          888       d88P" "Y88b 888   Y88b      888     888 888   d8P   888   Y88b       d88888   888   8888b   888 888        
88888b.d88888   888   88888b  888     888          888       888     888 888    888      888     888 888  d8P    888    888      d88P888   888   88888b  888 888        
888Y88888P888   888   888Y88b 888     888          8888888   888     888 888   d88P      888     888 888d88K     888   d88P     d88P 888   888   888Y88b 888 8888888    
888 Y888P 888   888   888 Y88b888     888          888       888     888 8888888P"       888     888 8888888b    8888888P"     d88P  888   888   888 Y88b888 888        
888  Y8P  888   888   888  Y88888     888          888       888     888 888 T88b        888     888 888  Y88b   888 T88b     d88P   888   888   888  Y88888 888        
888   "   888   888   888   Y8888     888          888       Y88b. .d88P 888  T88b       Y88b. .d88P 888   Y88b  888  T88b   d8888888888   888   888   Y8888 888        
888       888 8888888 888    Y888     888          888        "Y88888P"  888   T88b       "Y88888P"  888    Y88b 888   T88b d88P     888 8888888 888    Y888 8888888888 

*/
// ANYONE CAN CREATE AN NFT FOR THE UKRAINIAN PEOPLE!
// SIMPLY CALL MINT WITH THE IPFS METADATA FILE URL
// PAY 0.01 ETH + GAS PER NFT to MINT
// YOU GET THE NFT, UKRAINE GETS THE ETH!

// SAMPLE METADATA:
// ipfs.io/ipfs/QmR8WZDTobS3uTMyt863rPMNCm8pGmi1Jm7JLAFSvmTW8u

// ALL MINTING FEES GO DIRECTLY TO UKRAINE OFFICIAL ADDRESS
// https://twitter.com/Ukraine/status/1497594592438497282
// ETH and USDT (ERC-20) - 0x165CD37b4C644C2921454429E7F9358d18A45e14
// STOP THE WAR! - FREE THE UKRAINE PEOPLE!

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract UKRAINENFTS is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    //Price in Eth or Matic, depending on Network
    uint256 public constant ethPrice = 10000000000000000; //0.01 ETH per NFT
    uint256 public constant maticPrice = 10000000000000000000; //10.0 MATIC per NFT

    constructor() ERC721("MINT FOR UKRAINE", "MUA") {}

    // ANYONE Can Call MINT.  
    // _numberOfNFTs = how many nfts to mint
    // the NFT Metadata URI
    // Payable - Total Cost for all NFTs
    // 
    function safeMint(uint32 _numberOfNFTs, string memory uri) public payable {
        
      require(msg.value >= ethPrice * _numberOfNFTs , "insufficient funds for qty requested");
      require(_numberOfNFTs > 0, "need to mint at least 1 nft");

      for(uint i = 0; i < _numberOfNFTs; i++) {

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

      }

    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
 
 
  /*
      anyone can / someone periodically needs to invoke the withdraw function, 
      balance of ETH/MATIC goes directly to Ukraine Govt Eth Address
  */
  function withdraw() public {
      uint balance = address(this).balance;
      payable(0x165CD37b4C644C2921454429E7F9358d18A45e14).transfer(balance);
      //VERIFIED UKRAINE ADDRESS
      //https://twitter.com/Ukraine/status/1497594592438497282
      //ETH and USDT (ERC-20) - 0x165CD37b4C644C2921454429E7F9358d18A45e14
  }

}


