// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PuppetParts is ERC721A, Ownable {
    string public partsBaseURI;
    bool public saleIsActive = false;
    uint256 public maxPartSupply = 3000;
    address public PuppetStarsContract;
    mapping (address => uint256) public mintedByWallet;
    
    /*
    ** mint 1 - 0.02 ether / mint 2 - 0.04 ether / mint 3 - 0.0495 ether
    ** mint 4 - 0.056 ether / mint 5 - 0.058 ether / mint 6 - 0.06 ether
    */
    uint256[] public priceByMintAmount = [20000000000000000, 40000000000000000,
                                          49500000000000000, 56000000000000000,
                                          58000000000000000, 60000000000000000];

    constructor (string memory _initPartsBaseUri) ERC721A("PuppetParts", "Partz") {
        setPartsBaseURI(_initPartsBaseUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return partsBaseURI;
    }

    // public & external
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        
        return tokenIds;
    }

    function burnParts(uint256[6] memory _partsId, address _from) external {
        require(msg.sender == PuppetStarsContract,            "Not Allow");
        for(uint256 i; i < 6; i++) {
            require(ownerOf(_partsId[i]) == _from,            "You not owner of token");
        }
        require(_partsId[0] % 6 == 1,                         "First part must be Background");
        require(_partsId[1] % 6 == 2,                         "Second part must be Base");
        require(_partsId[2] % 6 == 3,                         "Third part must be Eyes");
        require(_partsId[3] % 6 == 4,                         "Fourth part must be Hair");
        require(_partsId[4] % 6 == 5,                         "Fifth part must be Cloth");
        require(_partsId[5] % 6 == 0,                         "Sixth part must be Accs");

        for(uint256 j = 0; j < 6; j++) {
            _burn(_partsId[j]);
        }
    }

    function mintParts(uint256 _quantity) external payable {
        require(saleIsActive,                                      "Not Allow");
        require(_quantity > 0 && _quantity <= 6,                   "Incorrect quantity");
        require(priceByMintAmount[_quantity - 1] == msg.value,     "Ether value incorrect");
        require(totalSupply() + _quantity <= maxPartSupply,        "Quantity exceed total supply");
        require(mintedByWallet[msg.sender] + _quantity <= 18,      "Each wallet can mint max 18");

        mintedByWallet[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    //only Owner
    function setPartsBaseURI(string memory _newBaseUri) public onlyOwner {
        partsBaseURI = _newBaseUri;
    }

    function flipSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPrice(uint256 _position, uint256 _newPrice) external onlyOwner {
        priceByMintAmount[_position] = _newPrice;
    }

    function setPuppetStarsContract(address _contract) external onlyOwner {
        PuppetStarsContract = _contract;
    }

    function devMint(uint256 _quantity) external onlyOwner {
        require(_quantity % 6 == 0,  "Only can min per batch size");
        uint256 numChuncks = _quantity / 6;
        for (uint256 i; i < numChuncks; i++) {
            _safeMint(msg.sender, 6);
        }
    }

    function devWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0,  "No more balance");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}