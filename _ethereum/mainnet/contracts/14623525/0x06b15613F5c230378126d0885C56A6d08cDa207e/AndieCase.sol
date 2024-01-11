// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

/// @author Sergio Martell - Motley Ds

/**
* @notice This is the first iteration for the implementation of the erc-1155 for the Music 3.0 initiative.
* this contract is an artist based contract, that will be controlled by either the artist or their management team.
* The structure of the contract allows for multiple releases or "drops" that can all be under the same instrument.
*/

/**
* @dev This is an Artist Controlled Music 3.0 ERC-1155 Contract, for Band NFTs.
* Please review the docs at www.bandnfts.com and the metadata on these assets to be able to interact with the 
* Music 3.0 and Band Royalty ecosystem.
 */

contract AndieCase is ERC1155, ReentrancyGuard, Ownable {
    string public name;
    string public symbol;

    // Releases - store base URI for the different releases from the artist, this way there is no need to have 1 shared baseURI.
    // note: Make sure that you are referencing an uploaded folder, not the file itself. The contract will give back the baseURI+tokenID
    // and also make sure you remove the .json extension to the file when uploading the folder.

    mapping (uint256 => string) private _releases;

    // Prices - for each of the releases, prices must be set in Gwei.
    mapping (uint256 => uint256) private _prices;

    // Supplies - Per release, the total number of tokens that will exist per release.
    mapping (uint256 => uint256) private _supplies;

    // Tokens minted, a way to track the amount of tokens that have been minted per release.
    mapping(uint256 => uint256) private _minted;

    address _rylty = 0x02A0355545A6c6F3951288C2DC878e930a738235;
    address _bstage = 0x69226ec93F31B11a1AAB0253CA3F4bAF8D56B407;
    address _band = 0xfAE7ba7eA15Dd2eAd68593f0701793bC43B7dB10;
    address _whomag = 0x06C9dd014e5B8b103E3Df5f6BF21076Aaaf08d01;

    // Switch to close and open sale;
    
    bool _saleActive = false;

    event ReleaseMinted(address sender, uint256 quantity, uint256 tokenId);

    constructor() ERC1155("") {
        name = "Andie Case Music NFTs";
        symbol = "ACMN";
        _releases[0] = "https://ipfs.io/ipfs/QmYkZbJ2fKyUoGs7RtLzdCwv7ZSTLmNkGF8LvShotXnQE7/";
        _supplies[0] = 777;
        _prices[0] = 0.03 ether;
        _minted[0] = 0;
    }
    
    // Owner Only functions.
    
    function setSaleState(bool _newSaleActive) external onlyOwner {
    _saleActive = _newSaleActive;
    }

     // Owner mint, will reflect on total supply. 

    function ownerMint(uint256 id, uint256 amount)
        public
        onlyOwner
        {
            require(_minted[id]+ amount <= _supplies[id], "This release has reached it's limited supply!");
            _mint(msg.sender, id, amount, "");
            _minted[id]+= amount;
        }

    function changeBaseURI(string memory _uri, uint256 tokenId) 
        public 
        onlyOwner
        {
            _releases[tokenId] = _uri;
        }
        
    function changePrice(uint256 _price, uint256 tokenId)
        public
        onlyOwner
        {
            _prices[tokenId] = _price;
        }

    /**
    * @dev please take notice of the _releases comment. And make sure that the folder that is uploaded to IPFS has a file with the tokenId as the name (0,1,2,3),
    * the token Ids must me whole numbers.
    */

    function createRelease(uint256 tokenId, uint256 supply, uint256 price, string memory baseURI) 
        public
        onlyOwner 
        {
            _releases[tokenId] = baseURI;
            _supplies[tokenId] = supply;
            _prices[tokenId] = price;
        }

    function disburse() external onlyOwner {
        uint _rylamount = address(this).balance * 125/10000;
        uint _bstageamount = address(this).balance * 125/10000;
        uint _bndamount = address(this).balance * 375/1000;
        uint _distamount = address(this).balance * 10/100;
        
        require(payable(_rylty).send(_rylamount), "Failed to send to rylty stake pool");
        require(payable(_band).send(_bndamount), "Failed to send to BAND");
        require(payable(_bstage).send(_bstageamount),  "Failed to send to BSTAGE stake pool");
        require(payable(_whomag).send(_distamount), "Failed to send to Distributor");
        require(payable(msg.sender).send(address(this).balance));
    }


    function emergencyWithdraw() external payable onlyOwner {
        (bool success, ) = payable(_band).call{ value: address(this).balance }(
        ''
        );
        require(success);
    }

    // API

    function mint(uint256 id, uint256 amount)
        public
        payable
        nonReentrant
    {   
        require(_saleActive, "Sale not active");
        require(_supplies[id] > 0, "This release does not exist.");
        require(_minted[id]+ amount <= _supplies[id], "This release has reached it's limited supply!");
        require(msg.value >= amount * _prices[id], "The amount sent doesn't cover the price for the asset");
        _mint(msg.sender, id, amount, "");
        _minted[id]+= amount;
        emit ReleaseMinted(msg.sender, amount, id);
    }

    function totalSupply(uint256 id) public view returns (uint256 supply){
        return _minted[id];
    }

    /**
    * @dev Returns the URI to the contract metadata as required by OpenSea
    */

    function contractURI() public pure returns (string memory){
        return "ipfs://bafkreigpjh3cbldi2qxy2ehdux24wrwg43w4vmgxoiqcuoaczgwkkhtxm4";
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return(string(abi.encodePacked( _releases[tokenId], Strings.toString(tokenId))));
    }

// fallback functions to handle someone sending ETH to contract

  fallback() external payable {}

  receive() external payable {}

 }