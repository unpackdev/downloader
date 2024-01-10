// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract BLOK is ERC721A, Ownable {
    bytes32 private _whitelistHash;
    bytes32 private _GAhash;
    bytes32 private _freeHash;

    uint256 public constant maxSupply = 3333;
    uint256 public GASupply = 150;
    uint256 public freeSupply = 20;
    uint256 public WhitelistSupply = 500;
    uint256 public OGSupply = 1000;
    uint256 public bonusSupply = 500;

    uint256 private constant maxPerAddress = 20;
    uint256 private constant maxPerGA = 10;
    uint256 private constant maxPerOG = 20;
    uint256 private constant maxPerWhitelist = 20;
    uint256 private constant maxPerFree = 1;

    uint256 public constant publicMintPrice = 0.013 ether;

    uint256 public whitelistMintCounter;
    uint256 public GAMintCounter;
    uint256 public bonusMintCounter;
    uint256 public OGMintCounter;
    uint256 public freeMintCounter;

    uint256 public saleStartDate = 1648830600;

    string private baseUri =
        "https://gateway.pinata.cloud/ipfs/QmZcLU8ksd5cvdCxL6QK4FPxpoCayCa1CbVeunUBo3EnLg/";
    string private baseExtension = ".json";

    mapping(address => uint32) public WhitelistMintedByAddress;
    mapping(address => uint32) public GAMintedByAddress;
    mapping(address => uint32) public freeMintedByAddress;

    bool public isPublicBonusOpen = true;
    bool public isOGBonusOpen = true;
    bool public isWhitelistOpen = true;
    bool public isGAOpen = true;
    bool public isFreeOpen = true;
    bool public isOGOpen = false;

    constructor() ERC721A("Bored Land Of Kizuki", "BLOK") {}

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

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= saleStartDate;
    }

    function isBonusAvailable() public view returns (bool) {
        return bonusMintCounter < bonusSupply;
    }

    function setSaleStartDate(uint256 date) external onlyOwner {
        saleStartDate = date;
    }

    function setFreeSupply(uint256 amount) external onlyOwner {
        freeSupply = amount;
    }

    function setOGSupply(uint256 amount) external onlyOwner {
        OGSupply = amount;
    }

    function setGASupply(uint256 amount) external onlyOwner {
        GASupply = amount;
    }

    function setBonusSupply(uint256 amount) external onlyOwner {
        bonusSupply = amount;
    }

    function setWhitelistSupply(uint256 amount) external onlyOwner {
        WhitelistSupply = amount;
    }

    function setPublicBonusState(bool state) external onlyOwner {
        isPublicBonusOpen = state;
    }

    function setOGBonusState(bool state) external onlyOwner {
        isOGBonusOpen = state;
    }

    function setWhitelistState(bool state) external onlyOwner {
        isWhitelistOpen = state;
    }

    function setFreeState(bool state) external onlyOwner {
        isFreeOpen = state;
    }

    function setOGState(bool state) external onlyOwner {
        isOGOpen = state;
    }

    function setGAState(bool state) external onlyOwner {
        isGAOpen = state;
    }

    function setHashWhitelist(bytes32 root) external onlyOwner {
        _whitelistHash = root;
    }

    function setHashGA(bytes32 root) external onlyOwner {
        _GAhash = root;
    }

    function setHashFree(bytes32 root) external onlyOwner {
        _freeHash = root;
    }

    function numberminted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _claimWithBonus(uint32 amount, bool isPublic) private {
        require(
            (msg.value >= publicMintPrice * amount) && (amount > 0),
            "Incorrect Price sent"
        );
        amount = amount * 2;
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(
            bonusMintCounter + (amount / 2) <= bonusSupply,
            "Free Mint Stock Unavailable"
        );
        if (isPublic) {
            bonusMintCounter += (amount / 2);
        } else {
            bonusMintCounter += (amount / 2);
            OGMintCounter += (amount / 2);
        }
        _safeMint(msg.sender, amount);
    }

    function _claimSale(uint32 amount, bool isPublic) private {
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require((amount > 0) && (amount <= maxPerAddress), "Incorrect amount");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(msg.value >= publicMintPrice * amount, "Incorrect Price sent");
        if (!isPublic) {
            OGMintCounter += amount;
        }
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint32 amount) external payable onlyEOA {
        require(isSaleOpen(), "Sale not open");
        if (isPublicBonusOpen == true && isBonusAvailable() == true) {
            _claimWithBonus(amount, true);
        } else {
            _claimSale(amount, true);
        }
    }

    function OGMint(uint32 amount) external payable onlyEOA {
        require(isOGOpen == true, "OG access not open yet");
        if (isOGBonusOpen == true && isBonusAvailable() == true) {
            _claimWithBonus(amount, false);
        } else {
            _claimSale(amount, false);
        }
    }

    function GAMint(bytes32[] calldata proof, uint16 amount) external onlyEOA {
        require(isGAOpen == true, "Session Closed");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(verifyWhitelist(proof, _GAhash), "Not whitelisted");
        require(
            (amount > 0) && (GAMintCounter + amount) <= GASupply,
            "Whitelist Mint Stock Unavailable"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(
            GAMintedByAddress[msg.sender] + amount <= maxPerGA,
            "Max Supply reached"
        );
        GAMintCounter += amount;
        GAMintedByAddress[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function FreeMint(bytes32[] calldata proof, uint16 amount)
        external
        onlyEOA
    {
        require(isFreeOpen == true, "Session Closed");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(verifyWhitelist(proof, _freeHash), "Not whitelisted");
        require(
            (amount > 0) && (freeMintCounter + amount) <= freeSupply,
            "Whitelist Mint Stock Unavailable"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(
            freeMintedByAddress[msg.sender] + amount <= maxPerFree,
            "Max Supply reached"
        );
        freeMintCounter += amount;
        freeMintedByAddress[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function WhitelistMint(bytes32[] calldata proof, uint16 amount)
        external
        onlyEOA
    {
        require(isWhitelistOpen == true, "Session Closed");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(verifyWhitelist(proof, _whitelistHash), "Not whitelisted");
        require(
            (amount > 0) && (whitelistMintCounter + amount) <= WhitelistSupply,
            "Whitelist Mint Stock Unavailable"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(
            WhitelistMintedByAddress[msg.sender] + amount <= maxPerWhitelist,
            "Max Supply reached"
        );
        whitelistMintCounter += amount;
        WhitelistMintedByAddress[msg.sender] += amount;
        _safeMint(msg.sender, amount);
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        _burn(tokenId);
    }
}
