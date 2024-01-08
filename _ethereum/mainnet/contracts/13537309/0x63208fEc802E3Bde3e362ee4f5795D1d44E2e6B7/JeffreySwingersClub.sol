// contracts/JeffreySwingersClub.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";

contract JeffreySwingersClub is ERC721, Ownable {
    string public lastWords = "";
    string public secret = "";
    string private baseURI = "ipfs://QmZhJojcaK4LBUvdHQqncSETvyxBaJmVhsNnH7ZZGThyEt/";

    uint256 public constant maxSupply = 666;
    uint256 public totalSupply = 0;

    uint256 public constant nftPrice = 6660000000000000000;
    uint256 public constant victimPrice = 6660000000000000000;
    uint256 public constant namePrice = 666000000000000000000;

    mapping(uint256 => string[]) private victims;
    mapping(uint256 => string) private names;

    event VictimNamed(
        address indexed _from,
        uint256 indexed _tokenId,
        string _name
    );

    event NFTNamed(
        address indexed _from,
        uint256 indexed _tokenId,
        string _name
    );

    event LastWordsUttered(
        address indexed _from,
        string _lastWords
    );

    event SecretWhispered(
        address indexed _from,
        string _secret
    );

    constructor() ERC721("JeffreySwingersClub", "JEFFREY") {
        _safeMint(msg.sender, 0);
        _safeMint(msg.sender, 1);
        _safeMint(msg.sender, 2);
        _safeMint(msg.sender, 3);
        _safeMint(msg.sender, 4);
        _safeMint(msg.sender, 5);
        _safeMint(msg.sender, 6);
        _safeMint(msg.sender, 7);

        totalSupply = 8;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_)
        public
        onlyOwner
    {
        baseURI = baseURI_;
    }

    function nameVictim(uint256 tokenId, string memory _name)
        public
        payable
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "You are not the owner");
        require(victimPrice <= msg.value, "Must send 6.66 ETH");

        victims[tokenId].push(_name);

        emit VictimNamed(msg.sender, tokenId, _name);
    }

    function nameNFT(uint256 tokenId, string memory _name)
        public
        payable
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "You are not the owner");
        require(bytes(names[tokenId]).length == 0, "NFT already named");
        require(victims[tokenId].length > 2, "Must name 3 victims first");
        require(namePrice <= msg.value, "Must send 666 ETH");

        names[tokenId] = _name;

        emit NFTNamed(msg.sender, tokenId, _name);
    }

    function whisperSecret(string memory _secret)
        public
        payable
    {
        require(bytes(secret).length == 0, "Too late, secret is already out");
        require(10000000000000000000000 <= msg.value, "Must send 10000 ETH");

        secret = _secret;

        emit SecretWhispered(msg.sender, secret);
    }

    function revealName(uint256 tokenId)
        public
        view
        returns(string memory)
    {
        require(_exists(tokenId), "Token ID does not exist");
        require(bytes(names[tokenId]).length > 0, "NFT not named");

        return names[tokenId];
    }

    function revealVictims(uint256 tokenId)
        public
        view
        returns(string[] memory)
    {
        require(_exists(tokenId), "Token ID does not exist");
        require(victims[tokenId].length > 0, "Victims not named");

        return victims[tokenId];
    }

    // WTF gas, no random for me
    function mintRandom()
        public
        payable
    {
        require(totalSupply < maxSupply, "All NFTs are minted. No soup for you!");

        require(!_exists(totalSupply), "Token already minted");
        require(nftPrice <= msg.value, "Must send 6.66 ETH");

        _safeMint(msg.sender, totalSupply);
        totalSupply ++; 
    }

    function withdraw()
        public
        onlyOwner
    {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function utterLastWords(string memory _lastWords)
        public
        onlyOwner
    {
        require(bytes(lastWords).length == 0, "Last words already uttered");

        lastWords = _lastWords;

        emit LastWordsUttered(msg.sender, _lastWords);
    }
}