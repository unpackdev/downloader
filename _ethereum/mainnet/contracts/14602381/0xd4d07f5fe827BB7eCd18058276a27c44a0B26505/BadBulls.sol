// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract BadBulls is ERC721A, Ownable {
    using ECDSA for bytes32;

    bool public isSaleActive = false;
    bool public isWhiteListActive = true;

    uint256 public maxSupply = 10000;
    uint256 public maxMint = 5;
    uint256 public publicSaleTokenPrice = 0.07 ether;
    uint256 public presaleTokenPrice = 0.05 ether;

    string private _baseTokenURI;
    address private whitelistAccount =
        0xF629C1F48A29dcfC48F52d50C4690F16A70ee679;
    address private freelistAccount =
        0x0f64EfcFfBBc95946576Fc8B8AfB2Cb205f64C0b;
    mapping(bytes32 => bool) whitelistCalimed;
    mapping(bytes32 => bool) freelistCalimed;

    event minted(address indexed _to);

    constructor(
        string memory baseURI_,
        address _whitelistAccount,
        address _freelistAccount
    ) ERC721A("Bad Bulls", "BBULL") {
        _baseTokenURI = baseURI_;
        whitelistAccount = _whitelistAccount;
        freelistAccount = _freelistAccount;
    }

    function mintWhitelist(
        uint8 numberOfTokens,
        bytes32 messageHash,
        bytes memory _signature
    ) external payable {
        uint256 ts = totalSupply();
        require(isWhiteListActive, "Whitelist is not active");
        require(
            isWhitelisted(messageHash, _signature) == whitelistAccount,
            "User is not whitelisted!"
        );
        require(!whitelistCalimed[messageHash], "Address has already cleaimed");
        require(numberOfTokens <= maxMint, "Exceeded max token purchase");
        require(
            ts + numberOfTokens <= maxSupply,
            "Purchase would exceed max tokens"
        );
        require(
            presaleTokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberOfTokens);
        whitelistCalimed[messageHash] = true;
        emit minted(msg.sender);
    }

    function mintFree(bytes32 messageHash, bytes memory _signature)
        external
        payable
    {
        uint256 ts = totalSupply();
        require(isWhiteListActive, "Whitelist is not active");
        require(
            isWhitelisted(messageHash, _signature) == freelistAccount,
            "User is not freelisted!"
        );
        require(!freelistCalimed[messageHash], "Address has already cleaimed");
        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens");

        _safeMint(msg.sender, 1);
        freelistCalimed[messageHash] = true;
        emit minted(msg.sender);
    }

    function mint(uint256 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isSaleActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= maxMint, "Exceeded max token purchase");
        require(
            ts + numberOfTokens <= maxSupply,
            "Purchase would exceed max tokens"
        );
        require(
            publicSaleTokenPrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, numberOfTokens);
        emit minted(msg.sender);
    }

    function isWhitelisted(bytes32 hash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), _signature);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mintToAddress(address _address, uint256 n) external onlyOwner {
        _safeMint(_address, n);
    }

    function setIsSaleState(bool newState) external onlyOwner {
        isSaleActive = newState;
    }

    function setIsWhiteListActive(bool _isWhiteListActive) external onlyOwner {
        isWhiteListActive = _isWhiteListActive;
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function updateMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function updatePublicSalePrice(uint256 _publicSaleTokenPrice)
        external
        onlyOwner
    {
        publicSaleTokenPrice = _publicSaleTokenPrice;
    }

    function updatePreSalePrice(uint256 _preSaleTokenPrice) external onlyOwner {
        presaleTokenPrice = _preSaleTokenPrice;
    }

    function setWhitelistAccount(address _whitelistAccount) external onlyOwner {
        whitelistAccount = _whitelistAccount;
    }

    function setFreelistAccount(address _freelistAccount) external onlyOwner {
        freelistAccount = _freelistAccount;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
