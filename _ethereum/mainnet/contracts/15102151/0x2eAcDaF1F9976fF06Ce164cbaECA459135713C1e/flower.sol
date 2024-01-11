// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";


contract Flower is ERC721A, Ownable {
    using Strings for uint256;

    enum EPublicMintStatus {
        CLOSED,
        PUBLIC_MINT
    }
    EPublicMintStatus public publicMintStatus;

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply = 9000;
    uint256 public publicSalePrice = 0.0035 ether;
    uint256 public totalFree = 1000;

    constructor(
        string memory _baseTokenURI
    ) ERC721A("International Flower", "IF") {
        baseTokenURI = _baseTokenURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser payable  {
        require(publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity > 0, "Invalid quantity");
        require(_quantity <= 10, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        uint256 _remainFreeQuantity = 0;
        if (totalFree > totalSupply() ) {
            _remainFreeQuantity = totalFree - totalSupply();
        }

        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        _safeMint(msg.sender, _quantity);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                ".json"
            )
        ) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }


    function setPublicMintStatus(uint256 status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(status);
    }


    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }


    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    struct reversemint {
        address reverseaddress;
        uint256 mintquantity;
    }

    function marketmint(reversemint[] memory _reversemintinfos) public  payable onlyOwner {
        for (uint256 i = 0; i < _reversemintinfos.length; i++) {
            require(totalSupply() + _reversemintinfos[i].mintquantity <= 1000, "Exceed supply");
            _safeMint(_reversemintinfos[i].reverseaddress, _reversemintinfos[i].mintquantity);
        }
    }

}

