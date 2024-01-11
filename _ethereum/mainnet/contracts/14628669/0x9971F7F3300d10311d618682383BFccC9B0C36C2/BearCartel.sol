// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

//     .--.              .--.
//    : (\ ". _......_ ." /) :
//     '.    `        `    .'
//      /'   _        _   `\
//     /     0}      {0     \
//    |       /      \       |
//    |     /'        `\     |
//     \   | .  .==.  . |   /
//      '._ \.' \__/ './ _.'
//      /  ``'._-''-_.'``  \
//
//        BEAR CARTEL 2022

contract BearCartel is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
    using ECDSA for bytes32;

    uint256 public constant MAX_PRESALE_SUPPLY = 444;
    uint256 public constant MAX_PUBLIC_SUPPLY = 4000;
    uint256 public constant MAX_SUPPLY = MAX_PRESALE_SUPPLY + MAX_PUBLIC_SUPPLY;
    uint256 public constant MAX_PRESALE_MINT_PER_TX = 5;

    uint256 public constant PUBLIC_SALE_MINT_PRICE = 0.11 ether;
    uint256 public constant PRESALE_MINT_PRICE = 0.08 ether;

    bool public presaleLive = false;
    bool public publicSaleLive = false;

    bytes32 private _merkleRoot;

    string private _metadataUrl = "https://metadata-api.onrender.com/tokens/";

    address[] private _payeeAddresses = [
        0x7A2AA6a1761D49e18a0577dC0b9D9B02938b5329,
        0x533c2E3c31473Bf863BC765A7e1948d949b53854
    ];

    uint256[] private _payeeAmounts = [93, 7];

    modifier callerIsSender() {
        require(msg.sender == tx.origin, "CONTRACT_INTERACTION_DISABLED");
        _;
    }

    constructor()
        ERC721A("BearCartel", "BEAR")
        PaymentSplitter(_payeeAddresses, _payeeAmounts)
    {}

    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function setPresaleState(bool state) external onlyOwner {
        presaleLive = state;
    }

    function setPublicSaleState(bool state) external onlyOwner {
        publicSaleLive = state;
    }

    function presaleMint(uint256 amount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        callerIsSender
    {
        require(presaleLive, "PRESALE_NOT_LIVE");
        require(amount <= MAX_PRESALE_MINT_PER_TX, "AMOUNT_EXCEEDS_MAX");
        require(amount > 0, "MINIMUM_MINT_NOT_REACHED");
        require(
            totalSupply() + amount < MAX_PRESALE_SUPPLY,
            "MAX_PRESALE_SUPPLY_REACHED"
        );
        require(msg.value >= PRESALE_MINT_PRICE * amount, "INCORRECT_ETHER_VALUE");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, _merkleRoot, leaf),
            "NOT_WHITELISTED"
        );

        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount)
        external
        payable
        nonReentrant
        callerIsSender
    {
        require(publicSaleLive, "PUBLIC_SALE_NOT_LIVE");
        require(totalSupply() + amount < MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        require(amount > 0, "MINIMUM_MINT_NOT_REACHED");
        require(
            msg.value >= PUBLIC_SALE_MINT_PRICE * amount,
            "INCORRECT_ETHER_VALUE"
        );

        _safeMint(msg.sender, amount);
    }

    // for marketing and dev purposes
    function ownerMint(address to, uint256 amount)
        external
        onlyOwner
        nonReentrant
        callerIsSender
    {
        require(totalSupply() + amount < MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        _safeMint(to, amount);
    }

    function aidrop(address[] memory receivers)
        external
        onlyOwner
        nonReentrant
        callerIsSender
    {
        require(
            totalSupply() + receivers.length < MAX_SUPPLY,
            "MAX_SUPPLY_REACHED"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
        }
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    function updateMetadataURL(string memory newURL) external onlyOwner {
        _metadataUrl = newURL;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _metadataUrl;
    }
}
