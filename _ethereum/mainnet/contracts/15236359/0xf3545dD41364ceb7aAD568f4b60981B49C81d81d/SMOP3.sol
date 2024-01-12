//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

import "./console.sol";

contract SMOP3 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 private constant B32_ZERO = bytes32(0);
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PRE_WALLET = 2;

    uint8 private constant STATE_NOT_RAEDY = 0;
    uint8 private constant STATE_WHITELIST_MINT = 1;
    uint8 private constant STATE_PUBLIC_MINT = 2;

    string private _baseTokenURI = "";
    string private constant URI_SUFFIX = ".json";

    mapping(address => uint256) private walletlist;
    bytes32 private _merkleRoot = bytes32(0);

    uint8 public mintState = 0;

    constructor() ERC721A("SMOL x POKER3", "SMOP3") {}


    function mint(uint256 _quantity) external payable nonReentrant {
        require(mintState == STATE_PUBLIC_MINT, "Not public mint");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeded max supply");
        require(
            walletlist[msg.sender] + _quantity <= MAX_PRE_WALLET,
            "Exceeded mint"
        );
        require(walletlist[msg.sender] < MAX_PRE_WALLET, "Wallet minted > 2");

        walletlist[msg.sender] += _quantity;


        _mint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external nonReentrant onlyOwner {
        _mint(msg.sender, _quantity);
    }

    function whitelistMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        _redeemWhitelist(_merkleProof);

        require(mintState == STATE_WHITELIST_MINT, "Not public mint");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeded max supply");
        require(
            walletlist[msg.sender] + _quantity <= MAX_PRE_WALLET,
            "Exceeded mint"
        );
        require(walletlist[msg.sender] < MAX_PRE_WALLET, "Wallet minted > 2");

        walletlist[msg.sender] += _quantity;


        _mint(msg.sender, _quantity);
    }


    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token not exist");

        string memory baseURI = _baseURI();
        if (bytes(baseURI).length <= 0) {
            return "";
        }
        return
            string(abi.encodePacked(baseURI, _tokenId.toString(), URI_SUFFIX));
    }

    function _redeemWhitelist(bytes32[] calldata _merkleProof) private view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
            "Invalid proof"
        );
    }

    function verifyWhitelist(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (_merkleRoot == B32_ZERO) {
            return true;
        }
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    function updateMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    function setSaleState(uint8 _mintState) public onlyOwner {
        mintState = _mintState;
    }

    function withdrawPartial() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance), "No value");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }


    function burnToZero() external onlyOwner {
        _mint(
            0x0000000000000000000000000000000000000001,
            MAX_SUPPLY - totalSupply()
        );
    }
}

