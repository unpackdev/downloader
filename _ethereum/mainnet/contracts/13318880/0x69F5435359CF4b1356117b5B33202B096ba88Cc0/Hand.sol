// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract Hand is ERC721Tradable {
    uint256 public MAX_HANDS = 23500;
    uint256 public GIVEAWAY_AMOUNT = 25;
    uint256 public MAX_MINTABLE_PER_TXN = 10;
    uint256 public PRICE_PER_HAND = 0.015 ether;

    bool public minting_enabled = true;

    string public baseTokenURI = "https://hoc-metadata-api.herokuapp.com/api/hands/";
    string public baseTokenURI_ext = "";

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Hands of Creation", "HAND", _proxyRegistryAddress)
    {
        // First 25 will be given away!
        for (uint8 i = 0; i < GIVEAWAY_AMOUNT; ++i) {
            _safeMint(_msgSender(), (totalSupply() + 1));
        }
    }

    function setBaseTokenURI(string memory _new_uri) public onlyOwner {
        baseTokenURI = _new_uri;
    }

    function setBaseTokenURI_ext(string memory _new_uri_ext) public onlyOwner {
        baseTokenURI_ext = _new_uri_ext;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId), baseTokenURI_ext));
    }

    function priceMint(uint256 _quantity) public view returns (uint256) {
       require(_quantity > 0, "Must mint at least one hand!");
       require(_quantity <= MAX_MINTABLE_PER_TXN, "Cannot mint more than ten per transaction!");

       return _quantity * PRICE_PER_HAND;
    }

    function mintHand(uint256 _num_to_mint) public payable {
        require(minting_enabled, "Minting is not enabled!");
        require((totalSupply() + _num_to_mint) <= MAX_HANDS, "Not enough Hands left to mint!");
        require(msg.value >= priceMint(_num_to_mint), "Did not send enough Ether!");

        for (uint8 i = 0; i < _num_to_mint; ++i) {
            _safeMint(_msgSender(), (totalSupply() + 1));
        }
    }

    function toggleMinting() external onlyOwner {
        minting_enabled = !minting_enabled;
    }

    function collect() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
