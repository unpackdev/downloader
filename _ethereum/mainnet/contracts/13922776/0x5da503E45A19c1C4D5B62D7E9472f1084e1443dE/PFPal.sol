//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract PFPals is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPPLY = 8000;
    uint256 public constant RESERVE_SUPPLY = 200;
    uint256 public constant FREE_SUPPLY = 100;
    uint256 public constant MAX_PER_MINT = 5;

    uint256 public constant PRICE = 0.05 ether;

    bool public publicActive = false;
    bool public whiteListActive = false;

    string public baseTokenURI;
    bytes32 public merkleRoot;

    mapping(address => bool) freeClaimed;
    mapping(address => bool) whitelistClaimed;

    constructor(string memory baseURI) ERC721("pfpal", "PFPAL") {
        setBaseURI(baseURI);
    }

    function freeMint() public {
        uint256 totalMinted = _tokenIds.current();
        require(!freeClaimed[msg.sender], "Wallet already claimed free mint.");
        require(totalMinted.add(1) <= FREE_SUPPLY, "Not enough NFTs left!");
        _mintSingleNFT();

        freeClaimed[msg.sender] = true;
    }

    function whitelistMint(uint256 _count, bytes32[] calldata _merkleProof)
        public
        payable
    {
        uint256 totalMinted = _tokenIds.current();
        require(whiteListActive, "Sale must be active to mint Tokens");
        require(
            !whitelistClaimed[msg.sender],
            "Wallet already claimed whitelist mint."
        );
        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(
            _count > 0 && _count <= 2,
            "Cannot mint specified number of NFTs."
        );
        require(
            msg.value >= PRICE.mul(_count),
            "Not enough ether to purchase NFTs."
        );

        // check for whitelist
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not on Whitelist"
        );

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }

        whitelistClaimed[msg.sender] = true;
    }

    function reserveNFTs(uint256 _count) public onlyOwner {
        uint256 totalMinted = _tokenIds.current();

        require(
            totalMinted.add(_count) < MAX_SUPPLY,
            "Not enough NFTs left to reserve"
        );

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function setSaleState(bool newState) public onlyOwner {
        publicActive = newState;
    }

    function setWhitelistState(bool newState) public onlyOwner {
        whiteListActive = newState;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleroot) public onlyOwner {
        merkleRoot = _merkleroot;
    }

    function mintNFTs(uint256 _count) public payable {
        uint256 totalMinted = _tokenIds.current();
        require(publicActive, "Sale must be active to mint Tokens");
        require(
            totalMinted.add(_count) <= (MAX_SUPPLY - RESERVE_SUPPLY),
            "Not enough NFTs left!"
        );
        require(
            _count > 0 && _count <= MAX_PER_MINT,
            "Cannot mint specified number of NFTs."
        );
        require(
            msg.value >= PRICE.mul(_count),
            "Not enough ether to purchase NFTs."
        );

        for (uint256 i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function remainingSupply() public view returns (uint256) {
        uint256 totalMinted = _tokenIds.current();
        return MAX_SUPPLY - totalMinted;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
