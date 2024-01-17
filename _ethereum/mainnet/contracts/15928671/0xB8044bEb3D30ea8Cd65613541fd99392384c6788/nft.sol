// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract MakizushiNFT is ERC721A, Ownable, ReentrancyGuard {
    address public treasury;

    uint256 public whitelistCount = 0;
    uint256 public publicCount = 0;
    uint256 public ownerCount = 0;

    uint256 public MAX_SUPPLY;
    uint256 public MAX_PUBLIC_SUPPLY;
    uint256 public MAX_WHITELIST_SUPPLY;
    uint256 public MAX_OWNER_SUPPLY;
    uint256 public WHITELIST_PRICE;
    uint256 public OG_PRICE;
    uint256 public PUBLIC_PRICE;

    bool public revealed = false;
    string public hiddenMetadataUri = "";
    string public baseURI = "";
    string public uriSuffix = "";

    bool public isOgMint = false;
    bool public isWhiteListMint = false;
    bool public isPublicMint = false;

    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public ogClaimed;
    mapping(address => uint256) public publicClaimed;

    bytes32 public whitelistMerkleRoot;
    bytes32 public ogMerkleRoot;

    constructor(
        address _treasury,
        uint256 _maxSupply,
        uint256 _maxPublicSupply,
        uint256 _maxWhitelistSupply,
        uint256 _maxOwnerSupply,
        uint256 _whitelistPrice,
        uint256 _ogPrice,
        uint256 _publicPrice
    ) ERC721A("MAKIZUSHI", "ZSHI") {
        MAX_SUPPLY = _maxSupply;
        MAX_PUBLIC_SUPPLY = _maxPublicSupply;
        MAX_WHITELIST_SUPPLY = _maxWhitelistSupply;
        MAX_OWNER_SUPPLY = _maxOwnerSupply;
        WHITELIST_PRICE = _whitelistPrice;
        OG_PRICE = _ogPrice;
        PUBLIC_PRICE = _publicPrice;
        treasury = _treasury;
    }

    /* -------------------------------------------------------------------------- */
    /*                                PUBLIC FUNCTION                             */
    /* -------------------------------------------------------------------------- */

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        require(isWhiteListMint == true, "Whitelist minting not active");

        uint256 totalSupply = totalSupply() + quantity;
        require(totalSupply <= MAX_SUPPLY, "Exceeds max supply");

        uint256 totalWhitelistSupply = whitelistCount + quantity;
        require(
            totalWhitelistSupply <= MAX_WHITELIST_SUPPLY,
            "Exceeds max whitelist supply"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Not whitelisted"
        );

        uint256 claimAmount = whitelistClaimed[msg.sender];
        require(claimAmount + quantity <= 4, "Max Take-Away is 4");

        if (claimAmount == 0) {
            require(
                msg.value >= ((quantity - 1) * WHITELIST_PRICE),
                "Not enough ETH"
            );
            whitelistClaimed[msg.sender] = quantity;
        } else {
            require(msg.value >= quantity * WHITELIST_PRICE, "Not enough ETH");
            whitelistClaimed[msg.sender] = claimAmount + quantity;
        }

        payable(treasury).transfer(msg.value);

        _safeMint(msg.sender, quantity);
        whitelistCount += quantity;
    }

    function ogMint(uint256 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        require(isWhiteListMint == true, "Whitelist minting not active");

        uint256 totalSupply = totalSupply() + quantity;
        require(totalSupply <= MAX_SUPPLY, "Exceeds max supply");

        uint256 totalOgSupply = whitelistCount + quantity;
        require(totalOgSupply <= MAX_WHITELIST_SUPPLY, "Exceeds max Whitelist supply");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf), "Not Dine-in");

        uint256 claimAmount = ogClaimed[msg.sender];
        require(claimAmount + quantity <= 5, "Max Dine-in is 5");

        uint256 freeQuota = 2;

        if (claimAmount >= freeQuota) {
            require(msg.value >= quantity * OG_PRICE, "Not enough ETH");
        } else {
          if (claimAmount == 0) {
            if (quantity > freeQuota) {
                require(
                    msg.value >= ((quantity - freeQuota) * OG_PRICE),
                    "Not enough ETH"
                );
            } 
          }

          if (claimAmount == 1) {
            if (quantity > 1) {
                require(
                    msg.value >= ((quantity - 1) * OG_PRICE),
                    "Not enough ETH"
                );
            }
          }
        }

        ogClaimed[msg.sender] = claimAmount + quantity;

        payable(treasury).transfer(msg.value);

        _safeMint(msg.sender, quantity);
        whitelistCount += quantity;
    }

    function publicMint(uint256 quantity) external payable nonReentrant {
        require(isPublicMint == true, "Public minting not active");

        uint256 totalSupply = totalSupply() + quantity;
        require(totalSupply <= MAX_SUPPLY, "Exceeds max supply");

        uint256 totalPublicSupply = publicCount + quantity;
        require(
            totalPublicSupply <= MAX_PUBLIC_SUPPLY,
            "Exceeds max public supply"
        );

        uint256 claimAmount = publicClaimed[msg.sender];
        require(claimAmount + quantity <= 5, "Max public is 5");

        require(msg.value >= quantity * PUBLIC_PRICE, "Not enough ETH");

        payable(treasury).transfer(msg.value);

        publicClaimed[msg.sender] = claimAmount + quantity;

        _safeMint(msg.sender, quantity);
        publicCount += quantity;
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        uint256 totalSupply = totalSupply() + quantity;
        require(totalSupply <= MAX_SUPPLY, "Exceeds max supply");

        uint256 ownerSupply = ownerCount + quantity;
        require(ownerSupply <= MAX_OWNER_SUPPLY, "Exceeds max owner supply");

        _safeMint(msg.sender, quantity);
    }

    /* -------------------------------------------------------------------------- */
    /*                                GETTERS                                     */
    /* -------------------------------------------------------------------------- */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
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
                        Strings.toString(_tokenId),
                        uriSuffix
                    )
                )
                : "";
    }

    function isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        external
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf);
    }

    function isOg(bytes32[] calldata _merkleProof, address _address)
        external
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Admin Only                                  */
    /* -------------------------------------------------------------------------- */

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUriSuffix(string memory _newUriSuffix) public onlyOwner {
        uriSuffix = _newUriSuffix;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setWhitelistMerkleRoot(bytes32 _newWhitelistMerkleRoot)
        public
        onlyOwner
    {
        whitelistMerkleRoot = _newWhitelistMerkleRoot;
    }

    function setOgMerkleRoot(bytes32 _newOgMerkleRoot) public onlyOwner {
        ogMerkleRoot = _newOgMerkleRoot;
    }

    function startWhitelistMinting() public onlyOwner {
        isWhiteListMint = true;
    }

    function endWhitelistMinting() public onlyOwner {
        isWhiteListMint = false;
    }

    function startPublicMinting() public onlyOwner {
        isPublicMint = true;
    }

    function endPublicMinting() public onlyOwner {
        isPublicMint = false;
    }

    function setTreasury(address _newTreasury) public onlyOwner {
        treasury = _newTreasury;
    }

    function setOgPrice(uint256 _newOgPrice) public onlyOwner {
        OG_PRICE = _newOgPrice;
    }

    function setWhitelistPrice(uint256 _newWhitelistPrice) public onlyOwner {
        WHITELIST_PRICE = _newWhitelistPrice;
    }

    function setPublicPrice(uint256 _newPublicPrice) public onlyOwner {
        PUBLIC_PRICE = _newPublicPrice;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply >= totalSupply(), "New max supply must be greater than or equal to current supply");
        MAX_SUPPLY = _newMaxSupply;
    }

    function setWhitelistMaxSupply(uint256 _newWhitelistMaxSupply) public onlyOwner {
        require(_newWhitelistMaxSupply >= whitelistCount, "New max supply must be greater than or equal to current supply");
        MAX_WHITELIST_SUPPLY = _newWhitelistMaxSupply;
    }

    function setOwnerMaxSupply(uint256 _newOwnerMaxSupply) public onlyOwner {
        require(_newOwnerMaxSupply >= ownerCount, "New max supply must be greater than or equal to current supply");
        MAX_OWNER_SUPPLY = _newOwnerMaxSupply;
    }

    function setPublicMaxSupply(uint256 _newPublicMaxSupply) public onlyOwner {
        require(_newPublicMaxSupply >= publicCount, "New max supply must be greater than or equal to current supply");
        MAX_PUBLIC_SUPPLY = _newPublicMaxSupply;
    }
    
}
