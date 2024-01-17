//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";

contract GenesisCorporations is ERC1155SupplyUpgradeable, OwnableUpgradeable {
    string public name;
    string public symbol;

    bool public isPaused;
    address public moderator;
    mapping(uint256 => string) public uris;
    mapping(uint256 => uint256) public maxSupplies;
    mapping(uint256 => uint256) public prices;

    mapping(uint256 => uint256) public mintLimitForId;
    mapping(address => mapping(uint256 => uint256)) public tokensMinted;

    event MintLimitSet(uint256 indexed id, uint256 limit);

    modifier onlyGov() {
        require(msg.sender == owner() || msg.sender == moderator, "NFT: NOT_GOVERNANCE");
        _;
    }

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC1155_init("");
        __Ownable_init();

        moderator = msg.sender;
        isPaused = true;
        name = name_;
        symbol = symbol_;
    }

    function setName(string memory name_) external onlyGov {
        name = name_;
    }

    function setSymbol(string memory symbol_) external onlyGov {
        symbol = symbol_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "NFT: WITHDRAW_FAILED");
    }

    function toggleStatus() external onlyGov {
        isPaused = !isPaused;
    }

    function setModerator(address moderator_) external onlyOwner {
        require(moderator_ != address(0), "NFT: ZERO_ADDRESS");
        moderator = moderator_;
    }

    function setMaxSupply(uint256 id, uint256 maxSupply) external onlyOwner {
        maxSupplies[id] = maxSupply;
    }

    function setPrice(uint256 id, uint256 price) external onlyOwner {
        prices[id] = price;
    }

    function setURI(uint256 id, string memory uri_) external onlyGov {
        uris[id] = uri_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }

    function mint(uint256 id, uint256 amount) external payable {
        require(!isPaused, "NFT: SALE_PAUSED");
        require(totalSupply(id) + amount <= maxSupplies[id], "NFT: EXCEED_MAX_SUPPLY");
        require(msg.value == prices[id] * amount, "NFT: INCORRECT_PRICE");

        require(amount <= availableMints(msg.sender, id), "NFT: EXCEED_MINT_LIMIT");
        tokensMinted[msg.sender][id] += amount;

        _mint(msg.sender, id, amount, "");
    }

    function setMintLimit(uint256 id, uint256 limit) external onlyGov {
        mintLimitForId[id] = limit;
        emit MintLimitSet(id, limit);
    }

    function availableMints(address user, uint256 id) public view returns(uint256) {
        int256 available = int256(mintLimitForId[id]) - int256(tokensMinted[user][id]);
        if (available <= 0) {
          return 0;
        } else {
          return uint256(available);
        }
    }
}