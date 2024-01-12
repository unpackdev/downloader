// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721A.sol";
 
/**
* Pepe Unlimited
*
* A collection with great and unique Pepe art & a simple and different approach for cheap minting.
* No presale, anyone can mint for free (+ gas).
*
* Max. supply 3334 Pepes, max. 2 mints per wallet.
*
* Important Details (How to mint):
*
* With the combined forces of the mint-on-receive principle and Azuki's EIP721A extension, 
* minting - especially batch minting - on Mainnet has never been cheaper.
*
* This collection demonstrates additional gas savings of 20-35% on top of the known EIP721A savings.
*
* Here is how it works:
*
* Instead of calling a mint function, simply send _zero_ ETH for minting 2 NFTs to the contract (max. 2 per wallet).
*
* Once the tx completed, the senders will find their NFTs in their wallets.
*
* If you get an extremly high gas suggestion from your wallet OR the tx fails, it means Pepe is minted out or you reached the max. amount per wallet.
*
* By leaving out the mint function - and with it the function parameters - the minting process will save substantial amounts of gas.
*
* Additionally, this collection derives from EIP721A and provides quasi-constant minting costs.
*
* This collection is fully erc721 compliant.
*
* Once this collection is minted out, Pepe Unlimited will provide unique art for collectors with interesting traits, rarities and potential use-cases (aka reveal).
*
* Mint instructions on: https://pepeunlimited.eth/
*
* Mint-on-receive is a new type of mint and has been first seen on https://rarity.garden/
*/
contract PepeUnlimited is ERC721A
{

    using Strings for uint256;

    uint256 public _total_max;
    address public owner;
    string public _baseTokenUri;
    mapping(address => bool) public minters;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 max_batch,
        uint256 collection_size
    ) ERC721A(name, symbol, max_batch, collection_size) {

        _baseTokenUri = baseTokenURI;
        owner = _msgSender();
        _total_max = collection_size;
    }

    receive() external payable {

        require(msg.value == 0, "receive: pepe doesn't need any ETH.");
        require(!minters[_msgSender()], "receive: wallet minted its Pepes already.");
        require(totalSupply() + 2 <= _total_max, "receive(): max. supply reached.");

        minters[_msgSender()] = true;
        _safeMint(_msgSender(), 2, "");
    }

    function _baseURI() internal view virtual override returns (string memory) {

        return _baseTokenUri;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
          
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "https://rarity.garden/media/pepe/prereveal.json";
    }
    
    function setBaseUri(string calldata baseTokenURI) public virtual {

        require(owner == _msgSender(), "setBaseUri: must be owner to set base uri.");

        _baseTokenUri = baseTokenURI;
    }

    function transferOwnership(address newOwner) external
    {
        require(_msgSender() == owner, "transferOwnership: not the owner");

        owner = newOwner;
    }
}