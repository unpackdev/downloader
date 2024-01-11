//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";

contract NFT is ERC1155SupplyUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    bool public isPaused;
    address public moderator;
    mapping(uint256 => string) public baseURIs;
    mapping(uint256 => uint256) public maxSupplies;
    mapping(uint256 => uint256) public prices;

    modifier onlyGov() {
        require(msg.sender == owner() || msg.sender == moderator, "NFT: NOT_GOVERNANCE");
        _;
    }

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();

        moderator = msg.sender;
        isPaused = true;
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

    function setURI(uint256 id, string memory baseURI) external onlyGov {
        baseURIs[id] = baseURI;
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory baseURI = baseURIs[id];
        return (bytes(baseURI).length == 0) ? "" : string(abi.encodePacked(baseURI, id.toString()));
    }

    function mint(uint256 id, uint256 amount) external payable {
        require(!isPaused, "NFT: SALE_PAUSED");
        require(totalSupply(id) + amount <= maxSupplies[id], "NFT: EXCEED_MAX_SUPPLY");
        require(msg.value == prices[id] * amount, "NFT: INCORRECT_PRICE");

        _mint(msg.sender, id, amount, "");
    }
}
