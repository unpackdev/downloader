pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";

contract TestSpawn is ERC20, AccessControl {

    bool public minable = false;
    string internal _name = 'TestSpawn';
    string internal _symbol = 'TSPAWN';
    uint8 internal _decimals = 18;
    uint256 internal max_mining = 420690000000000000000000000000000;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    address allowed_miner;

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function activate() external payable {
        require(minable == false, "INVALID");
        allowed_miner = msg.sender;
        minable = true;

        _mint(msg.sender, 2000000 ether);
    }

    function mintSupplyFromMinedLP(
        address miner,
        uint256 value
    ) external payable {
        require(minable == true, "INVALID");
        require(msg.sender == allowed_miner, "INVALID");

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
