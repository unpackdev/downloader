// SPDX-License-Identifier: MIT
// Authored by NoahN w/ Metavate 🚀 (https://twitter.com/heymetavate) 
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./Ownable.sol";



contract BrainCrocs is ERC721A, ERC2981, Ownable {
    using Strings for uint256;

    //------------------//
    //     VARIABLES    //
    //------------------//
    uint256 public cost = 0.015 ether;
    uint256 public presaleCost = 0.008 ether;
    uint256 private _maxSupply = 5555; 

    bool public sale = false;
    bool public presale = false;
    bool public braintoadzSale = false;
    bool public adminAccess = true;
    bool public frozen = false;

    string public baseURI;
    string public metadataExtension = ".json";

    address private constant _admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
    address private _owner;

    bytes32 public presaleMerkleRoot;
    bytes32 public braintoadzMerkleRoot;

    mapping(address => uint256) public presaleMintedAmount;
    mapping(address => bool) public braintoadzMinted;

    error Paused();
    error MaxSupply();
    error BadInput();
    error AccessDenied();
    error EthValue();
    error MintLimit();

    constructor()
        ERC721A("BRAINCROCS", "BC")
        Ownable(msg.sender)
    {
        _owner = msg.sender;
        _setDefaultRoyalty(_owner, 500); // 5% default royalties
        _safeMint(_owner, 1);
    }

    //------------------//
    //     MODIFIERS    //
    //------------------//

    modifier onlyTeam() {
        if (msg.sender != _owner && msg.sender != admin()) {
            revert AccessDenied();
        }
        _;
    }

    //------------------//
    //       MINT       //
    //------------------//

    function mint(uint256 mintQty) external payable {
        if (sale == false) revert Paused();
        if (mintQty * cost != msg.value) revert EthValue();
        if (mintQty > 10) revert MintLimit();
        if (mintQty + _totalMinted() > _maxSupply) revert MaxSupply();

        _safeMint(msg.sender, mintQty);
    }

    function presaleMint(uint256 mintQty, bytes32[] calldata _merkleProof)
        external
        payable
    {
        if (presale == false) revert Paused();
        if (mintQty * presaleCost != msg.value) revert EthValue();
        if (presaleMintedAmount[msg.sender] + mintQty > 10) revert MintLimit();
        if (mintQty + _totalMinted() > _maxSupply) revert MaxSupply();
        if (
            !MerkleProof.verify(
                _merkleProof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert AccessDenied();

        presaleMintedAmount[msg.sender] += mintQty;
        _safeMint(msg.sender, mintQty);
    }

    function braintoadzMint(bytes32[] calldata _merkleProof) external payable {
        if (braintoadzSale == false) revert Paused();
        if (_totalMinted() + 6 > _maxSupply) revert MaxSupply();
        if (
            !MerkleProof.verify(
                _merkleProof,
                braintoadzMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert AccessDenied();
        if (braintoadzMinted[msg.sender] == true) revert AccessDenied();

        braintoadzMinted[msg.sender] = true;
        _safeMint(msg.sender, 6);
    }

    function airdropMint(uint256 mintQty, address recipient) external onlyTeam {
        if (mintQty + _totalMinted() > _maxSupply) revert MaxSupply();
        _safeMint(recipient, mintQty);
    }

    function airdropMint(
        uint256[] calldata quantity,
        address[] calldata recipient
    ) external onlyTeam {
        if (quantity.length != recipient.length) revert BadInput();
        uint256 totalQuantity = 0;

        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        if (totalQuantity + _totalMinted() > _maxSupply) revert MaxSupply();

        for (uint256 i = 0; i < recipient.length; ++i) {
            _safeMint(recipient[i], quantity[i]);
        }
    }

    //------------------//
    //      SETTERS     //
    //------------------//

    function setBaseURI(string memory _newBaseURI) external onlyTeam {
        if (frozen == true) {
            revert Paused();
        }
        baseURI = _newBaseURI;
    }

    function setRoyalty(address receiver, uint96 feeNumerator) external onlyTeam {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function toggleSale() external onlyTeam {
        sale = !sale;
    }

    function togglePresale() external onlyTeam {
        presale = !presale;
    }

    function toggleBraintoadzSale() external onlyTeam {
        braintoadzSale = !braintoadzSale;
    }

    function setCost(uint256 _cost) external onlyTeam {
        cost = _cost;
    }

    function setMetadataExtension(string memory _newExtension)
        external
        onlyTeam
    {
        if (frozen == true) {
            revert Paused();
        }
        metadataExtension = _newExtension;
    }

    function setpresaleMerkleRoot(bytes32 root) external onlyTeam {
        presaleMerkleRoot = root;
    }

    function setBrainToadzMerkleRoot(bytes32 root) external onlyTeam {
        braintoadzMerkleRoot = root;
    }

    function freezeMetadata() external onlyTeam {
        frozen = true;
    }

    function toggleAdminAccess() external {
        if (msg.sender != _owner) {
            revert AccessDenied();
        }
        adminAccess = !adminAccess;
    }

    function reduceMaxSupply(uint256 newSupply) external onlyTeam {
        if (newSupply >= _maxSupply || newSupply < _totalMinted()) {
            revert MaxSupply();
        }
        _maxSupply = newSupply;
    }

    //------------------//
    //      GETTERS     //
    //------------------//

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        metadataExtension
                    )
                )
                : "";
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function admin() public view returns (address) {
        return adminAccess ? _admin : _owner;
    }

    //------------------//
    //       MISC       //
    //------------------//

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external {
        if (msg.sender != _owner) revert AccessDenied();
        payable(_owner).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    fallback() external payable {}

    receive() external payable {}
}
