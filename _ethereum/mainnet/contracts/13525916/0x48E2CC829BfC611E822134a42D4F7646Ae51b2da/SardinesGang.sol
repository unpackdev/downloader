// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";

contract SardinesGang is ERC721("Sardines Gang", "SG") {
    string public baseURI;
    bool public isSaleActive;

    uint256 public circulatingSupply;
    uint256 public constant totalSupply = 9999;

    address public owner = msg.sender;
    uint256 public itemPrice = 0.01 ether;

    IERC721 public bastardPenguins =
        IERC721(0x350b4CdD07CC5836e30086b993D27983465Ec014);

    bool public isClaimingActive;
    mapping(uint256 => bool) public radeem;

    ///////////////////////
    //  CLAIM SARDINES   //
    ///////////////////////

    // for every penguin 1 sardine can be claimed
    function claimSardine(uint256 penguinTokenId) private {
        require(isClaimingActive, "Claim is not active.");
        require(
            !radeem[penguinTokenId],
            "Sardine already claimed for this Penguin token."
        );
        require(
            msg.sender == bastardPenguins.ownerOf(penguinTokenId),
            "You are not the owner of this Penguin token."
        );

        radeem[penguinTokenId] = true;
        _mint(msg.sender, ++circulatingSupply);
    }

    // claim multiple sardines in single transaction
    function claimSardines(uint256[] memory penguinTokenIds)
        external
        tokensAvailable(penguinTokenIds.length)
    {
        for (uint256 i = 0; i < penguinTokenIds.length; i++)
            claimSardine(penguinTokenIds[i]);
    }

    ////////////////////
    //  PUBLIC SALE   //
    ////////////////////

    // Purchase multiple NFTs at once
    function purchaseTokens(uint256 _howMany)
        external
        payable
        tokensAvailable(_howMany)
    {
        require(isSaleActive, "Sale is not active");
        require(_howMany > 0 && _howMany <= 20, "Mint min 1, max 20");
        require(msg.value >= _howMany * itemPrice, "Try to send more ETH");

        for (uint256 i = 0; i < _howMany; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    //////////////////////////
    // Only Owner Methods   //
    //////////////////////////

    function setSaleActive(bool _startSale) external onlyOwner {
        isSaleActive = _startSale;
    }

    function setIsClaimingActive(bool _isClaimingActive) external onlyOwner {
        isClaimingActive = _isClaimingActive;
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

    // Change Price in case of ETH price changes too much
    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    ////////////////////
    //   Burn Method  //
    ////////////////////

    function burn(uint256 _tokenId) external {
        require(_exists(_tokenId), "Burn: token does not exist.");
        require(
            ownerOf(_tokenId) == msg.sender,
            "Burn: caller is not token owner."
        );
        _burn(_tokenId);
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
