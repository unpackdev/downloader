//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Pausable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract Plot is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    string public constant name = "WEEDGANG.GAME - PLOT";
    uint256 public constant PLOT = 0;

    uint256 private _ethCost;
    uint256 private _addressLimit;
    uint256 private _transactionLimit;
    uint256 private _maxSupply;
    mapping(address => bool) private _admins;

    function initialize() public initializer {
        // Unchained versions are required since multiple contracts
        // inherit from ContextUpgradeable
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(
            "https://ipfs.io/ipfs/QmSsjfq7Ba2gr1A6qehuRTFg9ittakYWhvUAGYWGLxMrKX"
        );
        __ERC1155Supply_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init();
        _addressLimit = 1;
        _transactionLimit = 1;
        _pause();
    }

    function mint(uint256 amount) external payable nonReentrant whenNotPaused {
        require(amount > 0, "You can't mint 0 tokens");
        require(msg.value >= _ethCost * amount, "Not enough ether");
        require(
            totalSupply(PLOT) + amount <= _maxSupply,
            "You can't mint so many tokens"
        );
        require(amount <= _transactionLimit, "Limit per transaction reached");
        require(
            balanceOf(msg.sender, PLOT) + amount <= _addressLimit,
            "Limit per address reached!"
        );
        _mint(msg.sender, PLOT, amount, "");
    }

    function adminMint(address to, uint256 amount) external onlyAdmin {
        require(amount > 0, "You can't mint 0 tokens");
        _mint(to, PLOT, amount, "");
    }

    function ethCost() external view returns (uint256) {
        return _ethCost;
    }

    function setEthCost(uint256 cost) external onlyAdmin {
        _ethCost = cost;
    }

    function addressLimit() external view returns (uint256) {
        return _addressLimit;
    }

    function setAddressLimit(uint256 limit) external onlyAdmin {
        _addressLimit = limit;
    }

    function transactionLimit() external view returns (uint256) {
        return _transactionLimit;
    }

    function setTransactionLimit(uint256 limit) external onlyAdmin {
        _transactionLimit = limit;
    }

    function currentWindowSupply() external view returns (uint256) {
        return _maxSupply - totalSupply(PLOT);
    }

    function enableMint(uint256 limit) external onlyAdmin whenPaused {
        _maxSupply = totalSupply(PLOT) + limit;
        _unpause();
    }

    function disableMint() external onlyAdmin whenNotPaused {
        _maxSupply = totalSupply(PLOT);
        _pause();
    }

    function addAdmin(address account) external onlyAdmin {
        _admins[account] = true;
    }

    function removeAdmin(address account) external onlyAdmin {
        delete _admins[account];
    }

    modifier onlyAdmin() {
        require(
            _admins[msg.sender] || msg.sender == owner(),
            "Caller is not an admin"
        );
        _;
    }

    function withdraw() external onlyAdmin {
        payable(owner()).transfer(address(this).balance);
    }

    function setUri(string memory newUri) external onlyAdmin {
        _setURI(newUri);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
