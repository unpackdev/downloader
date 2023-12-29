// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "./console.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./Address.sol";
import "./IERC1155.sol";

contract TravelCoHoodie is ERC721A, Ownable {
    using Address for address;
    string private _tokenUriBase;

    event mintEvent(
        address indexed user,
        uint256 quantity
    );

    constructor() ERC721A("DRx Travel Co hoodie", "DRxTCH") {
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function setTokenBaseURI(string memory tokenUriBase) public onlyOwner {
        _tokenUriBase = tokenUriBase;
    }

    function mintBatch(
        address receiver,
        uint256 quantity
    ) external onlyOwner {
        _safeMint(receiver, quantity);
        emit mintEvent(receiver, quantity);
    }

    function withdrawAll(address recipient) public onlyOwner {
        require(recipient != address(0), "recipient is the zero address");
        payable(recipient).transfer(address(this).balance);
    }

    function withdrawAllViaCall(address payable to) public onlyOwner {
        require(to != address(0), "recipient is the zero address");
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}
