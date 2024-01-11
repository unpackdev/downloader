//
// !!   DECLARE YOUR PHAVORITE NFT  !!
//
// this may or may not be a shitpost, only time will tell. phunk if i care.
//
// if someone tells you that a picture is worth a fortune they might be a fortune teller selling you lies.
//
// this contract is for apreciatooors to declare their phavorite NFT on the ethereum blockchain
// whenever you view your token it will show you the image of your fave, so you can display it wherever you want :)
//
// remember, you don't own or hold any rights to the image or token you claim as your favorite 
// but you have every right to view your declaration of appreciation anywhere -- that's called free speech
//
// HOW TO USE THIS CONTRACT:
// - send .001 ETH to the safeMint method of this contract, and provide the contract address and token ID of your fave
// -> you will receive your FAV token in your wallet
// - whenever you have a new favorite, send 001. ETH to the favNFT method of this contract, 
//   and provide the contract address and token ID of your new favorite NFT
// -> your FAV token will be updated to reflect your new favorite NFT and should eventually update its appearance
//
// Brought to you by Neuromantic.eth
//
// SPDX-License-Identifier: AFL-3.0;
//
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

pragma solidity  ^0.8.7;

interface INFT {
    function tokenURI(uint256 tokenId)   external view  returns (string memory);
}

contract PHAV is ERC721, Ownable, Pausable {

    struct NFT {
      address project;       
      uint256 token;
   } 
   NFT[] nfts;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("My Phavorite NFT", "PHAV") {
    }
    function mintPhav(address project, uint256 token) payable public  {
        if( msg.sender != owner() ){
           require(msg.value == .001 ether , "poor");
        }
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        nfts.push(NFT(project,token));
        _safeMint(msg.sender, tokenId);
    }
    function tokenURI(uint256 tokenId) override public view virtual returns (string memory) {
        return INFT(nfts[tokenId].project).tokenURI(nfts[tokenId].token);
    }
    function phavNFT(uint256 tokenId, address project, uint256 token) public payable {
        require(ownerOf(tokenId) == msg.sender, "you can only modify your own PHAV.");
        if( msg.sender != owner() ){
           require(msg.value == .001 ether, "poor");
        }
        nfts[tokenId].project = project;
        nfts[tokenId].token = token;
    }
}
