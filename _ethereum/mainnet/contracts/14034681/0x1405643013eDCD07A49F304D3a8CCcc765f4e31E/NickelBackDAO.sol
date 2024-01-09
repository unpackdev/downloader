// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
 * @title DadMfers contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NickelBackDAO is ERC721, Ownable {

    bool public saleIsActive = false;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;

    string public PROVENANCE;

    uint256 public publicTokenPrice = 0.03 ether;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    constructor(address payable shareholderAddress_) ERC721("NickelbackDAO", "NCKLBCK") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
    }

    function totalSupply() public view returns (uint256 supply) {
        return _tokenSupply.current();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function isSaleActive() external view returns (bool) {
        return saleIsActive;
    }

    function updatePublicPrice(uint256 newPrice) public onlyOwner {
        publicTokenPrice = newPrice;
    }

    function mint(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens < 11, "Exceeded max token purchase");

        require(_tokenSupply.current() + numberOfTokens < 1000, "Purchase would exceed max supply of tokens");
        
        if (_tokenSupply.current() + numberOfTokens > 250) {
            require((publicTokenPrice * numberOfTokens) <= msg.value, "Ether value sent is not correct");
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _tokenSupply.current());
            _tokenSupply.increment();
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }

}