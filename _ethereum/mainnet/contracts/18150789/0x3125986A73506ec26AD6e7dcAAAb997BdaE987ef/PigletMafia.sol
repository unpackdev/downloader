// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";

contract PigletMafia is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // Constants for initial supply allocation
    uint256 public constant TOTAL_SUPPLY = 1000000000000000; // 1 quadrillion
    uint256 public constant INITIAL_ALLOCATION_PERCENT = 10;
    uint256 public constant LOCKED_ALLOCATION_PERCENT = 30;
    uint256 public constant CUSTODY_ALLOCATION_PERCENT = 60;
    uint256 public constant CUSTODY_HOLD_PERCENT = 20;

    // Addresses for custody and development
    address public custodyWallet;
    address public developmentWallet;
    address public unlocksWallet;
    address public growthAccount;
    address public distributionAccount;
    address public burnAddress; // Address for burning tokens

    // Burn rate
    uint256 public constant BURN_RATE = 1; // 1% burn rate

    // Timestamp when the lock period ends
    uint256 public lockEndTime;

    // Unlock schedules
    uint256 public constant UNLOCK_INTERVAL = 365 days; // Unlock every year
    uint256 public unlockPercentage; // Start with 100% unlocked

    // Liquidity pool address
    address public liquidityPool;

    // Staking variables
    mapping(address => uint256) public stakedBalances;
    uint256 public totalStaked;

    // Events
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);

    // Initialize the contract
    function initialize(
        address _custodyWallet,
        address _developmentWallet,
        address _unlocksWallet,
        address _growthAccount,
        address _distributionAccount,
        address _liquidityPool
    ) initializer public {
        __ERC20_init("PigletMafia", "PIGLET"); // Updated contract name and symbol
        __Ownable_init();

        require(
            _custodyWallet != address(0) &&
                _developmentWallet != address(0) &&
                _unlocksWallet != address(0) &&
                _growthAccount != address(0) &&
                _distributionAccount != address(0) &&
                _liquidityPool != address(0),
            "Invalid wallet addresses"
        );

        custodyWallet = 0x7b01a2c5f6e1ee709D36e9A11c25a937f510638a;
        developmentWallet = 0xde879F37d558B845e4675f4178A15BC089f1c553;
        unlocksWallet = 0x0C17ec9AB62BE661f0276C8A294ca7844a477642;
        growthAccount = 0x632797127Bb492a3FFE7Ab17f878E151A1169C92;
        distributionAccount = 0x71C8EBB9AA1ac07003E36Da3b33F3e845D721955;
        burnAddress = 0x632797127Bb492a3FFE7Ab17f878E151A1169C92; // Set burn address as growth account initially
        liquidityPool = 0x0c69046D60029698b8Fb73Cb49ba86d87d01A7Ae;

        // Calculate token allocations
        uint256 initialAllocation = (TOTAL_SUPPLY * INITIAL_ALLOCATION_PERCENT) / 100;
        uint256 lockedAllocation = (TOTAL_SUPPLY * LOCKED_ALLOCATION_PERCENT) / 100;
        uint256 custodyAllocation = (TOTAL_SUPPLY * CUSTODY_ALLOCATION_PERCENT) / 100;

        // Mint initial supply to the contract creator
        _mint(msg.sender, initialAllocation);

        // Calculate the lock end time (2 years from contract deployment)
        lockEndTime = block.timestamp + 730 days;

        // Mint the locked allocation to the contract
        _mint(address(this), lockedAllocation);

        // Mint custody allocation to the custody wallet
        uint256 custodyHoldAllocation = (custodyAllocation * CUSTODY_HOLD_PERCENT) / 100;
        uint256 developmentAllocation = custodyAllocation - custodyHoldAllocation;

        _mint(custodyWallet, custodyHoldAllocation);
        _mint(developmentWallet, developmentAllocation);
    }

    // Function to release locked tokens after the lock period
    function releaseLockedTokens() external {
        require(block.timestamp >= lockEndTime, "Lock period not over");
        uint256 lockedBalance = balanceOf(address(this));
        require(lockedBalance > 0, "No locked tokens to release");

        // Calculate the amount to unlock based on the current percentage
        uint256 unlockAmount = (lockedBalance * unlockPercentage) / 100;

        // Decrease the unlock percentage for the next unlock
        if (unlockPercentage >= 10) {
            unlockPercentage = unlockPercentage.sub(10);
        } else {
            unlockPercentage = 0;
        }

        // Transfer the unlocked tokens
        _transfer(address(this), msg.sender, unlockAmount);
    }

    // Implement your tokenomics principles here, including locking, burning, staking, and any other features you require.
    
    // Function to burn tokens
    function burn(uint256 amount) external {
        require(amount > 0, "Amount to burn must be greater than 0");
        uint256 burnAmount = (amount * BURN_RATE) / 100;
        require(burnAmount <= balanceOf(msg.sender), "Insufficient balance to burn");
        _burn(msg.sender, burnAmount);
    }

    // Function to stake tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Amount to stake must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance to stake");
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        _transfer(msg.sender, address(this), amount);
        emit TokensStaked(msg.sender, amount);
    }

    // Function to unstake tokens
    function unstake(uint256 amount) external {
        require(amount > 0, "Amount to unstake must be greater than 0");
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        _transfer(address(this), msg.sender, amount);
        emit TokensUnstaked(msg.sender, amount);
    }

    // Function to mint tokens (only callable by the owner)
    function mintTokens(address recipient, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount to mint must be greater than 0");
        _mint(recipient, amount);
    }

    // Function to burn tokens (only callable by the owner)
    function burnTokens(address account, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount to burn must be greater than 0");
        _burn(account, amount);
    }

    // Additional code for maximum mining tolerance can be added here.
}
