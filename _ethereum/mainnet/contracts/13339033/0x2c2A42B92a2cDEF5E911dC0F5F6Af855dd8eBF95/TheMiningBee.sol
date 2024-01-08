// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract TheMiningBee is ERC721Enumerable, Ownable {
    /*
  
*/

    //uint256's
    uint256 currentPrice = 30000000000000000;
    uint256 maxSupply = 10800;
    uint256 saleStartTime = 1628787600;

    //strings
    string currentContractURI = "https://ipfs.io/theminingbee.mypinata.cloud/ipfs/QmbzRxi4UKpo31ZtHqJbg6Mr86BeXcDrDMK92dhYK6ieqK";
    string baseURI = "https://ipfs.io/theminingbee.mypinata.cloud/ipfs/QmYP7rSFJMPiZJMLs4kaC9KxLaTAVT8pfHZyZKxV6z126x";

    //bools
    bool baseURIChangeable = true;

    //structs
    struct _token {
        uint256 tokenId;
        string tokenURI;
    }

    //Libraries
    using Strings for uint256;

    constructor() ERC721("TheMiningBee", "TMB") {}

    //Write Functions

    //Functions for users

    function mintBees(uint256 BeeCount) public payable {
        uint256 supply = totalSupply();
        require(block.timestamp >= saleStartTime, "Sale has not started");
        require(BeeCount < 11, "Can only mint max 10 Bees!");
        require(
            supply + BeeCount <= maxSupply,
            "Maximum Bees already minted!"
        );
        require(msg.value >= (currentPrice * BeeCount));

        for (uint256 i = 0; i < BeeCount; i++) {
            _mint(msg.sender, supply + i);
        }

        return;
    }

    function ownerMintBees(uint256 BeeCount) public {
        require(msg.sender == owner(), "Only owner may mint free Bees");
        uint256 supply = totalSupply();
        require(
            supply + BeeCount <= maxSupply,
            "Maximum Bees already minted!"
        );

        for (uint256 i = 0; i < BeeCount; i++) {
            _mint(msg.sender, supply + i);
        }

        return;
    }

    //OWNER FUNCTIONS

    function withdraw() public {
        require(msg.sender == owner(), "Only owner can withdraw funds.");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function changeContractURI(string memory newContractURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change contract URI.");
        currentContractURI = newContractURI;
        return (currentContractURI);
    }

    function changeSaleStartTime(uint256 newSaleStartTime)
        public
        returns (uint256)
    {
        require(
            msg.sender == owner(),
            "Only owner can change sale start time."
        );
        saleStartTime = newSaleStartTime;
        return (saleStartTime);
    }

    function changeCurrentPrice(uint256 newCurrentPrice)
        public
        returns (uint256)
    {
        require(msg.sender == owner(), "Only owner can change current price.");
        currentPrice = newCurrentPrice;
        return currentPrice;
    }

    function makeBaseURINotChangeable() public returns (bool) {
        require(
            msg.sender == owner(),
            "Only owner can make base URI not changeable."
        );
        baseURIChangeable = false;
        return baseURIChangeable;
    }

    function changeBaseURI(string memory newBaseURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change base URI");
        require(
            baseURIChangeable == true,
            "Base URI is currently not changeable"
        );
        baseURI = newBaseURI;
        return baseURI;
    }

    /*
        READ FUNCTIONS
    */

    function baseURICurrentlyChangeable() public view returns (bool) {
        return baseURIChangeable;
    }

    function getCurrentPrice() public view returns (uint256) {
        return currentPrice;
    }

    function contractURI() public view returns (string memory) {
        return currentContractURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (_token[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        //Create an array of token structs.
        _token[] memory _tokens = new _token[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            uint256 _tokenId = tokenOfOwnerByIndex(_owner, i);
            string memory _tokenURI = tokenURI(_tokenId);
            _tokens[i] = _token(_tokenId, _tokenURI);
        }

        return _tokens;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent Bee"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}
