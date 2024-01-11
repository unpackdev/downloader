// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract Vkuzo is ERC721A, Ownable {
    bytes32 private _whitelistHash;
    bytes32 private _OGHash;

    uint256 public maxSupply = 4444;
    uint256 public bonusSupply = 1000;

    uint256 private constant maxPerAddress = 20;
    uint256 private constant maxPerOG = 15;

    uint256 public constant publicMintPrice = 0.027 ether;

    uint256 public bonusMintCounter;

    uint256 public saleStartDate = 1649602800;
    uint256 public OGStartDate = 1649599200;

    string private baseUri =
        "https://gateway.pinata.cloud/ipfs/QmTFWFbogSBHh8RrLcSP1zdtfj7YeKdSZr9UyyT9mfHV4A/";
    string private baseExtension = ".json";

    bool public isOGBonusOpen = true;
    bool public isWhitelistOpen = true;

    constructor() ERC721A("Vkuzo", "VKZ") {}

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

    function setBaseURI(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= saleStartDate;
    }

    function isOGOpen() public view returns (bool) {
        return block.timestamp >= OGStartDate;
    }

    function isOGBonusAvailable() public view returns (bool) {
        return bonusMintCounter < bonusSupply && isOGBonusOpen;
    }

    function setSaleStartDate(uint256 date) external onlyOwner {
        saleStartDate = date;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    function setOGStartDate(uint256 date) external onlyOwner {
        OGStartDate = date;
    }

    function setBonusSupply(uint256 amount) external onlyOwner {
        bonusSupply = amount;
    }

    function setOGBonusState(bool state) external onlyOwner {
        isOGBonusOpen = state;
    }

    function setWhitelistState(bool state) external onlyOwner {
        isWhitelistOpen = state;
    }

    function setHashWhitelist(bytes32 root) external onlyOwner {
        _whitelistHash = root;
    }

    function setHashOG(bytes32 root) external onlyOwner {
        _OGHash = root;
    }

    function numberminted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _claimWithBonus(uint32 amount) private {
        uint16 amountBonus = 0;
        require(
            (msg.value >= publicMintPrice * amount) && (amount > 0),
            "Incorrect Price sent"
        );
        if (amount == 2) {
            amountBonus = 1;
        } else if (amount == 4) {
            amountBonus = 2;
        } else if (amount == 6) {
            amountBonus = 3;
        } else if (amount == 8) {
            amountBonus = 4;
        } else if (amount == 10) {
            amountBonus = 5;
        }

        require(
            totalSupply() + (amount + amountBonus) <= maxSupply,
            "Max Supply reached"
        );
        require(
            _numberMinted(msg.sender) + (amount + amountBonus) <= maxPerOG,
            "Max per address"
        );
        require(
            bonusMintCounter + amountBonus <= bonusSupply,
            "Free Mint Stock Unavailable"
        );
        bonusMintCounter += amountBonus;
        _safeMint(msg.sender, amount + amountBonus);
    }

    function _claimSale(uint32 amount) private {
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require((amount > 0) && (amount <= maxPerAddress), "Incorrect amount");
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
        require(msg.value >= publicMintPrice * amount, "Incorrect Price sent");

        _safeMint(msg.sender, amount);
    }

    function publicMint(uint32 amount) external payable onlyEOA {
        require(isSaleOpen(), "Sale not open");
        _claimSale(amount);
    }

    function OGMint(bytes32[] calldata proof, uint32 amount)
        external
        payable
        onlyEOA
    {
        require(isOGOpen(), "OG mint session is not open yet");
        require(verifyWhitelist(proof, _OGHash), "Not whitelisted");
        isOGBonusAvailable() ? _claimWithBonus(amount) : _claimSale(amount);
    }

    function WhitelistMint(bytes32[] calldata proof, uint16 amount)
        external
        onlyEOA
    {
        require(isWhitelistOpen == true, "Session Closed");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(verifyWhitelist(proof, _whitelistHash), "Not whitelisted");

        require(
            _numberMinted(msg.sender) + amount <= maxPerAddress,
            "Max per address"
        );
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
