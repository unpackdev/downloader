// SPDX-License-Identifier: MIT

/*
___________      .__           _____
\__    ___/____  |__|   ______/ ____\___________  ______
  |    |  \__  \ |  |  /     \   __\/ __ \_  __ \/  ___/
  |    |   / __ \|  | |  Y Y  \  | \  ___/|  | \/\___ \
  |____|  (____  /__| |__|_|  /__|  \___  >__|  /____  >
               \/           \/          \/           \/

*/

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";

contract taimfers is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;
    uint public FREE_MINTS;
    uint public FREE_MINTS_REMAINING;
    uint public SUPPLY;
    uint public MINT_MAX;
    uint public MINT_PRICE;//Add mint price

    constructor(address payable shareholderAddress_, uint supply, uint freeMints, uint mintMax,
        uint mintPrice, string memory baseURI_, bool saleState) ERC721("Tai mfers", "mfn Tai") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
        FREE_MINTS = freeMints;
        FREE_MINTS_REMAINING = FREE_MINTS;
        SUPPLY = supply;
        MINT_MAX = mintMax;
        MINT_PRICE = mintPrice;
        _baseURIextended = baseURI_;
        saleIsActive = saleState;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setMintMaximum(uint mintLimit) public onlyOwner returns(bool) {
        MINT_MAX = mintLimit;
        return true;
    }

    function reserve(address [] memory reserveAddresses, uint [] memory reserveAmountArr) public onlyOwner {
        require(reserveAddresses.length == reserveAmountArr.length);
        uint supply = totalSupply() + 1;
        uint index = 0;

        for (uint j=0; j < reserveAmountArr.length; j++) {
            address airdropAddress = reserveAddresses[j];
            if(airdropAddress != address(0)) {
                uint reserveAmount = reserveAmountArr[j];
                for (uint i = 0; i < reserveAmount; i++) {
                    _safeMint(airdropAddress, supply + index);
                    index = index + 1;
                }
            }
        }
    }

    function changeMintPrice(uint mintPrice) public onlyOwner returns (bool) {
        MINT_PRICE = mintPrice;
        return true;
    }

    function addFreeMints(uint freeMintsToAdd) public onlyOwner returns (bool) {
        FREE_MINTS_REMAINING = FREE_MINTS_REMAINING + freeMintsToAdd;
        FREE_MINTS = FREE_MINTS + freeMintsToAdd;
        return true;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MINT_MAX, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= SUPPLY, "Purchase would exceed max supply of tokens");


        if (FREE_MINTS_REMAINING >= numberOfTokens) {
            FREE_MINTS_REMAINING = FREE_MINTS_REMAINING - numberOfTokens;
            for(uint i = 0; i < numberOfTokens; i++) {
                uint mintIndex = totalSupply() + 1;
                if (totalSupply() < SUPPLY) {
                    _safeMint(msg.sender, mintIndex);
                }
            }
            return;
        } else {
            if(FREE_MINTS_REMAINING == 0) {
                require(MINT_PRICE * numberOfTokens <= msg.value, "Ether value doesn't cover mint cost");
                for(uint i = 0; i < numberOfTokens; i++) {
                    uint mintIndex = totalSupply() + 1;
                    if (totalSupply() < SUPPLY) {
                        _safeMint(msg.sender, mintIndex);
                    }
                }
            } else {
                int freeMintsDiff = int(FREE_MINTS_REMAINING) - int(numberOfTokens);
                int freeMints = int(numberOfTokens) + freeMintsDiff;
                int paidMints = int(numberOfTokens) - freeMints;

                for(int i = 0; i < freeMints; i++) {
                    uint mintIndex = totalSupply() + 1;
                    if (totalSupply() < SUPPLY) {
                        _safeMint(msg.sender, mintIndex);
                    }
                }
                FREE_MINTS_REMAINING = 0;

                require(MINT_PRICE * uint(paidMints) <= msg.value, "Free mints are done. Ether value doesn't cover mint cost");
                for(int i = 0; i < paidMints; i++) {
                    uint mintIndex = totalSupply() + 1;
                    if (totalSupply() < SUPPLY) {
                        _safeMint(msg.sender, mintIndex);
                    }
                }
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }
}