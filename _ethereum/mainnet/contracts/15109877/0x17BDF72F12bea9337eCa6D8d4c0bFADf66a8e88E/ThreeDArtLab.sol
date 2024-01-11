// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "Ownable.sol";
import "ERC721Enumerable.sol";

contract ThreeDArtLab is ERC721Enumerable, Ownable {
    using Strings for uint256;
    bool public salePaused = true;
    string private baseTokenURI;
    uint256 private reserved = 100;
    uint256 public price = 0.2 ether;

    constructor(string memory baseTokenURI_) ERC721("3D-ART-LAB", "3DAL") {
        setBaseTokenURI(baseTokenURI_);
    }

    function flipSaleState() public onlyOwner {
        salePaused = !salePaused;
    }

    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getReserved() public view onlyOwner returns (uint256) {
        return reserved;
    }

    function reserve(uint256 thisMany_, address addressToReserve_)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(thisMany_ > 0, "Can not mint zero or negative token!");
        require(
            thisMany_ <= reserved,
            "Reserve would exceed reserved token supply."
        );
        uint256 i;
        for (i = 0; i < thisMany_; i++) {
            _safeMint(addressToReserve_, supply + i);
        }
        reserved -= thisMany_;
    }

    function mint(uint256 thisMany_) public payable {
        uint256 supply = totalSupply();
        require(!salePaused, "Sale is not active yet!");
        require(thisMany_ <= 20, "Exceeded max token per mint.");
        require(
            supply + thisMany_ <= 1000 - reserved,
            "Purchase would exceed token supply."
        );
        require(
            price * thisMany_ <= msg.value,
            "Ether value sent is not correct."
        );
        require(thisMany_ > 0, "Can not mint zero or negative token!");
        uint256 i;
        for (i = 0; i < thisMany_; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function walletOfOwner(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner_);
        uint256[] memory list = new uint256[](count);
        for (uint256 i; i < count; i++) {
            list[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return list;
    }
}
