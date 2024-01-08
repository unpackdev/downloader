// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";

contract BinaryXTickTack is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _ownerReserve;

    uint256 public constant MAX_SUPPLY = 1010;
    uint256 public constant MINTING_LIMIT = 25;
    uint256 public constant OWNER_RESERVE = 25;
    uint256 public mintingFee = 0.07 ether;

    string public baseURI;
    bool public mintingLive = false;
    address payable vault;

    constructor() ERC721("Binary X Tick Tack", "BXTT") {
        vault = payable(msg.sender);
    }

    function mint(uint256 _qty) public payable returns (bool) {
        require(mintingLive, "Minting has not yet started");
        uint256 _value = msg.value;
        uint256 supply = MAX_SUPPLY - _tokenIdCounter.current() - OWNER_RESERVE;
        require(supply >= _qty, "Not Enough Left");
        require(_qty <= MINTING_LIMIT, "Minting Too Many");
        require(_value >= (mintingFee * _qty), "Send more ether");
        payable(vault).transfer(_value);

        for (uint256 i = 0; i < _qty; i++) {
            if ((_tokenIdCounter.current() + OWNER_RESERVE) < MAX_SUPPLY)
                safeMint(msg.sender);
        }

        return true;
    }

    function safeMint(address to) private returns (uint256) {
        uint256 nextId = _tokenIdCounter.current() + OWNER_RESERVE;
        require(nextId < MAX_SUPPLY, "Sold Out");
        _safeMint(to, nextId);
        _tokenIdCounter.increment();
        return nextId;
    }

    function ownerMint(address _mintTo, uint256 _qty)
        public
        onlyOwner
        returns (bool)
    {
        require(_qty <= MINTING_LIMIT, "Minting too many");

        for (uint256 i = 0; i < _qty; i++) {
            if (_ownerReserve.current() < OWNER_RESERVE) {
                _ownerMint(_mintTo);
            }
        }

        return true;
    }

    function startSale() public onlyOwner {
        mintingLive = true;
    }

    function stopSale() public onlyOwner {
        mintingLive = false;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _ownerMint(address _mintTo) private returns (uint256) {
        uint256 nextId = _ownerReserve.current();
        require(nextId < OWNER_RESERVE, "All Boards Minted");
        _safeMint(_mintTo, nextId);
        _ownerReserve.increment();
        return nextId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory _uri)
    {
        return
            string(
                abi.encodePacked(baseURI, convertToString(tokenId), ".json")
            );
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function convertToString(uint256 value)
        internal
        pure
        returns (string memory)
    {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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
}
