// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";

contract BeingB00 is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    bytes32 public merkleRoot;
    bytes32 public fcfsMerkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => bool) public fcfsClaimed;
    mapping(address => bool) public publicClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri =
        "ipfs://QmSCQ6WGLD3fe3ec4kxtePmmssgQq3S2wYaqmt575gffQf/unr3v3al3d.json";

    uint256 public cost = 0 ether;
    uint256 public maxSupply = 1111;
    uint256 public whitelistMaxSupply = 708;
    uint256 public airdropMaxSupply = 203;
    uint256 public maxMintAmountPerTx = 1;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public fcfsMintEnabled = false;
    bool public revealed = false;

    constructor() ERC721A("Being B00", "B00") {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        require(
            totalSupply() + _mintAmount <=
                whitelistMaxSupply + airdropMaxSupply,
            "Whitelist max supply reached!"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function fcfsMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) {
        require(fcfsMintEnabled, "The FCFS sale is not enabled!");
        require(!fcfsClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, fcfsMerkleRoot, leaf),
            "Invalid proof!"
        );

        fcfsClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(
        uint256 _mintAmount
    ) public payable mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        require(!publicClaimed[_msgSender()], "Address already claimed!");

        publicClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return uriPrefix;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setFcfsMerkleRoot(bytes32 _fcfsMerkleRoot) public onlyOwner {
        fcfsMerkleRoot = _fcfsMerkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setFcfsMintEnabled(bool _state) public onlyOwner {
        fcfsMintEnabled = _state;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool wf, ) = payable(owner()).call{value: address(this).balance}("");
        require(wf);
    }
}
