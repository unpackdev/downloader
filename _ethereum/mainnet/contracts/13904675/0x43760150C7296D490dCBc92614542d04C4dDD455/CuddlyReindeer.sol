//SPDX-License-Identifier: MIT

// The Cuddly Reindeer collection consists of randomly generated NFTs on the Ethereum Blockchain,
// each one is completely unique. Cuddly Reindeer are exclusive, but there are some rarer than others.
// Each Cuddly Reindeer may include different fur, face, head accessory and attire - (and of course some special edition)
// Check more on @CuddlyReindeer on twitter

pragma solidity ^0.8.0;

import "./ERC721EnumerableLite.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CuddlyReindeer is ERC721EnumerableLite, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public maxSupply = 9876;
    bool public paused = false;

    constructor(string memory _initBaseURI) ERC721B("Cuddly Reindeer", "CR") {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    // Main mint method to adopt a Cuddly Reindeer
    function adopt(uint256 _numToMint) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Sale paused");
        require(_numToMint < 21, "You can mint a maximum of 20 Reindeer");
        require(
            supply + _numToMint <= maxSupply,
            "Exceeds maximum Reindeer supply"
        );
        uint256 costForMintingReindeers = getCostForMintingReindeers(
            _numToMint
        );
        require(
            msg.value >= costForMintingReindeers,
            "Please send correct amount of eth to mint"
        );
        // Just in case if user sends more eth than required to mint single/multiple
        if (msg.value > costForMintingReindeers) {
            payable(msg.sender).transfer(msg.value - costForMintingReindeers);
        }
        for (uint256 i = 0; i < _numToMint; ++i) {
            _safeMint(msg.sender, supply + i, "");
        }
    }

    // Define mint price single/multiple
    function getCostForMintingReindeers(uint256 _numToMint)
        public
        pure
        returns (uint256)
    {
        if (_numToMint == 1) {
            return 0.02 ether;
        } else if (_numToMint == 5) {
            return 0.075 ether;
        } else if (_numToMint == 10) {
            return 0.10 ether;
        } else if (_numToMint == 20) {
            return 0.15 ether;
        } else {
            return _numToMint * .02 ether;
        }
    }

    function gift(uint256[] calldata _quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            _quantity.length == recipient.length,
            "Must provide equal quantities and recipients"
        );

        uint256 totalQuantity = 0;
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < _quantity.length; ++i) {
            totalQuantity += _quantity[i];
        }
        require(
            supply + totalQuantity <= maxSupply,
            "Mint/order exceeds Reindeer supply"
        );
        delete totalQuantity;

        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < _quantity[i]; ++j) {
                _safeMint(recipient[i], supply++, "");
            }
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; ++i) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBase = _baseURI();
        if (bytes(currentBase).length > 0) {
            return string(abi.encodePacked(currentBase, _tokenId.toString()));
        }
        return "";
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(
            maxSupply != _newMaxSupply,
            "New value matches current Max Reindeer Supply"
        );
        require(
            _newMaxSupply >= totalSupply(),
            "New value should be greater than current adopted Reindeer"
        );
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        uint256 _balace = address(this).balance;
        require(payable(msg.sender).send(_balace));
    }
}
