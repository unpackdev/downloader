//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

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
    mapping(address => bool) public _admins;

    function initialize() public initializer {
        // Already called from V1, removing code to reduce deployment cost
        //__Context_init_unchained();
        //__ERC165_init_unchained();
        //__ERC1155_init_unchained(
        //    "https://ipfs.io/ipfs/QmSsjfq7Ba2gr1A6qehuRTFg9ittakYWhvUAGYWGLxMrKX"
        //);
        //__ERC1155Supply_init_unchained();
        //__Ownable_init_unchained();
        //__Pausable_init_unchained();
        //__ReentrancyGuard_init();
    }

    function mint(address to, uint256 amount)
        external
        onlyAdmin
        nonReentrant
        whenNotPaused
    {
        _mint(to, PLOT, amount, "");
    }

    function burn(address to, uint256 amount)
        external
        onlyAdmin
        nonReentrant
        whenNotPaused
    {
        _burn(to, PLOT, amount);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
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
