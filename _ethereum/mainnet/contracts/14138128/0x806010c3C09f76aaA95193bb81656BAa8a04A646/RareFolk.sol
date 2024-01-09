// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

import "./IFolkTraits.sol";

contract RareFolk is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant MAX_PRESALE_MINT_AMOUNT = 5;
    uint256 public constant MAX_MINT_AMOUNT = 10;

    uint256 private constant BASE_PRICE = 0.055 ether;
    uint256 private constant PRESALE_DISCOUNT = 0.005 ether;
    uint256 private constant BUNDLE_PRICE = 0.045 ether;
    uint256 private constant LARGE_BUNDLE_PRICE = 0.04 ether;

    bool public presaleIsActive;
    bool public saleIsActive;
    address public traitsContractAddress;

    address private _signerAddress;
    uint256 private _tokenSupply;

    constructor(address signerAddress) ERC721("Rare Folk", "FOLK") {
        _signerAddress = signerAddress;
        _mintAmount(1, _msgSender());
    }

    function mintPresale(uint256 amount, bytes calldata signature)
        external
        payable
    {
        require(presaleIsActive, "Pre-sale is not active");
        require(
            balanceOf(_msgSender()) + amount <= MAX_PRESALE_MINT_AMOUNT,
            "Mint amount exceeds maximum"
        );
        require(msg.value == price(amount, true), "Incorrect value sent");
        require(_validateSignature(signature), "Invalid signature");

        _mintAmount(amount, _msgSender());
    }

    function mint(uint256 amount) external payable {
        require(saleIsActive, "Sale is not active");
        require(amount <= MAX_MINT_AMOUNT, "Mint amount exceeds maximum");
        require(msg.value == price(amount, false), "Incorrect value sent");

        _mintAmount(amount, _msgSender());
    }

    function mintReserved(uint256 amount, address to) external onlyOwner {
        _mintAmount(amount, to);
    }

    function _mintAmount(uint256 amount, address to) internal {
        require(
            _tokenSupply + amount <= MAX_SUPPLY,
            "Not enough tokens remaining"
        );
        uint256 startId = _tokenSupply;
        for (uint256 i; i < amount; i++) {
            _tokenSupply++;
            _safeMint(to, startId + i);
        }
    }

    function price(uint256 amount, bool presale) public pure returns (uint256) {
        uint256 unitPrice = BASE_PRICE;
        if (presale) {
            unitPrice -= PRESALE_DISCOUNT;
        }

        if (amount > 4) {
            unitPrice = LARGE_BUNDLE_PRICE;
        } else if (amount > 2) {
            unitPrice = BUNDLE_PRICE;
        }

        return unitPrice * amount;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply;
    }

    function setPresaleState(bool state) external onlyOwner {
        presaleIsActive = state;
    }

    function setSaleState(bool state) external onlyOwner {
        saleIsActive = state;
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function setTraitsContractAddress(address contractAddress)
        external
        onlyOwner
    {
        traitsContractAddress = contractAddress;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return
            traitsContractAddress != address(0)
                ? IFolkTraits(traitsContractAddress).tokenURI(tokenId)
                : "";
    }

    function withdraw() external onlyOwner {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function _validateSignature(bytes calldata signature)
        internal
        view
        returns (bool)
    {
        bytes32 dataHash = keccak256(abi.encodePacked(_msgSender()));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address signer = ECDSA.recover(message, signature);
        return (signer == _signerAddress);
    }
}
