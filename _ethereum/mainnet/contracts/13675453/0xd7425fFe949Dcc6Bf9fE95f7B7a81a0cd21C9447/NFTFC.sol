// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

/*
  ███╗   ██╗███████╗████████╗    ███████╗ ██████╗
  ████╗  ██║██╔════╝╚══██╔══╝    ██╔════╝██╔════╝
  ██╔██╗ ██║█████╗     ██║       █████╗  ██║
  ██║╚██╗██║██╔══╝     ██║       ██╔══╝  ██║
  ██║ ╚████║██║        ██║       ██║     ╚██████╗
  ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝      ╚═════╝
  by @nichosystem
*/

contract NFTFC is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    event ToggleSale(bool saleLive, bool presaleLive);

    address public constant SIGNER = 0x62559A0bc422E9Cc365FB0389CeF91B697893C55;
    address public constant VAULT = 0xB4C0E862889A8f7448504bA6d5fe3c59abDcD944;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant TX_LIMIT = 20;

    uint256 public price;
    uint256 public batchSupply;
    uint256 public giftedAmount;
    bool public saleLive;
    bool public presaleLive;
    string public baseURI;

    mapping(address => uint256) public presaleTokensClaimed;
    mapping(address => mapping(uint256 => bool)) private _usedNonces;

    constructor() ERC721("NFT FC", "NFTFC") {}

    // INTERNAL
    function _hashTransaction(
        address sender,
        uint256 qty,
        uint256 nonce
    ) private pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(sender, qty, nonce))
                .toEthSignedMessageHash();
    }

    function _matchSigner(bytes32 hash, bytes memory signature)
        private
        pure
        returns (bool)
    {
        return SIGNER == hash.recover(signature);
    }

    // ONLY OWNER
    function toggleSale(bool _saleLive, bool _presaleLive) external onlyOwner {
        saleLive = _saleLive;
        presaleLive = _presaleLive;
        emit ToggleSale(_saleLive, _presaleLive);
    }

    function setupBatch(uint256 _price, uint256 _batchSupply)
        external
        onlyOwner
    {
        price = _price;
        batchSupply = _batchSupply;
    }

    function gift(address[] calldata recipients) external onlyOwner {
        require(
            totalSupply() + recipients.length <= MAX_SUPPLY,
            "Exceeds max supply"
        );
        giftedAmount += recipients.length;
        uint256 _supply = totalSupply(); // Gas optimization
        // zero-index i for recipients array
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], _supply + i + 1); // increment by 1 for token IDs
        }
    }

    function withdraw() external onlyOwner {
        payable(VAULT).transfer(address(this).balance);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    // PUBLIC
    function mint(uint256 tokenQuantity) external payable {
        require(saleLive, "Sale closed");
        require(
            totalSupply() + tokenQuantity <= batchSupply &&
                totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Exceeds max supply"
        );
        require(tokenQuantity <= TX_LIMIT, "Exceeds transaction limit");
        require(tokenQuantity > 0, "No tokens issued");
        require(msg.value >= price * tokenQuantity, "Insufficient ETH");

        uint256 _supply = totalSupply(); // Gas optimization
        for (uint256 i = 1; i <= tokenQuantity; i++) {
            _safeMint(msg.sender, _supply + i);
        }
    }

    function presaleMint(
        bytes32 hash,
        bytes memory signature,
        uint256 nonce,
        uint256 tokenQuantity
    ) external payable {
        require(presaleLive, "Presale closed");
        require(
            totalSupply() + tokenQuantity <= batchSupply &&
                totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Exceeds presale supply"
        );
        require(tokenQuantity > 0, "No tokens issued");
        require(msg.value >= price * tokenQuantity, "Insufficient ETH");
        require(_matchSigner(hash, signature), "No direct mint");
        require(!_usedNonces[msg.sender][nonce], "Hash used");
        require(
            _hashTransaction(msg.sender, tokenQuantity, nonce) == hash,
            "Hash fail"
        );

        presaleTokensClaimed[msg.sender] += tokenQuantity;
        _usedNonces[msg.sender][nonce] = true;
        uint256 _supply = totalSupply(); // Gas optimization
        for (uint256 i = 1; i <= tokenQuantity; i++) {
            _safeMint(msg.sender, _supply + i);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}
