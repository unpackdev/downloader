// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";

interface ERC20Token {
    function balanceOf(address account) external view returns (uint256);
}

contract AvianAvatars is ERC721("Avian Avatars", "BIRD") {
    string public baseURI =
        "ipfs://QmVttBZtxw8d231W8w4ugazQW3LRMeWR8rijXR5RuXNgb1/";
    bool public isSaleActive;
    uint256 public circulatingSupply;
    uint256 public constant totalSupply = 2478;

    address public birdToken = 0x70401dFD142A16dC7031c56E862Fc88Cb9537Ce0;
    address public owner = 0x18e150042eEB7d4f26bD865DF7e0Ed3e7bb6d7e2;

    constructor() {
        _mint(owner, ++circulatingSupply);
    }

    ////////////////////
    //  PUBLIC SALE   //
    ////////////////////

    // Purchase multiple NFTs at once
    function purchaseTokens() external payable {
        require(
            isSaleActive && circulatingSupply <= totalSupply - 60,
            "Sale Closed"
        );
        require(msg.value >= 0.1 ether, "Try to send more ETH");
        require(balanceOf(msg.sender) == 0, "You Already Minted");

        _mint(msg.sender, ++circulatingSupply);

        if (ERC20Token(birdToken).balanceOf(msg.sender) >= 25 ether)
            _mint(msg.sender, ++circulatingSupply);
    }

    //////////////////////////
    // Only Owner Methods   //
    //////////////////////////

    function setSaleActive(bool _startSale) external onlyOwner {
        isSaleActive = _startSale;
    }

    // Owner can withdraw ETH from here
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Hide identity or show identity from here
    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI = _baseURI_;
    }

    // Send NFTs to a list of addresses
    function gift(address[] calldata _sendNftsTo)
        external
        onlyOwner
        tokensAvailable(_sendNftsTo.length)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _mint(_sendNftsTo[i], ++circulatingSupply);
    }

    ////////////////////
    // Helper Methods //
    ////////////////////

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier tokensAvailable(uint256 _howMany) {
        require(
            _howMany <= totalSupply - circulatingSupply,
            "Try minting less tokens"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}
