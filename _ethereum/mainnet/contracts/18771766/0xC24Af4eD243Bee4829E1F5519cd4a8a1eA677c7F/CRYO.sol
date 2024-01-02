// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract CryoClone is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant WL_MINT_LIMIT = 1516;
    uint256 public constant RESERVED_MINT_LIMIT = 1000;
    uint256 public constant FCFS_MINT_LIMIT = 1817;
    uint256 public constant TEAM_MINT_LIMIT = 111;

    uint256 public constant WL_PRICE = 0.077 ether; // 0.077 ETH
    uint256 public constant RESERVED_PRICE = 0.088 ether; // 0.088 ETH
    uint256 public constant FCFS_PRICE = 0.099 ether; // 0.099 ETH

    uint256 public teamMinted;

    bytes32 public wlMerkleRoot;
    bytes32 public reservedMerkleRoot;

    uint256 public wlMinted;
    uint256 public reservedMinted;
    uint256 public fcfsMinted;

    uint256 public listedMintEndTime;

    string public uriPrefix =
        "https://bafybeievgxxhsghyx2ahp4ipof2dio4yhpcwzj55m7y6gpdulontclh6ee.ipfs.nftstorage.link/";
    string public uriSuffix = ".json";

    // Events
    event MerkleRoots(bytes32 wlMerkleRoot, bytes32 reservedMerkleRoot);
    event Withdrawn(address _to, uint256 amount);
    event MintWL(address _to, uint256 amount);
    event MintReserved(address _to, uint amount);
    event MintFCFS(address _to, uint amount);
    event MintAdmin();

    constructor() ERC721A("Cryo Clone", "CRYO") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Non-existent token given!");

        uint id = _tokenId;
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, id.toString(), uriSuffix)
                )
                : "";
    }

    function mintWL(
        bytes32[] memory proof,
        uint256 mintAmount
    ) external payable nonReentrant whenNotPaused {
        require(block.timestamp <= listedMintEndTime, "WL mint Not available");
        require(
            wlMinted + mintAmount <= WL_MINT_LIMIT,
            "Exceeds WL limit"
        );
        require(msg.value >= WL_PRICE * mintAmount, "Insufficient funds");
        require(
            MerkleProof.verify(proof, wlMerkleRoot, _getLeaf(msg.sender)),
            "Invalid Merkle proof"
        );

        _mint(msg.sender, mintAmount);
        wlMinted += mintAmount;

        if (totalSupply() >= WL_MINT_LIMIT + RESERVED_MINT_LIMIT) {
            listedMintEndTime = block.timestamp;
        }
        emit MintWL(msg.sender, mintAmount);
    }

    function mintReserved(
        bytes32[] memory proof,
        uint256 mintAmount
    ) external payable nonReentrant whenNotPaused {
        require(
            block.timestamp <= listedMintEndTime,
            "Reserved Mint Not available"
        );
        require(
            reservedMinted + mintAmount <= RESERVED_MINT_LIMIT,
            "Exceeds reserved limit"
        );
        require(msg.value >= RESERVED_PRICE * mintAmount, "Insufficient funds");
        require(
            MerkleProof.verify(proof, reservedMerkleRoot, _getLeaf(msg.sender)),
            "Invalid Merkle proof"
        );

        _mint(msg.sender, mintAmount);
        reservedMinted += mintAmount;

        if (totalSupply() >= WL_MINT_LIMIT + RESERVED_MINT_LIMIT) {
            listedMintEndTime = block.timestamp;
        }
        emit MintReserved(msg.sender, mintAmount);
    }

    function mintFCFS(
        uint256 mintAmount
    ) external payable nonReentrant whenNotPaused {
        require(block.timestamp > listedMintEndTime, "FCFS Mint Not available");
        require(
            totalSupply() + mintAmount <=
                WL_MINT_LIMIT + RESERVED_MINT_LIMIT + FCFS_MINT_LIMIT,
            "Exceeds public limit"
        );
        require(msg.value >= FCFS_PRICE * mintAmount, "Insufficient funds");

        _mint(msg.sender, mintAmount);
        fcfsMinted += mintAmount;

        emit MintFCFS(msg.sender, mintAmount);
    }

    function mintAdmin(uint256 mintAmount) external onlyOwner {
        require(totalSupply() + mintAmount <= MAX_SUPPLY, "Exceeds mint limit");

        _mint(msg.sender, mintAmount);

        emit MintAdmin();
    }

    // Function to start the different minting stages
    function startMint() external onlyOwner {
        listedMintEndTime = block.timestamp + 12 hours;
    }

    function _getLeaf(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

    function setMerkleRoots(
        bytes32 _wlMerkleRoot,
        bytes32 _reservedMerkleRoot
    ) external onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
        reservedMerkleRoot = _reservedMerkleRoot;
        emit MerkleRoots(_wlMerkleRoot, _reservedMerkleRoot);
    }

    function withdraw(address _to) external onlyOwner whenPaused {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_to).call{value: balance}("");
        emit Withdrawn(_to, balance);
        require(success);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPause() external onlyOwner whenPaused {
        _unpause();
    }
}
