// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// imports
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Paired is ERC20, ReentrancyGuard, Ownable {

    address public _multisigContract;
    address public _claimingContract;
    address public _admin;

    bool public _initial_mint;
    uint256 public _lastMint;
    
    // amount made available for claiming
    uint256 public _activeSupply = 100_000_000 * (10**decimals()); // 100 million
    uint256 public _max_inflation_pct = 372908894; // 0.372908894%
    uint256[9] public _inflation_options = [
        249067931, // 1% YoY - 0.1249% QoQ
        311045746, // 1.25% YoY - 0.311% QoQ
        372908894, // 1.5% YoY - 0.3729% QoQ
        434657867, // 1.75% YoY - 0.4346% QoQ
        496293157, // 2% YoY - 0.4962% QoQ
        557815251, // 2.25% YoY - 0.5578% QoQ
        619224633, // 2.5% YoY - 0.6192% QoQ
        680521782, // 2.75% YoY - 0.6805% QoQ
        741707178 // 3% YoY - 0.7417% QoQ
    ];
    uint256 public constant _scaling_factor = 10**11;

    constructor(string memory name, string memory symbol, address multisigContract) ERC20(name, symbol)
    {
        _multisigContract = multisigContract;
    }

    modifier onlyClaimingContract() {
        require(msg.sender == _claimingContract, "Only Claiming Contract");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == owner(), "Only Admin");
        _;
    }

    // MARK: - Only Owner
    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setClaimingContract(address claimingContract) external onlyOwner {
        _claimingContract = claimingContract;
    }

    function setMultisigContract(address multisigContract) external onlyOwner {
        _multisigContract = multisigContract;
    }

    function setInflationCap(uint256 index) external onlyOwner {
        require(index < _inflation_options.length, "Index out of range");
        _max_inflation_pct = _inflation_options[index];
    }

    function initial_mint() onlyOwner nonReentrant external {
        require(_initial_mint == false, "Already minted");
        _initial_mint = true;
        uint256 amount = _activeSupply * _max_inflation_pct / _scaling_factor;
        amount += _activeSupply;
        _mint(_multisigContract, amount);
    }

    // MARK: - Only Admin
    function mint() onlyAdmin nonReentrant external {
        require((block.timestamp - _lastMint) > 7862400, "Too soon to mint new tokens");
        uint256 delta = totalSupply() - _activeSupply;
        uint256 amount = _activeSupply * _max_inflation_pct / _scaling_factor;
        _lastMint = block.timestamp;
        _mint(_multisigContract, amount - delta);
    }

    // MARK: - Public
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
        _activeSupply -= amount;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // MARK: Only Claiming Contract
    function updateActiveSupply(uint256 amount) onlyClaimingContract nonReentrant external {
        require(amount + _activeSupply <= totalSupply(), "Amount cannot be greater than current total supply");
        _activeSupply += amount;
    }

}