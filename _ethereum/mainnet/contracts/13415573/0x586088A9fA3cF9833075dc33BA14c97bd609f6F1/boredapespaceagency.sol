//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract BoredApeSpaceAgency is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint public fee;
    event PriceUpdated(uint newPrice);
    string public baseUri;
    bool public isSaleHalted;

    constructor() ERC721("BoredApeSpaceAgency", "BASA") {
	fee = 40000000000000000 wei; //0.04 ETH
	baseUri = "https://gateway.pinata.cloud/ipfs/QmWmwj3A99EQXnpPoqQjJKkFaNFP5bxwaEiifxUF95unoe/";
	isSaleHalted = false;
    }

    function mintNFT(address recipient, uint numberOfMints)
        public payable
        returns (uint256)
    {
	require(!isSaleHalted, "Sale must be active to mint a BASA Token.");	
	require(_tokenIds.current() + numberOfMints <= 1000, "Maximum amount of BASA Tokens already minted.");
	require(msg.value >= fee * numberOfMints, "Fee is not correct.");
	require(numberOfMints <= 20, "You can only mint a maximum of 20 BASA Tokens at once.");

	uint256 newItemId=0;

	for(uint i = 0; i < numberOfMints; i++) {
        	_tokenIds.increment();
	        newItemId = _tokenIds.current();
		string memory tokenURI = "https://gateway.pinata.cloud/ipfs/QmWmwj3A99EQXnpPoqQjJKkFaNFP5bxwaEiifxUF95unoe/basa-blue.json";
	        _mint(recipient, newItemId);
	        _setTokenURI(newItemId, tokenURI);
	}
        return newItemId;
    }

    function updateFee(uint newFee) public onlyOwner{
       fee = newFee;
       emit PriceUpdated(newFee);
    }

    function getFee() public view returns (uint) {
       return fee;
    }

    function cashOut() public onlyOwner{
        payable(address(0x29faD43F3bB81F5A6Aa6eCBf095ecEa60ef4BFdE)).transfer(address(this).balance);//msg.sender replaced with community wallet address
    }

    function getRemaining() public view returns (uint) {
        return _tokenIds.current();
    }

    function toggleSaleState() public onlyOwner {
        isSaleHalted = !isSaleHalted;
    }

    function modTokenURI(uint id, string memory uri) public onlyOwner {

        _setTokenURI(id, uri);
    }

    function totalSupply() public pure returns (uint) {
       return 1000;
    }

}
