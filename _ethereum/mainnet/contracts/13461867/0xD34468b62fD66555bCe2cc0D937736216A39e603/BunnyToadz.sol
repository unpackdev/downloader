// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract BunnyToadz is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event MintNFT(address indexed sender, uint256 startWith, uint256 times);

    //supply counters
    uint256 public totalNfts;
    // MAX_SUPPLY
    uint256 public MAX_SUPPLY = 6969;
    //token Index tracker
    uint256 public MAX_BY_MINT = 10;
    uint256 public price = 50000000000000000;

    string public baseURI = "";
    bool private started;

    //constructor args
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString()))
                : "";
    }

    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function mint(uint256 _times) public payable {
        require(started, "not started");
        require(
            _times > 0 && _times <= MAX_BY_MINT,
            "must mint fewer in each mint"
        );
        require(totalNfts + _times <= MAX_SUPPLY, "max supply reached!");
        require(
            msg.value == _times * price,
            "value error, please check price."
        );
        payable(owner()).transfer(msg.value);
        emit MintNFT(_msgSender(), totalNfts + 1, _times);
        for (uint256 i = 0; i < _times; i++) {
            _mint(_msgSender(), totalNfts++);
        }
    }
}
