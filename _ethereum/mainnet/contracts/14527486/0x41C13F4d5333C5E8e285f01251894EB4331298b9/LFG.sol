// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract LFGPass is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.08 ether;
    uint256 public maxSupply = 3333;
    uint256 public maxSupplyForPresale = 1000;
    uint256 public maxMintAmount = 5;
    uint256 public nftPerWhitelistAddressLimit = 2;
    bool public paused = false;
    bool public onlyPresale = true;
    bytes32 private whitelistMerkleRoot;

    mapping(address => uint256) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "min mint is 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(!onlyPresale, "Presale is on");
            require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
        require(!paused, "the contract is paused");
        require(onlyPresale, "Presale is false");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "min mint is 1 NFT");
        require(supply + _mintAmount <= maxSupplyForPresale, "max NFT limit for presale exceeded");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        require(
            ownerMintedCount + _mintAmount <= nftPerWhitelistAddressLimit,
            "max NFT per whitelist address exceeded"
        );

        // Check if user is whitelisted
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Proof, User not whitelisted");

        require(msg.value >= cost * _mintAmount, "insufficient funds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function setWhitelistMerkleRoot(bytes32 root) external onlyOwner {
        whitelistMerkleRoot = root;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNftPerWhitelistAddressLimit(uint256 _limit) public onlyOwner {
        nftPerWhitelistAddressLimit = _limit;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyPresale(bool _state) public onlyOwner {
        onlyPresale = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool community, ) = payable(0x4eC96EBaDe794CC0c420b9429188d8483f958785).call{
            value: (address(this).balance * 8) / 10
        }("");
        require(community);

        (bool a, ) = payable(0x94eA70cf4318E26D4b398f062637512387Db76eF).call{value: (address(this).balance * 6) / 10}(
            ""
        );
        require(a);

        (bool b, ) = payable(0x58fC319b64C4375052AA84Dd07c5785a5910C7Ce).call{value: address(this).balance}("");
        require(b);
    }
}
