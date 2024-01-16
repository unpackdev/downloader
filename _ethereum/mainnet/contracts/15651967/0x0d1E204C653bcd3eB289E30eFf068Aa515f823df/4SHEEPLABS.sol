// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract _4SHEEPLABS is ERC721A, Ownable {

    enum EPublicMintStatus {
        NOTACTIVE,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    EPublicMintStatus public publicMintStatus;

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply;
    uint256 public publicSalePrice;
    uint256 public txLimit = 100;

    mapping(address => uint256) public usermint;

    constructor(
        string memory _baseTokenURI
    ) ERC721A ("4SHEEPLABS", "4SHEEPLABS") {
        defaultTokenURI = _baseTokenURI;
        _safeMint(_msgSender(), 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser payable {
        require(publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= txLimit, "Invalid quantity");
    _safeMint(msg.sender, _quantity);
    }


    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(status);
    }

    function setTxlimit(uint256 txlimit) external onlyOwner {
        txLimit = txlimit;
    }

    function setMaxSupply(uint256 totalsupply) external onlyOwner {
        maxSupply = totalsupply;
    }


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function devMint(address[] memory marketmintaddress, uint256[] memory mintquantity) public payable callerIsUser onlyOwner {
        for (uint256 i = 0; i < marketmintaddress.length; i++) {
            require(totalSupply() + mintquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(marketmintaddress[i], mintquantity[i]);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

}
