//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract NoSimpMfer is ERC721A, Ownable {
    
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public mintPrice = 0.03 ether;
    uint256 public ogMintPrice = 0.01 ether;
    address private immutable _ogMfers = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f;

    uint256 private immutable _mintStartTime;
    uint256 private _mintBaseQty;

    string private __baseURI;


    constructor(uint256 mintStartTime, uint256 initQty) ERC721A("NoSimpMfer", "XSMFER") {
        _mintStartTime = mintStartTime;
        _mintBaseQty = initQty;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    // 1 token released every 2 hours
    function totalMintable() public view returns (uint256) {
        uint256 timeSince = (block.timestamp > _mintStartTime) ? block.timestamp - _mintStartTime : 0;
        if (timeSince > 0) {
            uint256 subtotal = _mintBaseQty + (timeSince / 7200);
            return (subtotal > MAX_SUPPLY) ? MAX_SUPPLY : subtotal;
        } else {
            return 0;
        }
    }

    function mint(uint256 quantity) external payable {
        _validateSupply(quantity);
        require(quantity * mintPrice == msg.value, "Wrong amount sent");
        _safeMint(_msgSender(), quantity);
    }

    function ogMint(uint256 quantity) external payable {
        require(IERC721(_ogMfers).balanceOf(_msgSender()) > 0, "OG Mfers required");
        _validateSupply(quantity);
        require(quantity * ogMintPrice == msg.value, "Wrong amount sent");
        _safeMint(_msgSender(), quantity);
    }

    function _validateSupply(uint256 quantity) private view {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply!");
        require(totalSupply() + quantity <= totalMintable(), "Wait for new drops");
    }


    // Owner functions
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        require(newMintPrice >= 0.01 ether, "Below min price");
        mintPrice = newMintPrice;
    }

    function setOgMintPrice(uint256 newOgMintPrice) external onlyOwner {
        require(newOgMintPrice >= 0.03 ether, "Below min price");
        ogMintPrice = newOgMintPrice;
    }

    function setMintBaseQty(uint256 newBaseQty) external onlyOwner {
        require(newBaseQty > _mintBaseQty, "Below current base");
        _mintBaseQty = newBaseQty;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
}
