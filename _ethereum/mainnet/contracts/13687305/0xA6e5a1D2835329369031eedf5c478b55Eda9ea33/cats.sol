// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//                    ___            ___                                   ___                
//                    (   )          (   )                                 (   )               
//          .--.    .-.| |  .--.      | |_      .--.        .--.     .---.  | |_       .--.    
//         /    \  /   \ | /    \    (   __)   /    \      /    \   / .-, \(   __)   /  _  \   
//        |  .-. ;|  .-. ||  .-. ;    | |     |  .-. ;    |  .-. ; (__) ; | | |     . .' `. ;  
//        | |  | || |  | ||  | | |    | | ___ | |  | |    |  |(___)  .'`  | | | ___ | '   | |  
//        | |  | || |  | ||  |/  |    | |(   )| |  | |    |  |      / .'| | | |(   )_\_`.(___) 
//        | |  | || |  | ||  ' _.'    | | | | | |  | |    |  | ___ | /  | | | | | |(   ). '.   
//        | '  | || '  | ||  .'.-.    | ' | | | '  | |    |  '(   ); |  ; | | ' | | | |  `\ |  
//        '  `-' /' `-'  /'  `-' /    ' `-' ; '  `-' /    '  `-' | ' `-'  | ' `-' ; ; '._,' '  
//        `.__.'  `.__,'  `.__.'      `.__.   `.__.'      `.__,'  `.__.'_.  `.__.   '.___.'   
                                                                                            
//        Art by Heidi Miles (jellycat.eth)
//        Contract by worm.eth, thanks to Andrew Benson for pointers!    

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./console.sol";

contract OdeToCats is
  ERC721Enumerable,
  ERC721Burnable,
  ReentrancyGuard,
  Ownable
{
  using SafeMath for uint256;
  using Strings for uint256;

  event baseUriUpdated(string newBaseURL);
  address payable public withdrawalAddress;

  constructor()
    ERC721("Ode to Cats by Heidi Miles", "ODECATS")
  {
    mintArtistProofs();
  }

  bool public mintActive = false;
  uint256 public lastMintedId;
  uint256 public constant MINT_PRICE = 0.07 ether;
  uint256 public constant maxPublicSupply = 90;
  bool public artistProofsMinted = false;

  string public baseURI =
    "ipfs://QmfN4fFFXmpLG2o4Vbiwzz9qr9o3kYnbypbVsTcynjjPe9/";
  address public artistAddress = 0x2E71754c263a3535552AEc62D200aD87b8e1cb71;

  function setBaseURI(string memory _url) public onlyOwner {
    emit baseUriUpdated(_url);
    baseURI = _url;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
  }

  function buy() public payable nonReentrant {
    require(mintActive, "Minting is not currently active.");
    require(lastMintedId < maxPublicSupply, "Minting has ended.");
    require(MINT_PRICE == msg.value, "Must use correct amount.");
    _mintNFT();
  }

  function _mintNFT() private {
    require(
      lastMintedId < maxPublicSupply,
      "Maximum number of mints has been reached"
    );
    uint256 newTokenId = lastMintedId + 1;
    lastMintedId = newTokenId;
    _safeMint(msg.sender, newTokenId);
  }

  function mintArtistProofs() private {
    require(artistProofsMinted == false, "artists proofs already minted");
    for (uint256 i = 91; i < 101; ++i) {
     _safeMint(artistAddress, i);
    }
    artistProofsMinted = true;
  }

  function mintState() public onlyOwner returns (bool) {
    mintActive = !mintActive;
    return mintActive;
  }

  function withdraw() public onlyOwner {
    Address.sendValue(payable(artistAddress), address(this).balance);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}