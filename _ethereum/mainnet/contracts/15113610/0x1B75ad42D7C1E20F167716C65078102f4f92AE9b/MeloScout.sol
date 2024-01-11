// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract MeloScoutNFT is ERC721A, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint256 public preSalePrice = 0.38 ether;
    uint256 public publicSalePrice = 0.4 ether;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public publicSaleStartTime;
    uint256 public publicSaleEndTime;
    uint256 public maxPublicMintAmountPerTx = 5;
    bytes32 public root;
    address payable public safe =
        payable(0x0d50f333BeB3d1f012b8A1D7eA1332962E223dA9);
    uint256 public constant MAX_SUPPLY = 888;
    string public baseTokenURI;
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    mapping(address => uint256) preSaleMintedAmount;
    mapping(address => uint256) publicMintedAmount;

    constructor(
        string memory _newBaseURI,
        uint256 _preSaleStartTime,
        uint256 _preSaleEndTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime
    ) ERC721A("MeloScoutNFT", "MSNFT") {
        baseTokenURI = _newBaseURI;
        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
    }

    modifier checkMaxSupply(uint256 _amount) {
        require(totalSupply() + _amount <= MAX_SUPPLY, "exceeds total supply");
        _;
    }

    modifier validateProof(bytes32[] calldata _proof) {
        require(
            ERC721A._numberMinted(msg.sender) < 1,
            "NFT has been minted to this wallet already"
        );

        require(
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "your wallet is not in our whitelist"
        );
        _;
    }

    function devMint(address _to, uint256 _amount)
        public
        onlyOwner
        checkMaxSupply(_amount)
    {
        _safeMint(_to, _amount);
    }

    function setRoot(bytes32 _newRoot) public onlyOwner {
        root = _newRoot;
    }

    function setSafe(address payable _newSafe) public onlyOwner {
        safe = _newSafe;
    }

    function setPrice(uint256 _newPreSalePrice, uint256 _newPublicSalePrice) public onlyOwner {
        preSalePrice = _newPreSalePrice;
        publicSalePrice = _newPublicSalePrice;
    }

    function setPreSaleTime(uint256 _newStartTime, uint _newEndTime) public onlyOwner {
        preSaleStartTime = _newStartTime;
        preSaleEndTime = _newEndTime;
    }

    function setPublicSaleTime(uint256 _newStartTime, uint _newEndTime) public onlyOwner {
        publicSaleStartTime = _newStartTime;
        publicSaleEndTime = _newEndTime;
    }

    function setMaxPublicMintAmountPerTx(uint256 _amount) public onlyOwner {
        maxPublicMintAmountPerTx = _amount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdrawToSafe() public onlyOwner {
        require(address(safe) != address(0), "safe address not set");

        safe.transfer(address(this).balance);
    }
    
    function preSaleMint(bytes32[] calldata _proof)
        public
        payable
        checkMaxSupply(1)
        validateProof(_proof)
        nonReentrant
    {
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp <= preSaleEndTime,
            "presale is not opening yet"
        );
        require(
            preSaleMintedAmount[msg.sender] <= 1,
            "exceeds max allowable amount"
        );
        require(msg.value == preSalePrice, "incorrect payment");
        preSaleMintedAmount[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function publicMint(uint _amount)
        public
        payable
        checkMaxSupply(_amount)
        nonReentrant
    {
        require(_amount > 0, "need to mint at least 1 NFT");
        require(_amount <= maxPublicMintAmountPerTx, "exceeds max amount per tx");
        require(
            block.timestamp >= publicSaleStartTime &&
                block.timestamp <= publicSaleEndTime,
            "public sale is not opening yet"
        );
        uint256 cost = publicSalePrice * _amount;
        require(msg.value == cost, "incorrect payment");
        _safeMint(msg.sender, _amount);
    }
}