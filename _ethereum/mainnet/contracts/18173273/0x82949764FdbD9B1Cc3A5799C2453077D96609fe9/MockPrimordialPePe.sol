// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./AccessControl.sol";

contract TestPrimordialPePe is ERC20Burnable, AccessControl {

    bool public minable = false;
    uint8 internal _decimals = 18;
    uint256 internal max_mining = 420690000000000000000000000000000;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    address allowed_pepe_miner;
    address allowed_pond_miner;

    constructor() ERC20("TestPrimordialPePe", "TPPEPE") {

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function activate() external payable {
        require(allowed_pepe_miner == address(0) || allowed_pond_miner == address(0), "Miners activated");
        require(msg.sender != allowed_pepe_miner, "Miner already activated");

        uint256 mintAmount = 1000000 ether;

        if (allowed_pepe_miner == address(0)) {
            allowed_pepe_miner = msg.sender;
            _mint(allowed_pepe_miner, mintAmount);
        } else {
            allowed_pond_miner = msg.sender;
            _mint(allowed_pond_miner, mintAmount);
            minable = true; 
        }
    }

    function mintSupplyFromMinedLP(
        address miner,
        uint256 value
    ) external payable {
        require(minable == true, "INVALID");
        require(msg.sender == allowed_pepe_miner || msg.sender == allowed_pond_miner, "INVALID");

        uint _supply = totalSupply();
        uint _calculated = _supply + value;

        require(_calculated <= max_mining, "EXCEEDS MAX");
        _mint(miner, value);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role to mint");
        _mint(to, amount);
    }

    // Role management functions
    function grantAdminRole(address account) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to grant new admin");
        grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to revoke admin");
        revokeRole(ADMIN_ROLE, account);
    }

    function grantMinterRole(address account) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to grant minter role");
        grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role to revoke minter role");
        revokeRole(MINTER_ROLE, account);
    }
}
