//SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.0;

import "./Ownables.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract FancyMrFox is ERC721, ERC721Enumerable, Ownables {

    using SafeMath for uint256;

    string private _metadataAPI;
    
    uint256 private constant _MINT_PRICE = 0.01 ether;
    uint256 private constant _MINT_SUPPLY = 4444;

    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        string memory initMetadataAPI_,
        address secondOwner_
    ) ERC721(tokenName_, tokenSymbol_) {

        _metadataAPI = initMetadataAPI_;
        _setSecondOwner(secondOwner_);

    }

    function _mintTokens(uint256 numberOfTokens_) internal {
        
        for (uint256 index = 0; index < numberOfTokens_; index++) {
            _safeMint(msg.sender, totalSupply());
        }

    }

    function mintTokens(uint256 numberOfTokens_) public payable {
        
        require(totalSupply().add(numberOfTokens_) <= _MINT_SUPPLY, "Exceeds max supply");
        require(msg.value >= _MINT_PRICE.mul(numberOfTokens_)  ,  "Invalid ether value");

        _mintTokens(numberOfTokens_);

    }

    function setMetadataAPI(string memory newMetadataAPI_) public onlyOwner {

        _metadataAPI = newMetadataAPI_;

    }


    function _baseURI() internal view override returns(string memory) {
        return _metadataAPI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}


}