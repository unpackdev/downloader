//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract WanderingAround is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant maxPictures = 10_000;
    uint256 public constant picPrice = 0.05 ether;
    uint256 public constant maxPictureInCluster = 20; // Maximum number of picture in single purchase
    bool public saleIsActive = false;
    // Reserve 200 Pictures for the Team and Giveaways/Prizes on twitter
    uint256 public pictureReserve = 200;

    constructor() ERC721("Wandering Around", "WAC") {}

    string public _tokenURIPrefix =
        "https://wandaring-around.s3.us-west-2.amazonaws.com/";

    function _baseURI() internal view override returns (string memory) {
        return _tokenURIPrefix;
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _tokenURIPrefix = newuri;
    }

    function contractURI() public pure returns (string memory) {
        return
            "https://wandaring-around.s3.us-west-2.amazonaws.com/contract.json";
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintPicture(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Picture");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxPictureInCluster,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= maxPictures,
            "Purchase would exceed max supply of Pictures"
        );
        require(
            msg.value >= picPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < maxPictures) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reservePictures(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= pictureReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        pictureReserve = pictureReserve.sub(_reserveAmount);
    }
}
