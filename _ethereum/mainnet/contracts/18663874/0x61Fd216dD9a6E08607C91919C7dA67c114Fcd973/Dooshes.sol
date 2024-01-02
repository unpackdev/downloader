// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Dooshes is Ownable, ERC721A, DefaultOperatorFilterer {
    bytes32 public rootDL;
    bytes32 public rootAL;

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant DOOSHLIST_SUPPLY = 1111;

    uint256 public constant MAX_MINT_PER_WALLET_DOOSHLIST = 1;
    uint256 public constant MAX_MINT_PER_WALLET_ALLOWLIST = 1;
    uint256 public constant MAX_MINT_PER_WALLET_PUBLIC = 5;

    uint256 public priceAL = 0.0069 ether;
    uint256 public pricePub = 0.0069 ether;
    string private baseTokenURI;
    bool public stateDL;
    bool public stateAL;
    bool public statePub;

    string private hiddenMetadataUri;
    bool public revealStarted = false;

    address receiver1;
    address receiver2;
    address receiver3;

    constructor(
        address receiver1_,
        address receiver2_,
        address receiver3_,
        bytes32 _rootDL,
        bytes32 _rootAL,
        string memory _hiddenMetadataUri,
        string memory _baseTokenURI
    ) ERC721A("Dooshes", "Dooshes") {
        rootDL = _rootDL;
        rootAL = _rootAL;
        receiver1 = receiver1_;
        receiver2 = receiver2_;
        receiver3 = receiver3_;
        hiddenMetadataUri = _hiddenMetadataUri;
        baseTokenURI = _baseTokenURI;
    }

    function checkTokenURIs()
        external
        view
        returns (string memory hiddenuri, string memory uri)
    {
        return (hiddenMetadataUri, baseTokenURI);
    }

    function checkTokenURIActive() external view returns (string memory uri) {
        if (revealStarted) {
            return (baseTokenURI);
        } else {
            return (hiddenMetadataUri);
        }
    }

    function setURI(
        string memory _hiddenMetadataUri,
        string memory _baseTokenURI
    ) external onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
        baseTokenURI = _baseTokenURI;
    }

    function setRoots(bytes32 _rootDL, bytes32 _rootAL) external onlyOwner {
        rootDL = _rootDL;
        rootAL = _rootAL;
    }

    function mintDooshList(uint256 amount, bytes32[] memory proof) external {
        require(msg.sender == tx.origin, "No smart contract");
        require(stateDL, "Dooshlist sale is inactive");

        require(
            isValidDL(proof, keccak256(abi.encodePacked(msg.sender))),
            "Not a part of Dooshlist"
        );

        require(
            totalSupply() + amount <= DOOSHLIST_SUPPLY,
            "Whole doosh is already here"
        );
        require(
            _numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET_DOOSHLIST,
            "You've got enough"
        );

        _safeMint(msg.sender, amount);
    }

    function mintAllowList(
        uint256 amount,
        bytes32[] memory proof
    ) external payable {
        require(msg.sender == tx.origin, "No smart contract");
        require(stateAL, "AllowList sale inactive");

        require(
            isValidAL(proof, keccak256(abi.encodePacked(msg.sender))),
            "Not a part of Allowlist"
        );

        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "All Dooshes are already here"
        );
        require(msg.value >= amount * priceAL, "Yoo need to pay more");
        require(
            _numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET_ALLOWLIST,
            "You've got enough"
        );

        _safeMint(msg.sender, amount);
    }

    function mintPub(uint256 amount) external payable {
        require(msg.sender == tx.origin, "No smart contract");
        require(statePub, "Public sale is inactive");

        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "All Dooshes are already here"
        );

        require(msg.value >= amount * pricePub, "Yoo need to pay more");
        require(
            _numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET_PUBLIC,
            "You've got enough"
        );

        _safeMint(msg.sender, amount);
    }

    function isValidDL(
        bytes32[] memory proof,
        bytes32 leaf
    ) public view returns (bool) {
        return MerkleProof.verify(proof, rootDL, leaf);
    }

    function isValidAL(
        bytes32[] memory proof,
        bytes32 leaf
    ) public view returns (bool) {
        return MerkleProof.verify(proof, rootAL, leaf);
    }

    function ownerMint(uint256 amount, address to) external onlyOwner {
        require(amount + totalSupply() <= MAX_SUPPLY, "No more Dooshes");
        _safeMint(to, amount);
    }

    function setMintStatus(
        bool stateDL_,
        bool stateAL_,
        bool statePub_
    ) external onlyOwner {
        stateDL = stateDL_;
        stateAL = stateAL_;
        statePub = statePub_;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealStarted == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, Strings.toString(_tokenId))
                )
                : "";
    }

    function startReveal(bool _state) public onlyOwner {
        revealStarted = _state;
    }

    function setPrice(uint priceAL_, uint pricePub_) external onlyOwner {
        priceAL = priceAL_;
        pricePub = pricePub_;
    }

    function withdraw() external onlyOwner {
        uint256 state = (address(this).balance * 33) / 100;

        (bool ad1, ) = payable(receiver1).call{value: state}("");
        require(ad1);

        (bool ad2, ) = payable(receiver2).call{value: state}("");
        require(ad2);

        (bool ad3, ) = payable(receiver3).call{value: address(this).balance}(
            ""
        );
        require(ad3);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function checkMintStatus()
        public
        view
        returns (bool stateDL_, bool stateAL_, bool statePub_)
    {
        return (stateDL, stateAL, statePub);
    }

    function checkReceivers()
        public
        view
        returns (address rec1, address rec2, address rec3)
    {
        return (receiver1, receiver2, receiver3);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        if (revealStarted) {
            return (baseTokenURI);
        } else {
            return (hiddenMetadataUri);
        }
    }
}
