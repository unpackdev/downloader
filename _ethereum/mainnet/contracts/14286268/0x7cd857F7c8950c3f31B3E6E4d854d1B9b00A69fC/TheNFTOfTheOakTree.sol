pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

contract TheNFTOfTheOakTree is ERC721, ERC721Burnable, ERC721Enumerable, Ownable {
  uint public constant THE_NFT_OF_THE_OAK_TREE = 1;

  constructor() ERC721("The NFT of the Oak Tree", "OAK") {}
    
  function contractURI() public pure returns (string memory) {
    return "data:,"
           "{"
           " \"name\" : \"The NFT of the Oak Tree Collection\","
           " \"description\" : \"The NFT of the Oak Tree Collection\""
           "}";
  }

 function tokenURI(uint256) public view virtual override returns (string memory) {
    return "data:,"
           "{"
           " \"name\" : \"The NFT of the Oak Tree\","
           " \"description\" : \"This is the NFT of the oak tree originally created "
                                "by Sir Michael Craig-Martin in 1973. It is neither "
                                "the tree itself, nor its concept, nor its physical form. "
                                "It is also not the art piece called 'An Oak Tree', "
                                "nor its exhibition, nor any part of its installation. "
                                "This NFT does not confer ownership nor any other legal "
                                "rights to any of these either. This is nothing more and "
                                "nothing less than the NFT of that oak tree. Enjoy.\","
           " \"image\" : \"ipfs://QmbwhZUBHH3fvJtMSBb1jDEhnSpj6C1xKkUvbyKSbzfP8R\""
           "}";
  }

  function mintNFT(address recipient) public returns (uint256) {
    _safeMint(recipient, THE_NFT_OF_THE_OAK_TREE);
    return THE_NFT_OF_THE_OAK_TREE;
  }
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, 
                                                                      ERC721Enumerable)
    returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
