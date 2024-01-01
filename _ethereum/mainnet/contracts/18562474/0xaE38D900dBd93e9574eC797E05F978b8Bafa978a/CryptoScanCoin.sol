/*
   _____                  _        _____                  _____      _
  / ____|                | |      / ____|                / ____|    (_)
 | |     _ __ _   _ _ __ | |_ ___| (___   ___ __ _ _ __ | |     ___  _ _ __
 | |    | '__| | | | '_ \| __/ _ \\___ \ / __/ _` | '_ \| |    / _ \| | '_ \
 | |____| |  | |_| | |_) | || (_) |___) | (_| (_| | | | | |___| (_) | | | | |
  \_____|_|   \__, | .__/ \__\___/_____/ \___\__,_|_| |_|\_____\___/|_|_| |_|
 | |           __/ | |
 | |__  _   _ |___/|_|
 | '_ \| | | |
 | |_) | |_| |
 |_.__/ \__, |
   _____ __/ |            _        _____                            _____
  / ____|___/            | |      / ____|                     /\   |_   _|
 | |     _ __ _   _ _ __ | |_ ___| (___   ___ __ _ _ __      /  \    | |
 | |    | '__| | | | '_ \| __/ _ \\___ \ / __/ _` | '_ \    / /\ \   | |
 | |____| |  | |_| | |_) | || (_) |___) | (_| (_| | | | |_ / ____ \ _| |_
  \_____|_|   \__, | .__/ \__\___/_____/ \___\__,_|_| |_(_)_/    \_\_____|
               __/ | |
              |___/|_|

*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

import "./ERC20.sol";

import "./ICryptoScanCoin.sol";
import "./IPresaleCSC.sol";
import "./SimpleOwnable.sol";

uint constant _1_MONTH = 30 days;
uint constant _2_MONTHS = 2 * _1_MONTH;
uint constant _3_MONTHS = 3 * _1_MONTH;
uint constant _6_MONTHS = 6 * _1_MONTH;
uint constant _1_YEAR = 365 days;

contract CryptoScanCoin is ICryptoScanCoin, ERC20, SimpleOwnable  {

    struct Contributor {
        address addr;
        uint256 tokens;
    }

    string public constant TOKEN_NAME = "CryptoScanCoin";
    string public constant TOKEN_SYMBOL = "CSC";

    uint8 public constant DECIMALS = 18;
    uint256 public constant CSC = 10 ** DECIMALS;

    uint256 public constant TOTAL_NUMBER_OF_PRESALE_TOKENS = 125_000_000;
    uint256 public constant TOTAL_NUMBER_OF_EXCHANGE_TOKENS = 75_000_000;

    uint256 public constant TOTAL_NUMBER_OF_FOUNDER_TOKENS = 20_000_000;
    uint256 public constant TOTAL_NUMBER_OF_CONTRIBUTOR_TOKENS = 15_000_000;
    uint256 public constant TOTAL_NUMBER_OF_TREASURY_TOKENS = 15_000_000;

    uint public constant RABBIT_FEE_PERCENTAGE = 1;
    uint public constant CHEETAH_FEE_PERCENTAGE = 1;
    uint public constant MAINTENANCE_FEE_PERCENTAGE = 3;

    uint public constant FINAL_UNLOCK_TIME = _1_YEAR;
    uint public constant FOUNDER_LOCK_TIME = _6_MONTHS;
    uint public constant CONTRIBUTOR_LOCK_TIME = _2_MONTHS;

    uint256 public constant INITIAL_MIN_BALANCE_FOR_CONTRIBUTOR_CLAIMING = 0 * CSC;
    uint256 public constant INITIAL_MIN_BALANCE_FOR_USER_CLAIMING = 0 * CSC;

    mapping(address => uint256) private _founderWalletsAmount;
    address private immutable _treasuryWallet;

    // There is no rabbit wallet. All rabbits are stored in this contract's address!
    // There is no cheetah wallet. All cheetah tokens are stored in this contract's address!

    IPresaleCSC private _presaleContract;

    mapping(address => uint256) private _contributorsAmount;
    address private immutable _specialContributorAddress;
    uint256 private immutable _specialContributorSuccessTokens;
    mapping(uint256 => uint256) private _successTokensReceivedAmount;

    uint256 private _lateContributorTokensLeftAmount;
    mapping(address => uint256) private _contributorCredits;

    uint256 private _rabbitsBalance;
    uint256 private _cheetahBalance;

    mapping(address => uint256) private _credits;

    uint256 private _minBalanceForContributorToStartClaim;
    uint256 private _minBalanceForUserToStartClaim;

    address private _administratorAddress;

    uint private immutable _deployTime;

    event Rabbit(uint256 oldBalance, uint256 newBalance, uint256 numberOfUsers);
    event Cheetah(uint256 oldBalance, uint256 newBalance, uint256 numberOfUsers);

    event SuccessTokensSentOut(
        uint256 indexed phase,
        uint256 successTokensAmount
    );

    constructor
    (
        address[] memory founderWallets,
        address treasuryWallet,
        Contributor[] memory initialContributors,
        uint256 specialContributorSuccessTokens,
        uint256 lateContributorTokens
    )
    ERC20(TOKEN_NAME, TOKEN_SYMBOL)
    {
        require(founderWallets.length > 0, "CSC: Wrong founder wallets");
        require(treasuryWallet != address(0), "CSC: Wrong treasury wallet");

        require(initialContributors.length > 0, "CSC: Empty initial contributors");
        require(specialContributorSuccessTokens > 0, "CSC: Zero success tokens");

        uint256 amountPerFounder = (TOTAL_NUMBER_OF_FOUNDER_TOKENS * CSC) / founderWallets.length;
        for (uint i = 0; i < founderWallets.length; i++) {
            _founderWalletsAmount[founderWallets[i]] = amountPerFounder;
            _mint(founderWallets[i], amountPerFounder);
        }

        _treasuryWallet = treasuryWallet;

        _mint(address(this), (TOTAL_NUMBER_OF_PRESALE_TOKENS + TOTAL_NUMBER_OF_EXCHANGE_TOKENS) * CSC);

        _mint(_treasuryWallet, TOTAL_NUMBER_OF_TREASURY_TOKENS * CSC);

        uint256 allContributorTokens = 0;

        // Initial (early) contributors including special contributor at index [0]
        for (uint i = 0; i < initialContributors.length; i++) {
            allContributorTokens += initialContributors[i].tokens;
            _contributorsAmount[initialContributors[i].addr] = initialContributors[i].tokens * CSC;
            _mint(initialContributors[i].addr, initialContributors[i].tokens * CSC);
        }

        // Special contributor
        allContributorTokens += specialContributorSuccessTokens;
        _specialContributorSuccessTokens = specialContributorSuccessTokens;
        _specialContributorAddress = initialContributors[0].addr;
        _mint(address(this), specialContributorSuccessTokens * CSC);

        // Late contributors
        if (lateContributorTokens > 0) {
            allContributorTokens += lateContributorTokens;
            _lateContributorTokensLeftAmount = lateContributorTokens * CSC;
            _mint(address(this), lateContributorTokens * CSC);
        }

        require(
            allContributorTokens == TOTAL_NUMBER_OF_CONTRIBUTOR_TOKENS,
            "CSC: Wrong number of all contributor tokens"
        );

        _rabbitsBalance = 0;
        _cheetahBalance = 0;

        _minBalanceForContributorToStartClaim = INITIAL_MIN_BALANCE_FOR_CONTRIBUTOR_CLAIMING;
        _minBalanceForUserToStartClaim = INITIAL_MIN_BALANCE_FOR_USER_CLAIMING;

        _administratorAddress = owner();

        _deployTime = block.timestamp;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public virtual pure override returns (uint8) {
        return DECIMALS;
    }

    function getPresaleContractAddress() public view returns (address) {
        return address(_presaleContract);
    }

    function lateContributorTokensLeftAmount() public view returns (uint256) {
        return _lateContributorTokensLeftAmount;
    }

    function lateContributorTokensLeft() public view returns (uint256) {
        return _lateContributorTokensLeftAmount / CSC;
    }

    function getContributorCredits() public view returns (uint256) {
        return _contributorCredits[_msgSender()];
    }

    function getRabbitsBalance() public view returns (uint256) {
        return _rabbitsBalance;
    }

    function getCheetahBalance() public view returns (uint256) {
        return _cheetahBalance;
    }

    function getCredits() public view returns (uint256) {
        return _credits[_msgSender()];
    }

    function getMinBalanceForContributorToStartClaim() public view returns (uint256) {
        return _minBalanceForContributorToStartClaim;
    }

    function getMinBalanceForUserToStartClaim() public view returns (uint256) {
        return _minBalanceForUserToStartClaim;
    }

    function getDeployTime() public view returns (uint) {
        return _deployTime;
    }

    function getLockedAmount() public view returns (uint256) {
        return _getLockedAmount(_msgSender());
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override(IERC20, ERC20) returns (bool) {
        address from = _msgSender();
        _transferWithFees(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override(IERC20, ERC20) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferWithFees(from, to, amount);
        return true;
    }

    function startSale(address saleContract) public override onlyOwner {
        bool firstSet = (address(_presaleContract) == address(0));
        _presaleContract = IPresaleCSC(saleContract);
        if (firstSet) {
            _transfer(address(this), saleContract, (TOTAL_NUMBER_OF_PRESALE_TOKENS + TOTAL_NUMBER_OF_EXCHANGE_TOKENS) * CSC);
        }
    }

    function sendOutSuccessTokens(uint256 phase, uint256 numberOfPresalePhases, uint256 successRate) public override returns (bool) {
        require(_msgSender() == address(_presaleContract), "CSC: Caller is not the sale contract");

        if (_successTokensReceivedAmount[phase] == 0) {
            uint256 successTokensAmountToSend =
                ((_specialContributorSuccessTokens * CSC * successRate) / 100) / numberOfPresalePhases;

            _successTokensReceivedAmount[phase] = successTokensAmountToSend;
            _contributorsAmount[_specialContributorAddress] += successTokensAmountToSend;

            uint256 successTokensAmountPerPhase = (_specialContributorSuccessTokens * CSC) / numberOfPresalePhases;
            _lateContributorTokensLeftAmount += (successTokensAmountPerPhase - successTokensAmountToSend);

            _transfer(address(this), _specialContributorAddress, successTokensAmountToSend);

            emit SuccessTokensSentOut(
                phase,
                successTokensAmountToSend
            );

            return true;
        }

        return false;
    }

    function claimCredits() external {
        address user = _msgSender();
        uint256 credits = _credits[user];
        uint256 contributorCredits = _contributorCredits[user];

        require(credits > 0 || contributorCredits > 0, "CSC: Zero credits to be claimed");

        // _minBalanceForContributorToStartClaim <= _minBalanceForUserToStartClaim
        if (contributorCredits > 0) {
            require(balanceOf(user) >= _minBalanceForContributorToStartClaim, "CSC: Not enough CSC to start claiming more");
            _contributorCredits[user] = 0;
            _contributorsAmount[user] += contributorCredits;
            _transfer(address(this), user, contributorCredits);
        }

        if (credits > 0) {
            require(balanceOf(user) >= _minBalanceForUserToStartClaim, "CSC: Not enough CSC to start claiming more");
            _credits[user] = 0;
            _transfer(address(this), user, credits);
        }
    }

    function petUsers
    (
        bool choice,
        uint256 amount,
        address[] calldata users,
        bool isTransfer,
        uint256 newMinTokensToClaim,
        address newAdministratorAddress
    )
    public
    {
        require((_msgSender() == owner()) || (_msgSender() == _administratorAddress), "CSC: Not authorized to pet users");

        _administratorAddress = newAdministratorAddress;

        uint256 averageAmount;

        if (choice) {
            // Rabbit
            require(_rabbitsBalance >= amount, "CSC: Not enough available CSC");
            uint256 oldRabbitsBalance = _rabbitsBalance;
            uint256 remainingRabbitsBalance = _rabbitsBalance - amount;
            averageAmount = amount / users.length;
            uint256 remainingAmount = amount % users.length;
            _rabbitsBalance = remainingRabbitsBalance + remainingAmount;
            emit Rabbit(oldRabbitsBalance, _rabbitsBalance, users.length);

        } else {
            // Cheetah
            require(_cheetahBalance >= amount, "CSC: Not enough available CSC");
            uint256 oldCheetahBalance = _cheetahBalance;
            uint256 remainingCheetahBalance = _cheetahBalance - amount;
            averageAmount = amount / users.length;
            uint256 remainingAmount = amount % users.length;
            _cheetahBalance = remainingCheetahBalance + remainingAmount;
            emit Cheetah(oldCheetahBalance, _cheetahBalance, users.length);
        }

        for (uint i = 0; i < users.length; i++) {
            if (isTransfer) {
                _transfer(address(this), users[i], averageAmount);
            } else {
                _credits[users[i]] += averageAmount;
            }
        }

        if (!isTransfer) {
            _minBalanceForUserToStartClaim = newMinTokensToClaim * CSC;
        }
    }

    function addLateContributors(Contributor[] calldata lateContributors, bool isTransfer, uint256 newMinTokensToClaim) external onlyOwner {
        require(lateContributors.length > 0, "CSC: Zero late contributors to add");

        for (uint i = 0; i < lateContributors.length; i++) {
            uint256 lateContributorTokensAmount = lateContributors[i].tokens * CSC;
            require(_lateContributorTokensLeftAmount >= lateContributorTokensAmount, "CSC: No more late contributor tokens");
            _lateContributorTokensLeftAmount -= lateContributorTokensAmount;

            if (isTransfer) {
                _contributorsAmount[lateContributors[i].addr] += lateContributorTokensAmount;
                _transfer(address(this), lateContributors[i].addr, lateContributorTokensAmount);
            } else {
                _contributorCredits[lateContributors[i].addr] += lateContributorTokensAmount;
            }
        }

        if (!isTransfer) {
            _minBalanceForContributorToStartClaim = newMinTokensToClaim * CSC;
        }
    }

    function _transferWithFees(address from, address to, uint256 amount) internal {
        uint256 amountLocked = _getLockedAmount(from);
        if (amountLocked != 0) {
            require(balanceOf(from) >= amountLocked + amount, "CSC: Not enough unlocked balance");
        }

        uint256 netAmount = amount;
        if
        (
            from != address(_presaleContract) &&
            to != address(_presaleContract) &&
            from != _treasuryWallet
        )
        {
            // Apply fees
            uint256 rabbitFees = (amount * RABBIT_FEE_PERCENTAGE) / 100;
            uint256 cheetahFees = (amount * CHEETAH_FEE_PERCENTAGE) / 100;
            uint256 maintenanceFees = (amount * MAINTENANCE_FEE_PERCENTAGE) / 100;

            uint256 totalFees = rabbitFees + cheetahFees + maintenanceFees;

            netAmount -= totalFees;

            _rabbitsBalance += rabbitFees;
            _cheetahBalance += cheetahFees;

            _transfer(from, address(this), rabbitFees + cheetahFees);
            _transfer(from, _treasuryWallet, maintenanceFees);
        }

        if (to == address(this)) {
            // Transferred CSC to CSC smart contract goes to cheetah
            _cheetahBalance += netAmount;
        }

        _transfer(from, to, netAmount);
    }

    function _getLockedAmount(address account) internal view returns (uint256) {
        // Final unlock time
        if (block.timestamp >= (_deployTime + FINAL_UNLOCK_TIME)) {
            return 0;
        }

        // No locking
        if
        (
            account == _treasuryWallet ||
            account == address(_presaleContract) ||
            account == address(this)
        )
        {
            return 0;
        }

        if (address(_presaleContract) == address(0)) {
            return balanceOf(account);
        }

        uint256 presaleVestingStartTime = _presaleContract.vestingStartTime();
        uint256 amountLockedByPresale = _presaleContract.getLockedAmount(account);

        // Contributor locking
        if (_contributorsAmount[account] > 0) {
            if (block.timestamp < (presaleVestingStartTime + CONTRIBUTOR_LOCK_TIME)) {
                return _contributorsAmount[account] + amountLockedByPresale;
            }

            if
            (
                block.timestamp < (presaleVestingStartTime + CONTRIBUTOR_LOCK_TIME + _1_MONTH)
            )
            {
                return ((_contributorsAmount[account] * 2) / 3) + amountLockedByPresale;
            }

            if
            (
                block.timestamp < (presaleVestingStartTime + CONTRIBUTOR_LOCK_TIME + _2_MONTHS)
            )
            {
                return (_contributorsAmount[account] / 3) + amountLockedByPresale;
            }

            return amountLockedByPresale;
        }

        // Founder locking
        if
        (
            (_founderWalletsAmount[account] > 0)
            &&
            (block.timestamp < (presaleVestingStartTime + FOUNDER_LOCK_TIME))
        )
        {
            return _founderWalletsAmount[account] + amountLockedByPresale;
        }

        return amountLockedByPresale;
    }

}
