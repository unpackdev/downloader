// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract AntiHeroMint is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    uint256 public MAX_ANTIHEROES;
    uint256 public MINT_PASS_SUPPLY;
    uint256 public PUBLIC_SUPPLY;
    uint256 public WL_SUPPLY;
    uint256 public MAX_PER_PURCHASE;
    uint256 public ANTIHERO_BASE_PRICE;

    string public tokenBaseURI;
    string public unrevealedURI;
    bool public mintPassSaleActive;
    bool public whitelistSaleActive;
    bool public publicMintActive;

    mapping(address => uint256) private whitelistAddressMintCount;
    mapping(address => uint256) private mintPassRedemption;

    CountersUpgradeable.Counter public tokenSupply;
    CountersUpgradeable.Counter public publicMintSupply;
    CountersUpgradeable.Counter public wlMintSupply;
    CountersUpgradeable.Counter public mintPassSupply;

    event AntiheroMinted(
        address indexed from,
        uint256 amountPaid,
        uint256 tier
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("Hero Galaxy: Anti-Heroes", "ANTI-HERO");
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        MAX_ANTIHEROES = 6666;
        MINT_PASS_SUPPLY = 4810;
        PUBLIC_SUPPLY = 0;
        WL_SUPPLY = 1856;
        MAX_PER_PURCHASE = 2;
        ANTIHERO_BASE_PRICE = 0.13 ether;
        mintPassSaleActive;
        whitelistSaleActive = false;
        publicMintActive = false;

    }

    function setTokenBaseURI(string memory _baseURI) external onlyOwner {
        tokenBaseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
        unrevealedURI = _unrevealedUri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        bool revealed = bytes(tokenBaseURI).length > 0;
        if (!revealed) {
            return unrevealedURI;
        }
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function verifyOwnerSignature(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return hash.toEthSignedMessageHash().recover(signature) == owner();
    }

    function setWhitelistSaleActive(bool _active) external onlyOwner {
        whitelistSaleActive = _active;
    }

    function setPublicMintActive(bool _active) external onlyOwner {
        publicMintActive = _active;
    }

    function setMintPassSaleActive(bool _active) external onlyOwner {
        mintPassSaleActive = _active;
    }

    function updateSupply(
        uint256 _mintPasses,
        uint256 _wlSupply,
        uint256 _publicSupply
    ) external onlyOwner {
        require(
            (_mintPasses + _wlSupply + _publicSupply) <= MAX_ANTIHEROES,
            "Supply must add up to 6666"
        );
        WL_SUPPLY = _wlSupply;
        PUBLIC_SUPPLY = _publicSupply;
        MINT_PASS_SUPPLY = _mintPasses;
    }

    function passesMinted(address _address)
        public
        view
        returns (uint256 _passesMinted)
    {
        return mintPassRedemption[_address];
    }

    // Requirements to public mint
    // Active Sale
    // Max of 2 per TX
    // >= 0.13 eth * quantity minted
    // Quantity minted < total allotted to the public

    function publicMint(uint256 _quantity) external payable {
        require(publicMintActive, "Sale is not active.");
        require(
            _quantity <= MAX_PER_PURCHASE,
            "You can only mint a maximum of 2 at a time"
        );
        require(
            publicMintSupply.current().add(_quantity) <= PUBLIC_SUPPLY,
            "This purchase would exceed the amount available for public mint"
        );
        require(
            msg.value >= ANTIHERO_BASE_PRICE.mul(_quantity),
            "The ether value sent is not correct"
        );
        publicMintSupply._value += _quantity;
        _safeMintAntiheroes(_quantity, false);
    }

    // Requirements to WL Mint
    // * Signed Message
    // * Active Sale
    // * Max of 2, min of 1 per 1 wallet
    // >= 0.13 eth * quantity minted
    // Quantity minted < Total supply
    // Quantity Minted < WL Supply

    function whitelistMint(
        uint256 _quantity,
        bytes calldata _whitelistSignature
    ) external payable {
        require(whitelistSaleActive, "Whitelist sale is not active");
        require(
            verifyOwnerSignature(
                keccak256(abi.encode(msg.sender)),
                _whitelistSignature
            ),
            "Invalid whitelist signature"
        );
        require(
            _quantity <= MAX_PER_PURCHASE,
            "You can only mint a maximum of 2 for presale"
        );
        require(
            whitelistAddressMintCount[msg.sender].add(_quantity) <=
                MAX_PER_PURCHASE,
            "This purchase would exceed the maximum Anti-heroes you are allowed to mint in the presale"
        );
        require(
            msg.value >= ANTIHERO_BASE_PRICE.mul(_quantity),
            "The ether value sent is not correct"
        );
        require(
            wlMintSupply.current().add(_quantity) <= WL_SUPPLY,
            "This purchase would exceed the amount available for whitelist mint"
        );
        whitelistAddressMintCount[msg.sender] += _quantity;
        wlMintSupply._value += _quantity;
        _safeMintAntiheroes(_quantity, false);
    }

    // Requirements to mint pass mint
    // Active Sale
    // Valid Signature
    // Quantity minted should be less than the sum of
    // the amount minted in the past + the amount attempting to be minted (mint passes redeemed)
    // Quantity less than mint pass supply

    function mintPassMint(
        uint256 _quantity,
        uint256 _totalMintPasses,
        bytes calldata _signature
    ) external payable {
        require(mintPassSaleActive, "Mint pass redemption is not active");
        require(
            verifyOwnerSignature(
                keccak256(abi.encode(_quantity, _totalMintPasses, msg.sender)),
                _signature
            ),
            "Invalid signature"
        );
        require(
            passesMinted(msg.sender).add(_quantity) <= _totalMintPasses,
            "Purchase would exceed the amount of antiheroes you are allowed to mint"
        );
        require(
            mintPassSupply.current().add(_quantity) <= MINT_PASS_SUPPLY,
            "This purchase would exceed the available mintpasses"
        );
        mintPassRedemption[msg.sender] += _quantity;
        mintPassSupply._value += _quantity;
        _safeMintAntiheroes(_quantity, true);
    }

    function _safeMintAntiheroes(uint256 _quantity, bool _freeMint) internal {
        require(_quantity > 0, "You must mint at least 1 anti-hero");
        require(
            tokenSupply.current().add(_quantity) <= MAX_ANTIHEROES,
            "This purchase would exceed max supply of Antiheroes Heroes"
        );
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 mintIndex = tokenSupply.current();
            tokenSupply.increment();
            _safeMint(msg.sender, mintIndex);
            emit AntiheroMinted(
                msg.sender,
                msg.value,
                tierLevel(msg.value, _freeMint, _quantity)
            );
        }
    }

    function tierLevel(
        uint256 amountSent,
        bool freeMint,
        uint256 quantity
    ) internal view returns (uint256 tier) {
        if (!freeMint) {
            amountSent = amountSent - ANTIHERO_BASE_PRICE.mul(quantity);
        }
        if (amountSent >= 10 ether) {
            return 8;
        }
        if (amountSent >= 5 ether) {
            return 7;
        }
        if (amountSent >= 2.5 ether) {
            return 6;
        }
        if (amountSent >= 1 ether) {
            return 5;
        }
        if (amountSent >= 0.5 ether) {
            return 4;
        }
        if (amountSent >= 0.25 ether) {
            return 3;
        }
        if (amountSent >= 0.1 ether) {
            return 2;
        }
        if (amountSent >= 0.066 ether) {
            return 1;
        }
        return 0;
    }
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
