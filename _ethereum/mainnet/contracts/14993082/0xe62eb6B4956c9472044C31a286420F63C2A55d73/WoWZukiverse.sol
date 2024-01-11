// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721APausable.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract WoWZukiverse is ERC721A, ERC721AQueryable, ERC721APausable, ERC721ABurnable, Ownable, ReentrancyGuard {
    uint256 public PRICE;
    uint256 public MAX_SUPPLY;
    string private BASE_URI;
    uint32 public MAX_MINT_AMOUNT_PER_TX;

    bool public SALE_STATE;
    bool public METADATA_FROZEN;

    address private SIGNER;

    uint256 public totalFreeMinted;

    constructor(uint256 price,
        uint256 maxSupply,
        string memory baseUri,
        uint32 maxMintPerTx,
        address signer) ERC721A("WoW Zukiverse", "WOWZ") {
        PRICE = price;
        MAX_SUPPLY = maxSupply;
        BASE_URI = baseUri;
        MAX_MINT_AMOUNT_PER_TX = maxMintPerTx;
        SIGNER = signer;
    }

    /** GETTERS **/

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function getClaimedFreeMints(address minter) external view returns (uint64) {
        return _getAux(minter);
    }

    /** SETTERS **/

    function setSigner(address signer) external onlyOwner {
        SIGNER = signer;
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        require(!METADATA_FROZEN, "Metadata frozen!");
        BASE_URI = customBaseURI_;
    }

    function setMaxMintPerTx(uint32 maxMintPerTx) external onlyOwner {
        MAX_MINT_AMOUNT_PER_TX = maxMintPerTx;
    }

    function setSaleState(bool state) external onlyOwner {
        SALE_STATE = state;
    }

    function freezeMetadata() external onlyOwner {
        METADATA_FROZEN = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /** MINT **/

    modifier mintCompliance(uint256 _mintAmount) {
        require(_currentIndex + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        require(_mintAmount > 0, "Invalid mint amount!");
        _;
    }

    function mint(uint32 _mintAmount, bytes memory signature, uint64 freeMints) public payable mintCompliance(_mintAmount) {
        uint64 usedFreeMints = _getAux(msg.sender);
        uint64 remainingFreeMints = 0;
        if (freeMints > usedFreeMints) {
            remainingFreeMints = freeMints - usedFreeMints;
        }
        require(_mintAmount <= MAX_MINT_AMOUNT_PER_TX, "Mint limit exceeded!");
        require(_currentIndex >= 10, "First 10 mints are reserved for the owner!");
        require(SALE_STATE, "Sale not started");

        uint256 price = PRICE * _mintAmount;

        uint256 freeMinted = 0;

        bool hasFreeMint = recoverSigner(keccak256(abi.encodePacked(msg.sender, freeMints)), signature) == SIGNER;
        if (freeMints > 0 && hasFreeMint && remainingFreeMints > 0) {
            if (_mintAmount >= remainingFreeMints) {
                price -= remainingFreeMints * PRICE;
                freeMinted = remainingFreeMints;
                remainingFreeMints = 0;
            } else {
                price -= _mintAmount * PRICE;
                freeMinted = _mintAmount;
                remainingFreeMints -= _mintAmount;
            }
        }

        require(msg.value == price, "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);

        totalFreeMinted += freeMinted;
        _setAux(msg.sender, uint64(freeMints - remainingFreeMints));
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    /** PAYOUT **/

    address private constant payoutAddress1 =
    0x68E71B8A36b929352bBC5b3a9Dd1509881dD9f8E;

    address private constant payoutAddress2 =
    0x2a12f70C8d31EE18520cFC89c7e1598e9EDFA8A6;

    address private constant payoutAddress3 =
    0x44d692C458932ACac67b84d8eBF805e195FEefaE;

    address private constant payoutAddress4 =
    0x90cbeebcF9744b1f4274122Ab2B6387bb8D345Fd;

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), balance / 4);

        Address.sendValue(payable(payoutAddress2), balance / 4);

        Address.sendValue(payable(payoutAddress3), balance / 4);

        Address.sendValue(payable(payoutAddress4), balance / 4);
    }

    /** UTILS **/

    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash
            )
        );

        return ECDSA.recover(messageDigest, signature);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
