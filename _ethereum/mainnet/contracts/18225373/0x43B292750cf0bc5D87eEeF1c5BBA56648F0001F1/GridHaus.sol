// SPDX-License-Identifier: MIT
/**
  ____      _     _   _   _                 
 / ___|_ __(_) __| | | | | | __ _ _   _ ___ 
| |  _| '__| |/ _` | | |_| |/ _` | | | / __|
| |_| | |  | | (_| | |  _  | (_| | |_| \__ \
 \____|_|  |_|\__,_| |_| |_|\__,_|\__,_|___/     

 */

pragma solidity ^0.8.13;

import "./ERC721Psi.sol";
import "./Ownable.sol";
import "./ERC721PsiBurnable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract GridHaus is ERC721Psi, Ownable, ERC721PsiBurnable, ReentrancyGuard {
    uint256 public MINT_PRICE = 0.005 ether;
    uint256 public MAX_MINT_PER_WALLET = 3;
    bytes32 public root;
    bool _mintEnabled = false;
    bool _burnEnabled = false;
    mapping(address => uint256) public tokensMinted;

    constructor() ERC721Psi() {}

    function setMerkleRoot(bytes32 p_root) external onlyOwner nonReentrant {
        root = p_root;
    }

    function setGeneratedId(uint256 p_tokenId) external onlyOwner nonReentrant {
        _generatedId = p_tokenId;
    }

    function ownerMint(uint256 _amount) external onlyOwner nonReentrant {
        _safeMint(msg.sender, _amount);
    }

    function gridListMint(uint256 p_amount, bytes32[] memory p_proof)
        external
        payable
        nonReentrant
    {
        require(
            isValid(p_proof, keccak256(abi.encodePacked(msg.sender))),
            "Wallet Address is not Grid Listed."
        );
        require(_mintEnabled == true, "Grid Haus: Mint disabled.");
        require(
            tokensMinted[msg.sender] + p_amount <= MAX_MINT_PER_WALLET,
            "Grid Haus: Minting more than allowed per wallet"
        );
        require(
            (MINT_PRICE * p_amount) -
                (tokensMinted[msg.sender] < 1 ? 0.005 ether : 0) <=
                msg.value,
            "Grid Haus: Not enough ETH sent"
        );
        _safeMint(msg.sender, p_amount);
        tokensMinted[msg.sender] += p_amount;
    }

    function mint(uint256 p_amount) external payable nonReentrant {
        require(_mintEnabled == true, "Grid Haus: Mint disabled.");
        require(
            tokensMinted[msg.sender] + p_amount <= MAX_MINT_PER_WALLET,
            "Grid Haus: Minting more than allowed per wallet"
        );
        require(
            (MINT_PRICE * p_amount) <= msg.value,
            "Grid Haus: Not enough ETH sent"
        );
        _safeMint(msg.sender, p_amount);
        tokensMinted[msg.sender] += p_amount;
    }

    function dyeArtPiece(uint256 p_artPieceToDye, uint256 p_artPieceToBurn)
        external
        nonReentrant
    {
        require(_burnEnabled == true, "Grid Haus: Burn is disabled.");
        require(
            ownerOf(p_artPieceToDye) == msg.sender,
            "Grid Haus: You do not own the art piece to dye"
        );
        require(
            ownerOf(p_artPieceToBurn) == msg.sender,
            "Grid Haus: You do not own the dye art piece"
        );

        if (getWalletAddress(p_artPieceToDye) != msg.sender) {
            _originalAddress[_currentIndex] = getWalletAddress(p_artPieceToDye);
        }
        _seeds[_currentIndex] = generateSeed(p_artPieceToDye);
        _colors[_currentIndex] = getColorPalette(p_artPieceToBurn);
        _safeMint(msg.sender, 1);
        _burn(p_artPieceToBurn);
        _burn(p_artPieceToDye);
    }

    function transformArtPiece(
        uint256 p_artPieceToTransform,
        uint256 p_artPieceToBurn1,
        uint256 p_artPieceToBurn2
    ) external nonReentrant {
        require(_burnEnabled == true, "Grid Haus: Burn is disabled.");
        require(
            ownerOf(p_artPieceToTransform) == msg.sender,
            "Grid Haus: You do not own the art piece to transform"
        );
        require(
            ownerOf(p_artPieceToBurn1) == msg.sender,
            "Grid Haus: You do not own the first art piece to burn"
        );
        require(
            ownerOf(p_artPieceToBurn2) == msg.sender,
            "Grid Haus: You do not own the second art piece to burn"
        );

        _colors[_currentIndex] = getColorPalette(p_artPieceToTransform);
        _safeMint(msg.sender, 1);
        _burn(p_artPieceToTransform);
        _burn(p_artPieceToBurn1);
        _burn(p_artPieceToBurn2);
    }

    function enableMint() public onlyOwner nonReentrant {
        _mintEnabled = true;
    }

    function disableMint() public onlyOwner nonReentrant {
        _mintEnabled = false;
    }

    function enableBurn() public onlyOwner nonReentrant {
        _burnEnabled = true;
    }

    function disableBurn() public onlyOwner nonReentrant {
        _burnEnabled = false;
    }

    function setBaseURI(string memory p_baseURI) public onlyOwner nonReentrant {
        _baseTokenURI = p_baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        require(address(this).balance > 0, "Balance is zero.");
        payable(owner()).transfer(address(this).balance);
    }

    function isValid(bytes32[] memory p_proof, bytes32 p_leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(p_proof, root, p_leaf);
    }

    function totalSupply()
        public
        view
        override(ERC721Psi, ERC721PsiBurnable)
        returns (uint256)
    {
        return super.totalSupply();
    }

    function _exists(uint256 tokenId)
        internal
        view
        override(ERC721Psi, ERC721PsiBurnable)
        returns (bool)
    {
        return super._exists(tokenId);
    }
}
