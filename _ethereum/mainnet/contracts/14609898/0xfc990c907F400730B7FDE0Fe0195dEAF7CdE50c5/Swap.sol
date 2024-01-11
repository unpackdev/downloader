// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract HybexSwap is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public swapToken;

    bool public enableblacklisting;

    mapping(address => bool) public blacklisted;

    mapping(address => uint256) public stakedAmountOf;

    //tier1 represents the value of tier1's maximum capped amount
    uint256 public tier1;

    //tier2 represents the value of tier2's maximum capped amount
    uint256 public tier2;

    //tier3 represents the value of tier3's maximum capped amount
    uint256 public tier3;

    //tier1 stake Amount represent users eligible tier
    uint256 public tier1StakeAmount;

    //tier2 stake Amount represents user's eligible tier
    uint256 public tier2StakeAmount;

    //tier3 stake Amount represents user's eligible tier
    uint256 public tier3StakeAmount;

    //tier1PreCappedAmount - tier 1's previous capped amount
    uint256 public tier1PreCappedAmount;

    //tier2PreCappedAmount - tier 2's previous capped amount
    uint256 public tier2PreCappedAmount;

    //tier3PreCappedAmount - tier 3's previous capped amount
    uint256 public tier3PreCappedAmount;

    //tier4PreCappedAmount - tier 4's previous capped amount
    uint256 public tier4PreCappedAmount;

    event SwapEmit(
        address indexed owner,
        uint256 capTier1,
        uint256 capTier2,
        uint256 capTier3,
        uint256 capTier4,
        uint256 _VisToken
    );
    event Swapped(address account, uint256 amount);
    event TokenFromContractTransferred(
        address externalAddress,
        address toAddress,
        uint amount
    );
    event TokenSwapUpdated(address token);
    event blacklistStatusUpdated(bool enable);
    event AccountblacklistUpdated(address indexed account, bool status);
    event AccountsblacklistUpdated(address[] indexed accounts, bool status);
    event SetTierStakingLimit(
        uint256 _tier1StakedAmount,
        uint256 _tier2StakedAmount,
        uint256 _tier3StakedAmount
    );
    event SetTierCapAmount(
        uint256 _tier1CapAmount,
        uint256 _tier2CapAmount,
        uint256 _tier3CapAmount
    );
    event SwapCalculateEmit(
        string VISTOKEN,
        uint256 capTier1,
        uint256 capTier2,
        uint256 capTier3,
        uint256 capTier4
    );
    event UpdateStakeAmount(
        address[] indexed _userAddress,
        uint256[] stakedAmount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _swapToken) public initializer {
        // initializing
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        tier1 = 200000 * 10 ** 6;
        tier2 = 350000 * 10 ** 6;
        tier3 = 500000 * 10 ** 6;

        tier1StakeAmount = 5000;
        tier2StakeAmount = 1000;
        tier3StakeAmount = 250;

        require(_swapToken != address(0), "Swap: Account cant be zero address");
        swapToken = IERC20Upgradeable(_swapToken);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
    @dev Check if address is blacklisted
    @param account - wallet address
  */
    function isblacklisted(address account) external view returns (bool) {
        return blacklisted[account];
    }

    /**
    @dev Swap tokens
    @param _capAmount - user likely to swap the token amount(must be greater than zero)
  */

    function swap(uint256 _capAmount,uint256 visToken) external nonReentrant whenNotPaused {
        require(_capAmount > 0, "Swap: Amount cant be zero");
        require(!blacklisted[msg.sender], "Swap: Account is blacklisted");

        swapToken.safeTransferFrom(msg.sender, address(this), _capAmount);

        uint256 _stakedAmount = stakedAmountOf[msg.sender];

        //tier1's balance capable amount
        uint256 tier1CapBalance = tier1 - tier1PreCappedAmount;
        uint256 tier1CurrentCappedAmount = tier1PreCappedAmount + _capAmount;

        //tier2's balance capable amount
        uint256 tier2CapBalance = tier2 - tier2PreCappedAmount;
        uint256 tier2CurrentCappedAmount = tier2PreCappedAmount + _capAmount;

        //tier3's balance capable amount
        uint256 tier3CapBalance = tier3 - tier3PreCappedAmount;
        uint256 tier3CurrentCappedAmount = tier3PreCappedAmount + _capAmount;

        //calculating tier4 requirements
        if (_stakedAmount < tier3StakeAmount) {
            tier4PreCappedAmount += _capAmount;
            uint256 _visToken = visToken;
            emit SwapEmit(msg.sender, 0, 0, 0, _capAmount,_visToken);
        }
        //calculating tier3 requirements
        else if (
            _stakedAmount >= tier3StakeAmount &&
            _stakedAmount < tier2StakeAmount
        ) {
            if (tier3CurrentCappedAmount <= tier3) {
                tier3PreCappedAmount += _capAmount;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, 0, 0, _capAmount, 0,_visToken);
            } else if (
                tier3PreCappedAmount <= tier3 && _capAmount > tier3CapBalance
            ) {
                uint256 tier3Cap = tier3 - tier3PreCappedAmount;
                uint256 tier4Cap = _capAmount - tier3Cap;
                tier3PreCappedAmount += tier3Cap;
                tier4PreCappedAmount += tier4Cap;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, 0, 0, tier3Cap, tier4Cap,_visToken);
            }
        }
        //calculating tier2 requirements
        else if (
            _stakedAmount >= tier2StakeAmount &&
            _stakedAmount < tier1StakeAmount
        ) {
            if (tier2CurrentCappedAmount <= tier2) {
                tier2PreCappedAmount += _capAmount;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, 0, _capAmount, 0, 0,_visToken);
            } else if (
                tier2PreCappedAmount <= tier2 &&
                _capAmount <= tier2CapBalance + tier3CapBalance
            ) {
                uint256 tier2Cap = tier2 - tier2PreCappedAmount;
                uint256 tier3Cap = _capAmount - tier2Cap;
                tier2PreCappedAmount += tier2Cap;
                tier3PreCappedAmount += tier3Cap;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, 0, tier2Cap, tier3Cap, 0,_visToken);
            } else if (
                tier2PreCappedAmount <= tier2 &&
                _capAmount > tier2CapBalance + tier3CapBalance
            ) {
                uint256 tier2Cap = tier2 - tier2PreCappedAmount;
                uint256 tier3Cap = tier3 - tier3PreCappedAmount;
                uint256 tier4Cap = _capAmount - (tier3Cap + tier2Cap);
                tier2PreCappedAmount += tier2Cap;
                tier3PreCappedAmount += tier3Cap;
                tier4PreCappedAmount += tier4Cap;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, 0, tier2Cap, tier3Cap, tier4Cap,_visToken);
            }
        }
        //calculating Tier1 Requirements
        else if (_stakedAmount >= tier1StakeAmount) {
            if (tier1CurrentCappedAmount <= tier1) {
                tier1PreCappedAmount += _capAmount;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, _capAmount, 0, 0, 0,_visToken);
            } else if (
                tier1PreCappedAmount <= tier1 &&
                _capAmount <= tier1CapBalance + tier2CapBalance
            ) {
                uint256 tier1Cap = tier1 - tier1PreCappedAmount;
                uint256 tier2Cap = _capAmount - tier1Cap;
                tier1PreCappedAmount += tier1Cap;
                tier2PreCappedAmount += tier2Cap;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, tier1Cap, tier2Cap, 0, 0,_visToken);
            } else if (
                tier1PreCappedAmount <= tier1 &&
                _capAmount <=
                tier1CapBalance + tier2CapBalance + tier3CapBalance &&
                _capAmount >= tier2CapBalance + tier1CapBalance
            ) {
                uint256 tier1Cap = tier1 - tier1PreCappedAmount;
                uint256 tier2Cap = tier2CapBalance;
                uint256 tier3Cap = _capAmount - (tier1Cap + tier2Cap);
                tier1PreCappedAmount += tier1Cap;
                tier2PreCappedAmount += tier2Cap;
                tier3PreCappedAmount += tier3Cap;
                uint256 _visToken = visToken;
                emit SwapEmit(msg.sender, tier1Cap, tier2Cap, tier3Cap, 0,_visToken);
            } else if (
                tier1PreCappedAmount <= tier1 &&
                _capAmount > tier1CapBalance + tier2CapBalance + tier3CapBalance
            ) {
                uint256 capAmt = _capAmount;
                uint256 tier1Cap = tier1 - tier1PreCappedAmount;
                uint256 tier2Cap = tier2CapBalance;
                uint256 tier3Cap = tier3CapBalance;
                uint256 tier4Cap = capAmt - tier1Cap - (tier2Cap + tier3Cap);

                tier1PreCappedAmount += tier1Cap;
                tier2PreCappedAmount += tier2Cap;
                tier3PreCappedAmount += tier3Cap;
                tier4PreCappedAmount += tier4Cap;
                uint256 _visToken = visToken;
                emit SwapEmit(
                    msg.sender,
                    tier1Cap,
                    tier2Cap,
                    tier3Cap,
                    tier4Cap,
                    _visToken
                );
            }
        }
    }

    /** 
    @dev Pause contract by owner
  */
    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    /**
     @dev set tier staking limit
     @param _tier1StakedAmount updates the tier1StakeAmount
     @param _tier2StakedAmount updates the tier2StakeAmount
     @param _tier3StakedAmount updates the tier3StakeAmount
      */
    function setTierStakingLimit(
        uint256 _tier1StakedAmount,
        uint256 _tier2StakedAmount,
        uint256 _tier3StakedAmount
    ) public onlyOwner {
        require(
            _tier1StakedAmount > _tier2StakedAmount,
            "Tier1 value must be greater than tier2"
        );
        require(
            _tier2StakedAmount > _tier3StakedAmount,
            "tier2 value must be greater than tier3"
        );
        tier1StakeAmount = _tier1StakedAmount;
        tier2StakeAmount = _tier2StakedAmount;
        tier3StakeAmount = _tier3StakedAmount;
        emit SetTierStakingLimit(
            _tier1StakedAmount,
            _tier2StakedAmount,
            _tier3StakedAmount
        );
    }

    /**
    @dev set all tier cap limit
    @param _tier1CapAmount updates the tier1 value
    @param _tier2CapAmount updates the tier2 value
    @param _tier3CapAmount updates the tier3 value
     */
    function setTierCapAmount(
        uint256 _tier1CapAmount,
        uint256 _tier2CapAmount,
        uint256 _tier3CapAmount
    ) public onlyOwner {
        tier1 = _tier1CapAmount;
        tier2 = _tier2CapAmount;
        tier3 = _tier3CapAmount;
        emit SetTierCapAmount(
            _tier1CapAmount,
            _tier2CapAmount,
            _tier3CapAmount
        );
    }

    /**
    @dev Unpause contract by owner
  */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    /**
    @dev Update Enable blacklisting
    @param enable - boolean
  */
    function updateEnableblacklisting(bool enable) external onlyOwner {
        require(enableblacklisting != enable, "Swap: Already in same status");
        enableblacklisting = enable;
        emit blacklistStatusUpdated(enable);
    }

    /**
    @dev Include specific address for blacklisting
    @param account - blacklisting address
  */
    function includeInblacklist(address account) external onlyOwner {
        require(account != address(0), "Swap: Account cant be zero address");
        require(!blacklisted[account], "Swap: Account is already blacklisted");
        blacklisted[account] = true;
        emit AccountblacklistUpdated(account, true);
    }

    /**
    @dev Exclude specific address from blacklisting
    @param account - blacklisting address
  */
    function excludeFromblacklist(address account) external onlyOwner {
        require(account != address(0), "Swap: Account cant be zero address");
        require(blacklisted[account], "Swap: Account is not blacklisted");
        blacklisted[account] = false;
        emit AccountblacklistUpdated(account, false);
    }

    /**
    @dev Include multiple address for blacklisting
    @param accounts - blacklisting addresses
  */
    function includeAllInblacklist(address[] memory accounts)
        external
        onlyOwner
    {
        for (uint256 account = 0; account < accounts.length; account++) {
            if (!blacklisted[accounts[account]]) {
                blacklisted[accounts[account]] = true;
            }
        }
        emit AccountsblacklistUpdated(accounts, true);
    }

    /**
    @dev Exclude multiple address from blacklisting
    @param accounts - blacklisting address
  */
    function excludeAllFromblacklist(address[] memory accounts)
        external
        onlyOwner
    {
        for (uint256 account = 0; account < accounts.length; account++) {
            if (blacklisted[accounts[account]]) {
                blacklisted[accounts[account]] = false;
            }
        }
        emit AccountsblacklistUpdated(accounts, false);
    }

    /**
    @dev Update swap token by owner
    @param token - cannot be the zero address.
  */
    function updateSwapToken(address token)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        require(token != address(0), "Token cant be zero address");
        swapToken = IERC20Upgradeable(token);
        emit TokenSwapUpdated(token);
    }

    /**
    @dev update Users take amount
    @param _userAddress represents the user address
    @param stakedAmount updates the users staked amount
  */
    function updateStakeAmount(
        address[] memory _userAddress,
        uint256[] memory stakedAmount
    ) public onlyOwner {
        require(
            _userAddress.length == stakedAmount.length,
            "Unequal paramaters length"
        );
        for (uint256 i = 0; i < _userAddress.length; i++)
            stakedAmountOf[_userAddress[i]] = stakedAmount[i];
        emit UpdateStakeAmount(_userAddress, stakedAmount);
    }

    /**
    @dev Recover BEP20 token from the contract address by owner
    @param _tokenAddress - cannot be the zero address.
    @param amount - cannot be greater than balance.
  */
    function withdrawBEP20(address _tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(_tokenAddress != address(0), "Address cant be zero address");
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenAddress);
        require(
            amount <= tokenContract.balanceOf(address(this)),
            "Amount exceeds balance"
        );
        tokenContract.transfer(msg.sender, amount);
        emit TokenFromContractTransferred(_tokenAddress, msg.sender, amount);
    }

    //Calculate the respective tier amount and balance
    function swapCalculate(address _account)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        
        uint256 tier1Balance = tier1 - tier1PreCappedAmount;
        uint256 tier2Balance = tier2 - tier2PreCappedAmount;
        uint256 tier3Balance = tier3 - tier3PreCappedAmount;
        if (
            stakedAmountOf[_account] >= tier2StakeAmount &&
            stakedAmountOf[_account] < tier1StakeAmount
        ) {
            //tier 2
            string memory Intier = "Tier2";
            return (Intier, 0, tier2Balance, tier3Balance, 0);
        } else if (
            stakedAmountOf[_account] >= tier3StakeAmount &&
            stakedAmountOf[_account] < tier2StakeAmount
        ) {
            //tier 3
            string memory Intier = "Tier3";
            return (Intier, 0, 0, tier3Balance,0);
        } else if (stakedAmountOf[_account] >= tier1StakeAmount) {
            //tier 1
            string memory Intier = "Tier1";
            return (Intier, tier1Balance, tier2Balance, tier3Balance, 0);
        } else {
            //tier 4
            string memory Intier = "Tier4";
            return (Intier, 0, 0, 0, 0);
        }
    }
}
