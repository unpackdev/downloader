// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract DepressedDucks is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    string public DUCK_PROVENANCE = ""; // IPFS added once sold out
    string public LICENSE_TEXT = "Depressed Ducks is a community cursed with knowledge";
    bool licenseLocked = false;
    uint public constant maxDuckPurchase = 10;
    uint256 public constant MAX_DUCKS = 10000;
    bool public saleIsActive = false;
    
    uint256 private _duckPrice = 20000000000000000; // 0.02 ETH
    string private baseURI;
    uint private _duckReserve = 300;

    mapping(uint => string) public duckNames;

    event licenseisLocked(string _licenseText);

    constructor() ERC721("Depressed Ducks", "DD") { }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _duckPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _duckPrice;
    }
    
    function reserveDucks(address _to, uint256 _reserveAmount) public onlyOwner {
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= _duckReserve, "Reserve limit has been reached");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        _duckReserve = _duckReserve.sub(_reserveAmount);
    }


    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        DUCK_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Choose a Duck in supply range");
        return LICENSE_TEXT;
    }

    // Locks the license to prevent further changes
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }

    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }


    function mintDepressedDuck(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Duck");
        require(numberOfTokens > 0 && numberOfTokens <= maxDuckPurchase, "Oops - you can only mint 10 ducks at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_DUCKS, "Purchase exceeds max supply of Ducks");
        require(msg.value >= _duckPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_DUCKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }

    }


    // All ducks in wallet
    function duckNamesOfOwner(address _owner) external view returns(string[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new string[](0);
        } else {
            string[] memory result = new string[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = duckNames[ tokenOfOwnerByIndex(_owner, index) ] ;
            }
            return result;
        }
    }

}