// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

contract OnlyKevin is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;

    uint128 public _releaseTimestamp;
    uint64 public immutable _maxSupply;
    uint64 private immutable _maxMintAmount = 2;
    bool private _treasuryMint;
    string public _baseTokenURI =
        "ipfs://bafybeifksx5guif35ghoz64j3yzrwxvkaqrofjqhqhy46syabyq42ygjjm/";

    address public constant xKevin = 0x34584DF6874314784B6dd7428333d792C372532c;

    mapping(address => uint16) public addressMintBalance;

    receive() external payable {}

    fallback() external payable {}

    constructor(uint128 releaseTimestamp, uint64 maxSupply)
        ERC721A("OnlyKevin", "OLYKVN")
    {
        _releaseTimestamp = releaseTimestamp;
        _maxSupply = maxSupply;
    }

    function mintCompliance(uint256 quantity) private {
        require(msg.value == 0, "Incorrect payment");
        require(
            quantity > 0 && quantity <= _maxMintAmount,
            "Invalid mint amount"
        );
        require(
            totalSupply() + quantity <= _maxSupply,
            "Maximum supply exceeded"
        );
        require(block.timestamp > _releaseTimestamp, "It is not yet your time");
    }

    /**
     * @dev minting function, balance tracking only relevant for Soundlist.
     * TX validation done inside {mintCompliance}.
     */
    function publicMint(uint8 quantity) public payable {
        mintCompliance(quantity);
        require(
            addressMintBalance[msg.sender] + quantity <= _maxMintAmount,
            "Sorry, you can't mint any more tokens"
        );
        addressMintBalance[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function setReleaseTimestamp(uint128 releaseTimestamp) public onlyOwner {
        _releaseTimestamp = releaseTimestamp;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function treasuryMint(uint256 quantity) public onlyOwner {
        require(!_treasuryMint, "Treasury mint can only be done once");
        require(quantity > 0, "Invalid mint amount");
        require(
            totalSupply() + quantity <= _maxSupply,
            "Maximum supply exceeded"
        );
        _safeMint(msg.sender, quantity);
        _treasuryMint = true;
    }

    function withdraw() public onlyOwner nonReentrant {
        Address.sendValue(payable(xKevin), address(this).balance);
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
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    (_tokenId + 1).toString(),
                    ".json"
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
