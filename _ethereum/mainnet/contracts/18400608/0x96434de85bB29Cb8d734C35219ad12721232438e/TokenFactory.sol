// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";
import "./ERC20PresetFixedSupply.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./IERC20.sol";

contract TokenFactory is Ownable {
    uint256 public deploymentFee;

    event PFSTokenDeployed(address indexed creator, address indexed tokenAddress, uint paid);
    event MPTokenDeployed(address indexed creator, address indexed tokenAddress, uint paid);

    constructor(uint256 _initialDeploymentFee) {
        deploymentFee = _initialDeploymentFee;
    }

    function setDeploymentFee(uint256 _newFee) external onlyOwner {
        deploymentFee = _newFee;
    }

    function deployMinterPauserToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint256 _maxSupply
    ) external payable returns (address) {
        require(msg.value >= deploymentFee, "Insufficient payment");

        MinterPauser newToken = new MinterPauser(_name, _symbol, _decimals, _maxSupply, msg.sender);
        newToken.mint(msg.sender, _initialSupply * (10**uint256(_decimals)));
        emit MPTokenDeployed(msg.sender, address(newToken), msg.value);

        return address(newToken);
    }

    function deployFixedSupplyToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) external payable returns (address) {
        require(msg.value >= deploymentFee, "Insufficient payment");

        PresetFixedSupply newToken = new PresetFixedSupply(_name, _symbol, _initialSupply * (10**uint256(_decimals)), msg.sender, _decimals);
        emit PFSTokenDeployed(msg.sender, address(newToken), msg.value);

        return address(newToken);
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(_amount);
    }
}

contract MinterPauser is ERC20, ERC20Burnable, ERC20Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 private _decimals;
    uint256 public maxSupply;

    constructor(
        string memory name, 
        string memory symbol, 
        uint8 decimals,
        uint256 _maxSupply,
        address deployer
    ) 
    ERC20(name, symbol) 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(MINTER_ROLE, deployer);
        _setupRole(PAUSER_ROLE, deployer);
        
        _decimals = decimals;
        maxSupply = _maxSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "REVERT: must have minter role to mint");
        require(totalSupply() + amount <= maxSupply * (10 ** _decimals), "REVERT: max supply exceeded");
        _mint(to, amount);
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "REVERT: must have pauser role to pause");
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "REVERT: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract PresetFixedSupply is ERC20, ERC20Burnable, ERC20Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) ERC20(name, symbol) {
        _mint(owner, initialSupply);
        _decimals = decimals;
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "REVERT: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "REVERT: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}