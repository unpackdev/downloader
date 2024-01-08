// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMath.sol";

struct FrozenWallet {
    address wallet;
    uint totalAmount;
    uint releaseDay;
    bool scheduled;
}

struct LorcVestingType {
    uint cliffDays;
    bool vesting;
}

contract LandOrc is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    using SafeMath for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    mapping (address => bool) public isBlackListed;
    mapping (address => FrozenWallet) public frozenWallets;

    address public landNFTAddress;
    address public rewardVaultAddress;
    address public exchangeAddress;
    
    uint public rewardPercentage;
    uint public releaseTime;

    LorcVestingType[] public vestingTypes;

    function initialize(string memory _name, string memory _symbol) initializer public {
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        
        rewardVaultAddress = msg.sender;
        exchangeAddress = msg.sender;
        
        rewardPercentage = 4500; // 45% of minted token goes to reward vault
        _mint(msg.sender, 21000000 * 10 ** uint(decimals())); // 21 Million initial token supply
        
        releaseTime = block.timestamp; // 1628985600; //"Sunday, 15 August 2021 00:00:00"
        vestingTypes.push(LorcVestingType(360 days, true)); // Advisor - vesitng duration 360 Days
        vestingTypes.push(LorcVestingType(540 days, true)); // Seed - vesitng duration 540 Days
        vestingTypes.push(LorcVestingType(540 days, true)); // Founder - vesitng duration 720 Days
        vestingTypes.push(LorcVestingType(90 days, true)); // Private A - vesitng duration 90 Days
        vestingTypes.push(LorcVestingType(30 days, true)); // Private B - vesitng duration 30 Days
    }

    /// @dev Throws if called by any account other than the LandNFT Contract.
    modifier onlyNFTContract() {
        require(landNFTAddress == msg.sender, "LandOrc: Caller is not the LandNFT Contract");
        _;
    }

    /// @dev Throws if argument address is blacklisted
    modifier notBlacklisted(address _address) {
        require(isBlackListed[_address] == false, "transaction blacklisted!");
        _;
    }

    /// @dev Set LandNFT contract address
    function setLandNFTAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        address _oldAddress = landNFTAddress;
        landNFTAddress = _address;
        emit UpdateLandNFTAddress(_oldAddress, _address);
        return true;
    }

    /// @dev Set Reward Vault address
    function setRewardVaultAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        address _oldAddress = rewardVaultAddress;
        rewardVaultAddress = _address;
        emit UpdateRewardVaultAddress(_oldAddress, _address);
        return true;
    }

    /// @dev Set Exchange account address
    function setExchangeAddress(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        address _oldAddress = exchangeAddress;
        exchangeAddress = _address;
        emit UpdateExchangeAddress(_oldAddress, _address);
        return true;
    }

    /// @dev Set Reward Percetage for NFT mint
    function setRewardPercentage(uint _rewardPercentage) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        require(_rewardPercentage > 0 && _rewardPercentage <= 10000, "LandOrc: percentage must be within range of 1 to 10000");
        rewardPercentage = _rewardPercentage;
        return true;
    }

    /// @dev add blacklist address 
    function addBlackList (address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isBlackListed[_address] = true;
        emit AddedBlackList(_address);
    }

    /// @dev remove blacklist address 
    function removeBlackList (address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isBlackListed[_address] = false;
        emit RemovedBlackList(_address);
    }
 
    /// @dev check if the Vesting is completed
    function isVestingCompleted(uint releaseDay) public view returns (bool) {
        if (block.timestamp < releaseTime || block.timestamp < releaseDay) {
            return false;
        }
        return true;
    }

    /// @dev Add funds Allocations for vesting wallet addresses
    function addAllocations(address[] memory addresses, uint[] memory totalAmounts, uint vestingTypeIndex) external payable onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(addresses.length == totalAmounts.length, "LandOrc: Address and totalAmounts length must be same");
        require(vestingTypes[vestingTypeIndex].vesting, "LandOrc: Vesting type isn't found");

        LorcVestingType memory vestingType = vestingTypes[vestingTypeIndex];
        uint addressesLength = addresses.length;

        for(uint i = 0; i < addressesLength; i++) {
            address _address = addresses[i];
            uint256 totalAmount = totalAmounts[i];
            uint256 cliffDay = vestingType.cliffDays;

            addFrozenWallet(_address, totalAmount, cliffDay);
        }

        return true;
    }

    /// @dev Add frozen wallet
    function addFrozenWallet(address wallet, uint totalAmount, uint cliffDays) internal {
        if (!frozenWallets[wallet].scheduled) {
            // Transfer funds to wallet
            super._transfer(msg.sender, wallet, totalAmount);
        }

        // Create frozen wallets
        FrozenWallet memory frozenWallet = FrozenWallet(
            wallet,
            totalAmount,
            releaseTime.add(cliffDays),
            true
        );

        // Add wallet to frozen wallets
        frozenWallets[wallet] = frozenWallet;
    }

    /// @dev get transferable amount on frozen wallet address
    function getTransferableAmount(address sender) public view returns (uint256) {
        if (block.timestamp < frozenWallets[sender].releaseDay) {
            return 0;
        }
        return frozenWallets[sender].totalAmount;
    }

    /// @dev get frozen amount on the wallet address
    function getFrozenAmount(address sender) public view returns (uint256) {
        uint256 transferableAmount = getTransferableAmount(sender);
        uint256 frozenAmount = frozenWallets[sender].totalAmount.sub(transferableAmount);
        return frozenAmount;
    }

    /// @dev validate if the adddress can transfer amount
    function canTransfer(address sender, uint256 amount) public view returns (bool) {
        // Control is scheduled wallet
        if (!frozenWallets[sender].scheduled) {
            return true;
        }

        uint256 balance = balanceOf(sender);
        uint256 frozenAmount = getFrozenAmount(sender);

        if (balance > frozenWallets[sender].totalAmount && balance.sub(frozenWallets[sender].totalAmount) >= amount) {
            return true;
        }

        if (!isVestingCompleted(frozenWallets[sender].releaseDay) || balance.sub(amount) < frozenAmount) {
            return false;
        }
        return true;
    }

    /// @dev Mint new LORC for LandNFT
    function mintNFTReward( uint256 _amount) external whenNotPaused onlyNFTContract {
        require(_amount > 0, "LandOrc: amount must be greater than 0");

        uint _rewardAmount = _amount.mul(rewardPercentage).div(10000);
        uint _exchangeAmount = _amount.sub(_rewardAmount);

        if(rewardVaultAddress != address(0) && _rewardAmount > 0){
            _mint(rewardVaultAddress, _rewardAmount);
        }

        if(exchangeAddress != address(0) && _exchangeAmount > 0){
            _mint(exchangeAddress, _exchangeAmount);
        }
    }

    /// @dev pause contract
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @dev unpause contract
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev mint new LORC
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @dev Override _beforeTokenTransfer
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        notBlacklisted(from)
        notBlacklisted(to)
        notBlacklisted(msg.sender)
        override
    {
        require(canTransfer(msg.sender, amount), "LandOrc: Wait for vesting day!");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    event UpdateRewardVaultAddress(address oldAddress, address newAddress);
    event UpdateExchangeAddress(address oldAddress, address newAddress);
    event UpdateLandNFTAddress(address oldAddress, address newAddress);
    event AddedBlackList(address _address);
    event RemovedBlackList(address _address);
}
