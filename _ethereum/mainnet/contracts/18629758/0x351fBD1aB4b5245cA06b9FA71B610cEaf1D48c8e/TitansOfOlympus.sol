// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract TitansOfOlympus is ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    struct Wallet {
        address payable addr;
        uint256 percentage;
    }

    Wallet[2] private wallets;
    mapping(address => uint256) private mintedTokens;

    uint256 public constant MAX_TOKENS_PER_WALLET = 5;
    uint256 private constant MAX_TOKENS = 999;

    string private _baseTokenURI;

    event FundsWithdrawn(address wallet, uint256 amount);

    function initialize(
        address payable _wallet1,
        address payable _wallet2
    ) public initializer {
        __ERC721_init("Titans of Olympus", "TOO");
        __Pausable_init();
        OwnableUpgradeable.__Ownable_init();
        __ReentrancyGuard_init();

        require(_wallet1 != address(0) && _wallet2 != address(0), "Invalid wallet address");
        wallets[0] = Wallet(_wallet1, 50);
        wallets[1] = Wallet(_wallet2, 50);

        _baseTokenURI = "ipfs://Qma75AkQMcb94x3CyCKDDqGfwLJLS2YyLu8amdWFuFUqkh/";
    }

    function mint(uint256 quantity) external payable whenNotPaused nonReentrant {
        require(totalSupply() + quantity <= MAX_TOKENS, "Exceeds max tokens");
        require(mintedTokens[msg.sender] + quantity <= MAX_TOKENS_PER_WALLET, "Exceeds max tokens per wallet");
        require(msg.value >= quantity * tokenPrice(), "Insufficient ETH sent");
        mintedTokens[msg.sender] += quantity;

        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        for (uint i = 0; i < wallets.length; i++) {
            uint256 amount = (balance * wallets[i].percentage) / 100;
            (bool success, ) = wallets[i].addr.call{value: amount}("");
            require(success, "Transfer failed");
            emit FundsWithdrawn(wallets[i].addr, amount);
        }
    }

    function setWallets(address payable _wallet1, address payable _wallet2) external onlyOwner {
        require(_wallet1 != address(0) && _wallet2 != address(0), "Invalid wallet address");
        wallets[0].addr = _wallet1;
        wallets[1].addr = _wallet2;
    }

    function tokenPrice() public pure returns (uint256) {
        return 0.03 ether;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

// Override tokenURI to append '.json' at the end of each URI
function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require((tokenId - 1) < totalSupply(), "ERC721Metadata: URI query for nonexistent token");
require(tokenId > 0, "Token ID must be > 0");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, (tokenId).toString(), ".json"))
            : '';
    }

}
