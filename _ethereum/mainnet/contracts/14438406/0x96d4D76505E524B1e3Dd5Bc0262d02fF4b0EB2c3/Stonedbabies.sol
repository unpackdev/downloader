// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibRoyaltiesV2.sol";
import "./LibRoyalties2981.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract Stonedbabies is ERC721, ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.1 ether;
    uint256 public maxSupply = 6666;
    bool public revealed = false;
    bool public paused = true;
    string public notRevealedUri;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721("Stonedbabies", "SB") {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), baseExtension)) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable {
        require(_mintAmount > 0, "Mint amount must be greater than 0");
        require(!paused, "Minting is paused");
        require(totalSupply() + _mintAmount <= maxSupply, "All NFTs have been minted");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Insufficient funds to mint");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            setRoyalties(tokenId, payable(owner()), 1000);
        }

        if (totalSupply() == 500) {
            giveaway(2 ether);
        } else if (totalSupply() == 1000) {
            giveaway(3 ether);
        } else if (totalSupply() == 1500) {
            giveaway(3.5 ether);
        } else if (totalSupply() == 2000) {
            giveaway(4 ether);
        } else if (totalSupply() == 3000) {
            giveaway(5 ether);
        } else if (totalSupply() == 4000) {
            giveaway(5 ether);
        } else if (totalSupply() == 5000) {
            giveaway(6 ether);
        } else if (totalSupply() == 6666) {
            giveaway(8 ether);
        }
    }

    function setRoyalties(uint256 _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].account = _royaltiesRecipientAddress;
        _royalties[0].value = _percentageBasisPoints;
        _saveRoyalties(_tokenId, _royalties);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == LibRoyalties2981._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");

        require(success, "Transfer failed.");
    }

    function giveaway(uint256 amount) internal {
        uint256 winnerIndex = createRandomNumber(totalSupply() + 1);

        (bool success, ) = payable(ownerOf(winnerIndex)).call{value: amount}("");

        require(success, "Giveaway transfer failed.");
    }

    function createRandomNumber(uint256 number) internal view returns (uint256) {
        return uint256(blockhash(block.number - 1)) % number;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}
