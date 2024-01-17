// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./IVoyBridge.sol";

/**
 * VoyToken contract
 * This contract implements a continuous minting function. The minting function is protected with MINTER_ROLE.
 * Each minting operation requires the unique complementary Corda transaction SecureHash as a reference for provenance.
 * We leverage the use of Open Zeppelin contracts for Context, AccessControl, and ERC20.
 */
contract VoyToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public MAX_SUPPLY = 500_000_000 ether; // MAX_SUPPLY is 500M
    mapping(address => bool) public bridges;

    event BridgeSet(address indexed _bridge, bool _enabled);
    event Swap(address indexed _user, address indexed _bridge, uint256 _amount);


    constructor() ERC20("Voy Token", "VOY") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _mint(_msgSender(), 40_000_000 ether); // Initial supply is 40M
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        uint256 _totalSupply = totalSupply();
        require(
            amount <= MAX_SUPPLY - _totalSupply,
            "VoyToken: MAX_SUPPLY is out"
        );
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) {
        MAX_SUPPLY -= amount;
        _burn(from, amount);
    }

    function setBridge(address _bridge, bool _enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!_enabled || isContract(_bridge), "Not a contract");
        bridges[_bridge] = _enabled;

        emit BridgeSet(_bridge, _enabled);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function swap(address _bridge, uint256 _amount) external {
        require(bridges[_bridge], "Invalid bridge");
        require(_amount > 0, "Invalid amount");

        approve(_bridge, _amount);
        transferToBridge = true;
        IVoyBridge(_bridge).initiateSwap(msg.sender, _amount);
        transferToBridge = false;

        emit Swap(msg.sender, _bridge, _amount);
    }

    bool transferToBridge = false;

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, amount);

        require(
            !bridges[to] || transferToBridge,
            "Not allowed to send to bridge"
        );
    }
}
