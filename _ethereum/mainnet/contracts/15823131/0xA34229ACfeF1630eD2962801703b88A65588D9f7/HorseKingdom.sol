// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract HorseKingdom is ERC721A, Ownable {

    enum MintStatus {
        NOTACTIVE,
        WHITELIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    MintStatus public launchMintStatus;
    string  public baseTokenURI = "ipfs://bafybeiffaccyxx7hf5prrthbk6nmghtxjd3v5l7zqtk6qeqzjretvndvwq/";
    string  public defaultTokenURI;
    uint256 public maxSupply = 10000;
    uint256 public publicSalePrice = 0.003 ether;
    mapping(address => uint256) public usermint;

    address payable public payMent;


    constructor() ERC721A ("Horse Kingdom", "HK") {
        payMent = payable(msg.sender);
        _safeMint(msg.sender, 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function HorseKingdomMint(uint256 _quantity) external callerIsUser payable {
        require(launchMintStatus == MintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= 10, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        uint256 _remainFreeQuantity = 0;
        if (totalSupply()+_quantity<4000) {
            if (1 > usermint[msg.sender] ) {
                _remainFreeQuantity = 1 - usermint[msg.sender];
            }
        }

        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        usermint[msg.sender]+=_quantity;
        _safeMint(msg.sender, _quantity);
    }

    function getTokenIdsByWalletOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex <= ownerTokenCount && currentTokenId <= totalSupply()) {
            TokenOwnership memory ownerTokenOwnership =  _ownershipOf(currentTokenId);

            if (!ownerTokenOwnership.burned) {
                if (ownerTokenOwnership.addr != address(0)) {
                    latestOwnerAddress = ownerTokenOwnership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;
                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }
        return ownedTokenIds;
    }



    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    function setPublicPrice(uint256 _mintpublicprice) external onlyOwner {
        publicSalePrice = _mintpublicprice;
    }

    function setPublicMintStatus(uint256 _status) external onlyOwner {
        launchMintStatus = MintStatus(_status);
    }


    function airdrop(address[] memory _marketmintaddress, uint256[] memory _mintquantity) public payable onlyOwner {
        for (uint256 i = 0; i < _marketmintaddress.length; i++) {
            require(totalSupply() + _mintquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(_marketmintaddress[i], _mintquantity[i]);
        }
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

