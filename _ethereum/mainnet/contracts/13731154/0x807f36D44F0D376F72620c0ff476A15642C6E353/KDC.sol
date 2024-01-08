// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./Counters.sol";

contract KDC is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public _nextTokenId;

    address private owner;

    string public _baseTokenUri;
    bool public _paused = true;
    uint256 public _maxBeats = 909; // TR-909
    uint256 private _price = 0.0303 ether; // TR-303 bass price

    event BeatMint(uint256 indexed tokenId);

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(string memory baseURI) ERC721("Kopenicker Dance Club", "KDC") {
        owner = msg.sender;
        setBaseURI(baseURI);
        _nextTokenId.increment();
        // Mint 4 for us & 5 to give away
        mint(owner, 1);
        mint(owner, 2);
        mint(owner, 3);
        mint(owner, 4);
        mint(owner, 5);
        mint(owner, 6);
        mint(owner, 7);
        mint(owner, 8);
        mint(owner, 9);
    }

    function mint(address _to, uint256 _tokenId) internal {
        _nextTokenId.increment();
        _safeMint(_to, _tokenId);
        emit BeatMint(_tokenId);
    }

    function mintBeats(uint256 _amount) public payable {
        require(!_paused, "KDC sale is paused");

        uint256 mintIndex = _nextTokenId.current();

        require(mintIndex <= _maxBeats, "Not enough beats left");
        require(msg.value >= _price * _amount, "Not enough ETH");
        require(_amount < 101, "Max 100 beats per tx");

        for(uint256 i = 0; i < _amount; i++) {
            mint(msg.sender, mintIndex + i);
            emit BeatMint(mintIndex + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory)  {
        return _baseTokenUri;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenUri = baseURI;
    }

    function totalBeats() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(payable(owner).send(amount));
    }

    function pause(bool _pause) public onlyOwner {
        _paused = _pause;
    }
}
