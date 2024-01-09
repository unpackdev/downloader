// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";


/* mythx-disable SWC-116 */
struct FrozenWallet {
    address wallet;
    uint256 totalAmount;
    uint256 monthlyAmount;
    uint256 initialAmount;
    uint256 lockDaysPeriod;
    bool scheduled;
}

struct VestingType {
    uint256 monthlyRate;
    //Should be set in percents with 4 trailing digits. i.e. 12.7337% value should be 127337
    uint256 initialRate;
    uint256 lockDaysPeriod;
}


contract ColiToken is OwnableUpgradeable, ERC20PausableUpgradeable {
    // a single wallet can belong only to a single vesting type
    mapping(address => FrozenWallet) public frozenWallets;
    VestingType[] public vestingTypes;
    uint256 public releaseTime;

    // NOTE: the following fields must be left in the contract to ensure that the storage layout stays the same between upgrades
    // anti-sniping bot defense
    uint256 public burnBeforeBlockNumber;
    bool public burnBeforeBlockNumberDisabled;

    event TransferBurned(address indexed wallet, uint256 amount);

    function initialize(uint256 _releaseTime) public initializer {
        // https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained("Coliquidity Token", "COLI");
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();

        setReleaseTime(_releaseTime);

        // Mint all supply to the owner
        // no addition minting is available after initialization
        _mint(owner(), 969_163_000 * 10 ** 18);

        // Seed:	Locked for 1 month, 5% on first release, then equal parts of 10.556% over total of 9 months
        vestingTypes.push(VestingType(105556, 5, 30 days));
        // Private:	10% at listing, then equal parts of 15% over total of 6 months
        vestingTypes.push(VestingType(150000, 10, 0));
        // Advisory:	Locked for 1 month, 4% on first release, then equal parts of 4% over total of 24 months
        vestingTypes.push(VestingType(40000, 4, 30 days));
        // Team:	Locked for 12 months, 8% on first release, then equal parts of 7.667% over total of 12 months
        vestingTypes.push(VestingType(76667, 8, 12 * 30 days));
        // Development:	Locked for 6 months, 3% on first release, then equal parts of 2.694% over total of 36 months
        vestingTypes.push(VestingType(26945, 3, 6 * 30 days));
        // Marketing:	Locked for 3 months, 2% on first release, then equal parts of 2.041% over total of 48 months
        vestingTypes.push(VestingType(20417, 2, 3 * 30 days));
        // Liquidity mining:	8% at listing, then equal parts of 7.666% over total of 12 months
        vestingTypes.push(VestingType(76667, 8, 0));
        // General Reserve:	Locked for 6 months, 2% on first release, then equal parts of 1.633% over total of 60 months
        vestingTypes.push(VestingType(16334, 2, 6 * 30 days));
    }

    function name() public view virtual override returns (string memory) {
        return "Coliquidity Token";
    }

    function symbol() public view virtual override returns (string memory) {
        return "COLI";
    }

    function addVestingType(uint256 monthlyRate, uint256 initialRate, uint256 lockDaysPeriod) external onlyOwner returns (uint256) {
        require(releaseTime + lockDaysPeriod > block.timestamp, "This lock period is over already");

        vestingTypes.push(VestingType(monthlyRate, initialRate, lockDaysPeriod));
        return vestingTypes.length - 1;
    }

    function addAllocations(address[] memory addresses, uint[] memory totalAmounts, uint vestingTypeIndex) external payable onlyOwner returns (bool) {
        uint addressesLength = addresses.length;

        require(addressesLength == totalAmounts.length, "Array lengths must be same");
        require(vestingTypeIndex < vestingTypes.length, "Invalid vestingTypeIndex");

        VestingType memory vestingType = vestingTypes[vestingTypeIndex];

        for (uint256 i = 0; i < addressesLength; i++) {
            address _address = addresses[i];

            uint256 totalAmount = totalAmounts[i] * 10 ** 18;
            uint256 monthlyAmount = totalAmounts[i] * vestingType.monthlyRate * 10 ** 14 / 100;
            uint256 initialAmount = totalAmounts[i] * vestingType.initialRate * 10 ** 18 / 100;
            uint256 lockDaysPeriod = vestingType.lockDaysPeriod;

            addFrozenWallet(_address, totalAmount, monthlyAmount, initialAmount, lockDaysPeriod);
        }

        return true;
    }

    function addFrozenWallet(address wallet, uint totalAmount, uint monthlyAmount, uint initialAmount, uint lockDaysPeriod) internal {
        require(!frozenWallets[wallet].scheduled, "Wallet already frozen");

        super._transfer(msg.sender, wallet, totalAmount);

        // Create frozen wallets
        FrozenWallet memory frozenWallet = FrozenWallet(
            wallet,
            totalAmount,
            monthlyAmount,
            initialAmount,
            lockDaysPeriod,
            true
        );

        // Add wallet to frozen wallets
        frozenWallets[wallet] = frozenWallet;
    }

    function getMonths(uint256 lockDaysPeriod) public view returns (uint256) {
        uint256 unlockTime = releaseTime + lockDaysPeriod;

        if (block.timestamp < unlockTime) {
            return 0;
        }

        uint256 diff = block.timestamp - unlockTime;
        uint256 months = diff / 30 days + 1;

        return months;
    }

    function getUnlockedAmount(address sender) public view returns (uint256) {
        uint256 months = getMonths(frozenWallets[sender].lockDaysPeriod);

        // lockup period
        if (months == 0) {
            return 0;
        }

        uint256 sumMonthlyTransferableAmount = frozenWallets[sender].monthlyAmount * (months - 1);
        uint256 totalTransferableAmount = sumMonthlyTransferableAmount + frozenWallets[sender].initialAmount;

        if (totalTransferableAmount > frozenWallets[sender].totalAmount) {
            return frozenWallets[sender].totalAmount;
        }

        return totalTransferableAmount;
    }

    function getLockedAmount(address sender) public view returns (uint256) {
        uint256 unlockedAmount = getUnlockedAmount(sender);
        return frozenWallets[sender].totalAmount - unlockedAmount;
    }

    function getTransferableAmount(address sender) public view returns (uint256) {
        uint256 balance = balanceOf(sender);
        uint256 lockedAmount = getLockedAmount(sender);
        return balance - lockedAmount;
    }

    function transferMany(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        uint256 amountsLength = amounts.length;
        uint256 recipientsLength = recipients.length;

        require(recipientsLength == amountsLength, "Wrong array length");

        uint256 total = 0;
        for (uint256 i = 0; i < amountsLength; i++) {
            total = total + amounts[i];
        }

        require(balanceOf(msg.sender) >= total, "ERC20: transfer amount exceeds balance");

        for (uint256 i = 0; i < recipientsLength; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            require(recipient != address(0), "ERC20: transfer to the zero address");

            super._transfer(msg.sender, recipient, amount);
        }
    }

    // Transfer control
    function canTransfer(address sender, uint256 amount) public view returns (bool) {
        // Control only scheduled wallet
        if (!frozenWallets[sender].scheduled) {
            return true;
        }

        uint256 balance = balanceOf(sender);
        if (balance >= frozenWallets[sender].totalAmount && (balance - frozenWallets[sender].totalAmount) >= amount) {
            return true;
        }

        uint256 lockedAmount = getLockedAmount(sender);

        if (block.timestamp < releaseTime || (balance - amount) < lockedAmount) {
            return false;
        }
        return true;
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        require(canTransfer(sender, amount), "Wait for vesting day!");
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = _msgSender().call{value : amount}("");
        require(success, "Unable to send value");
    }

    function withdrawToken(address token, uint256 amount) public onlyOwner {
        IERC20Upgradeable(token).transfer(msg.sender, amount);
    }

    function pause(bool status) public onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setReleaseTime(uint256 _releaseTime) public onlyOwner {
        if (releaseTime > 0) {
            require(releaseTime > block.timestamp, "Can't change after release");
        }
        releaseTime = _releaseTime;
    }

}
