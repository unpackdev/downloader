// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC165.sol";
import "./Strings.sol";

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

contract BryceYoung is Ownable, ERC165, ICreatorExtensionTokenURI {

    using Strings for uint256;
    using Strings for uint;

    string public PROVENANCE = "";
    uint256 public constant MAX_SUPPLY = 3626;
    uint256 public constant TOKEN_PRICE = 0.1 ether;
    uint public constant MAX_PURCHASE = 250;
    bool public saleIsActive = false;

    string private _baseURIextended;
    address private _creator;
    uint private _numMinted;
    mapping(uint256 => uint) _tokenEdition;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked(_baseURIextended, (_tokenEdition[tokenId] - 1).toString()));
    }

    function totalSupply() external view returns (uint) {
        return _numMinted;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintThroughCreator(address to) private {
        _numMinted += 1;
        _tokenEdition[IERC721CreatorCore(_creator).mintExtension(to)] = _numMinted;
    }

    function reserve(uint numberOfTokens) public onlyOwner {        
        for (uint i = 0; i < numberOfTokens; i++) {
            mintThroughCreator(msg.sender);
        }
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint token");
        require(numberOfTokens <= MAX_PURCHASE, "Exceeded max purchase amount");
        require(_numMinted + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (_numMinted < MAX_SUPPLY) {
                mintThroughCreator(msg.sender);
            }
        }
   }
}
