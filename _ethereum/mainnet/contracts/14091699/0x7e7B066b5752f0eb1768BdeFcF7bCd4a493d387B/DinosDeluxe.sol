// SPDX-License-Identifier: MIT

/*
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
 * @title DinosDeluxe contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract DinosDeluxe is ERC721, Ownable {

    bool public saleIsActive = false;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;
    address payable private marketingAddress = payable(0x83870Cc61e00627d785167CB8b92cb5e4e23b967);
    address payable private marketingAddress2 = payable(0x1e1f01944A4Ab1c3A8a357AD3B7624C54d18b78a);

    string public PROVENANCE;
    uint256 public publicTokenPrice = 0.03 ether;

    uint256 public maxSupply = 3000;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    constructor(address payable shareholderAddress_) ERC721("DinosDeluxe", "DINOSDELUXE") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;

        // TEST MINT
        for(uint i = 0; i < 10; i++) {
            _safeMint(msg.sender, _tokenSupply.current());
            _tokenSupply.increment();
        }

        // TEST MINT
        for(uint i = 0; i < 50; i++) {
            _safeMint(marketingAddress, _tokenSupply.current());
            _tokenSupply.increment();
        }

        // TEST MINT
        for(uint i = 0; i < 15; i++) {
            _safeMint(marketingAddress2, _tokenSupply.current());
            _tokenSupply.increment();
        }
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

    function updateMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function mint(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens < 21, "Exceeded max token purchase");

        require(_tokenSupply.current() + numberOfTokens < maxSupply, "Purchase would exceed max supply of tokens");
        
        if (_tokenSupply.current() + numberOfTokens > 500) {
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