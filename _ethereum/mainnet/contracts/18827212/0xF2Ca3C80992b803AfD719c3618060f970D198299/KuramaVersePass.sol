// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";

contract KuramaVersePass is ERC721, Ownable {
    error MintNotActive();
    error CannotMintMoreThanMaxSupply();
    error CannotMintMoreThanMaxMintQuantity();
    error InsufficientBalance();
    error NotEligibleToMintForThisPhase();
    error HashAlreadyExecuted();

    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    enum MintPhase {
        GUARANTEED,
        WHITELIST,
        PUBLIC
    }

    MintPhase private currentMintPhase = MintPhase.GUARANTEED;
    uint256 public mintPrice = 0.035 ether;

    uint256 public currentTokenId = 0;
    bool private isMintActive = true;
    uint16 private maxSupply = 555;

    uint16 private maxMintQuantity = 3;

    address private signerAddress;

    string private baseUri = "";

    mapping(bytes32 => bool) private executedHashes;

    mapping(MintPhase => mapping(address => uint16)) public tokensMintedPerAddress;

    constructor(address _initialOwner, address _signerAddress, string memory _baseURI)
        ERC721("KuramaVersePass", "KURAMA")
        Ownable(_initialOwner)
    {
        signerAddress = _signerAddress;
        baseUri = _baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mintKuramaVersePass(address to, uint16 mintQuantity, bytes memory signature, uint256 nonce)
        external
        payable
    {
        MintPhase _currentMintPhase = currentMintPhase;
        bool verificationRequired =
            _currentMintPhase == MintPhase.GUARANTEED || _currentMintPhase == MintPhase.WHITELIST;

        if (verificationRequired) {
            bytes32 _hash = keccak256(abi.encodePacked(_msgSender(), to, mintQuantity, nonce));

            if (executedHashes[_hash]) {
                revert HashAlreadyExecuted();
            }
            address recoveredAddress = _hash.toEthSignedMessageHash().recover(signature);
            if (recoveredAddress != signerAddress) {
                revert NotEligibleToMintForThisPhase();
            }
            executedHashes[_hash] = true;
        }

        mint(currentMintPhase, to, mintQuantity, maxMintQuantity, mintPrice);
    }

    function airDrop(address _address, uint16 _mintQuantity) external onlyOwner {
        mintMany(_address, _mintQuantity);
    }

    function burnKuramaVersePass(uint256 _tokenId) external {
        _burn(_tokenId);
    }

    function isValidMint(uint16 _mintQuantity, uint16 _maxMintQuantity, uint256 _mintPrice)
        internal
        view
        returns (bool)
    {
        if (!isMintActive) {
            revert MintNotActive();
        }
        if (currentTokenId + _mintQuantity > maxSupply) {
            revert CannotMintMoreThanMaxSupply();
        }
        if (_mintQuantity > _maxMintQuantity) {
            revert CannotMintMoreThanMaxMintQuantity();
        }
        if (msg.value < _mintQuantity * _mintPrice) {
            revert InsufficientBalance();
        }
        return true;
    }

    function mintMany(address _to, uint16 _mintQuantity) internal {
        for (uint16 i = 0; i < _mintQuantity; i++) {
            currentTokenId++;
            _safeMint(_to, currentTokenId);
        }
    }

    function mint(MintPhase _mintPhase, address _to, uint16 _mintQuantity, uint16 _maxMintQuantity, uint256 _mintPrice)
        internal
    {
        if (tokensMintedPerAddress[_mintPhase][_to] + _mintQuantity > _maxMintQuantity) {
            revert CannotMintMoreThanMaxMintQuantity();
        }

        tokensMintedPerAddress[_mintPhase][_to] += _mintQuantity;

        if (isValidMint(_mintQuantity, maxMintQuantity, _mintPrice)) {
            mintMany(_to, _mintQuantity);
        }
    }

    function updateMintPhase(MintPhase _mintState, uint256 _mintPrice, uint16 _maxMintQuantity) external onlyOwner {
        currentMintPhase = _mintState;
        mintPrice = _mintPrice;
        maxMintQuantity = _maxMintQuantity;
    }

    function setIsMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    function setMaxSupply(uint16 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function setMaxMintQuantity(uint16 _maxMintQuantity) external onlyOwner {
        maxMintQuantity = _maxMintQuantity;
    }

    function setMintPrice(uint256 _mintPirce) external onlyOwner {
        mintPrice = _mintPirce;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseUri = _baseURI;
    }

    function tokenURI(uint256) public view virtual override returns (string memory) {
        return baseUri;
    }
}
