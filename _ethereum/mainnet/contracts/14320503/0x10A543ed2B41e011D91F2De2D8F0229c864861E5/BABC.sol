// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BABC is ERC721A, Ownable {
    bytes32 private _merkleRootWhitelist;
    bytes32 private _merkleRootGA;

    uint256 public constant maxSupply = 3456;
    uint256 public constant maxWhitelistSupply = 400;
    uint256 public constant maxGASupply = 100;
    uint256 public FCFSsupply = 356;

    uint256 private constant maxPerAddress = 8;

    uint256 public constant publicMintPrice = 0.018 ether;

    uint256 public whitelistMintCounter;
    uint256 public GAMintCounter;
    uint256 public freeMintCounter;

    uint256 public nonPublicStartDate = 1646402400;
    uint256 public saleStartDate = 1646402400;

    string private baseUri =
        "https://gateway.pinata.cloud/ipfs/QmTt4DnC9V1p3qWwUe21dTRX593VRnDKLmyx8hsbA4D1DN/";
    string private baseExtension = ".json";
    mapping(address => bool) public GAMintedByAddress;
    mapping(address => uint32) public FreeMintedByAddress;
    bool private revealed = false;

    constructor() ERC721A("Bored Ape Bones Club", "BABC") {}

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseUri).length != 0
                ? string(
                    abi.encodePacked(
                        baseUri,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function isNonPublicOpen() public view returns (bool) {
        if (
            block.timestamp >= nonPublicStartDate &&
            block.timestamp <= nonPublicStartDate + 30 minutes
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isSaleOpen() public view returns (bool) {
        if (block.timestamp >= saleStartDate) {
            return true;
        } else {
            return false;
        }
    }

    function setNonPublicStartDate(uint256 date) external onlyOwner {
        nonPublicStartDate = date;
    }

    function setSaleStartDate(uint256 date) external onlyOwner {
        saleStartDate = date;
    }

    function setFCFSSupply(uint256 maxsupp) external onlyOwner {
        FCFSsupply = maxsupp;
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        require(revealed == false, "Meta already set");
        baseUri = uri;
        revealed = true;
    }

    function _claimFCFS(uint32 amount) private {
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            (amount > 0) && (freeMintCounter + amount <= FCFSsupply),
            "FCFS Mint Stock Unavailable"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(FreeMintedByAddress[msg.sender] < 4, "Max Free Reached");
        freeMintCounter += amount;
        FreeMintedByAddress[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function _claimsale(uint32 amount) private {
        require(totalSupply() + amount < maxSupply, "Max Supply reached");
        require((amount > 0) && (amount <= maxPerAddress), "Incorrect amount");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(msg.value >= publicMintPrice * amount, "Incorrect Price sent");
        _safeMint(msg.sender, amount);
    }

    function saleMint(uint32 amount) external payable onlyEOA {
        require(isSaleOpen(), "Sale not open");
        isNonPublicOpen()
            ? isFreeAvailable() ? _claimFCFS(amount) : _claimsale(amount)
            : _claimsale(amount);
    }

    function isFreeAvailable() public view returns (bool) {
        return freeMintCounter < FCFSsupply;
    }

    function mintWhitelist(bytes32[] calldata proof, uint16 amount)
        external
        onlyEOA
    {
        require(isNonPublicOpen(), "Session Closed");
        require(
            verifyWhitelist(proof, _merkleRootWhitelist),
            "Not whitelisted"
        );
        require(
            (amount > 0) &&
                (whitelistMintCounter + amount) <= maxWhitelistSupply,
            "Whitelist Mint Stock Unavailable"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        whitelistMintCounter += amount;
        _safeMint(msg.sender, amount);
    }

    function mintGA(bytes32[] calldata proof) external onlyEOA {
        require(isNonPublicOpen(), "Session Closed");
        require(verifyWhitelist(proof, _merkleRootGA), "Not whitelisted");
        require(GAMintCounter + 1 <= maxGASupply, "GA Mint Stock Unavailable");
        require(
            _numberMinted(msg.sender) + 1 <= maxPerAddress,
            "Max per address"
        );
        require(GAMintedByAddress[msg.sender] != true, "GA Minted Already");
        require(totalSupply() + 1 <= maxSupply, "Max Supply reached");
        GAMintCounter += 1;
        GAMintedByAddress[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function setMerkleRootWhitelist(bytes32 root) external onlyOwner {
        _merkleRootWhitelist = root;
    }

    function setMerkleRootGA(bytes32 root) external onlyOwner {
        _merkleRootGA = root;
    }

    function verifyWhitelist(bytes32[] memory _proof, bytes32 _roothash)
        private
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, _roothash, _leaf);
    }

    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "Zero Balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    function burn(uint256 tokenId) public virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        _burn(tokenId);
    }

    function numberminted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
