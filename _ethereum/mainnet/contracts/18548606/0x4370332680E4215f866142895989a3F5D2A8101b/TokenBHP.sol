//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./console.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./errors.sol";
import "./TokenJOMO.sol";

contract TokenBHP is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 1618 * 10 ** 6 * 10 ** 18;
    uint256 private constant oneDistributionPart = MAX_SUPPLY / 5;
    uint256 private constant marketingEcosystemUnlocked = oneDistributionPart / 5;

    address private stakingContractAddress;
    address private governanceContractAddress;
    address private multiSignContractAddress;
    address private royaltyAddress;
    address private preSalePaymentToken;
    uint64 private feeEnabledAfter;
    uint64 private feeDisabledAfter;
    uint64 public constant timeFeeStart = 30 days * 4;
    uint64 public constant timeFeeEnd = 30 days * 42;

    // Ecosystem rewards & Marketing vesting
    uint64 public vestingStart;
    uint64 public vestingEnd;
    uint256 public ecosystemVestingMinted;
    uint256 public marketingVestingMinted;
    uint256 public presaleMinted;

    mapping(address => bool) public excludedFromFee;

    event PresaleMinted(address indexed user, uint256 amount);

    constructor(
        address _initialOwner, string memory _name, string memory _symbol,
        address _multiSignAddress, address _preSaleAddress, address _royaltyAddress
    )
    ERC20(_name, _symbol)
    Ownable(_initialOwner)
    {
        feeEnabledAfter = uint64(block.timestamp) + timeFeeStart;
        feeDisabledAfter = feeEnabledAfter + timeFeeEnd;
        multiSignContractAddress = _multiSignAddress;
        preSalePaymentToken = _preSaleAddress;
        royaltyAddress = _royaltyAddress;

        // Ecosystem & Marketing - 2 years vesting
        vestingStart = uint64(block.timestamp);
        vestingEnd = uint64(block.timestamp) + 720 days;

        // Mint 20% of total supply for LP
        _mint(msg.sender, oneDistributionPart);

        // Mint 20% from Marketing (4% from total) + 20% from Ecosystem (4% from total), rest amount by vesting
        _mint(multiSignContractAddress, marketingEcosystemUnlocked * 2);

        // exclude mint new tokens fees
        excludedFromFee[address(0)] = true;
    }

    // ------------------ Public/External ------------------

    function _update(address _from, address _to, uint256 _value)
    internal
    override(ERC20)
    {
        if (governanceContractAddress != address(0)) {
            TokenJOMO _govToken = TokenJOMO(governanceContractAddress);
            if (_from != address(0) && _from != stakingContractAddress) {
                _govToken.mintRewards(_from);
            }
            if (_to != address(0) && _to != stakingContractAddress) {
                _govToken.mintRewards(_to);
            }
        }

        if (excludedFromFee[_from] || excludedFromFee[_to] || block.timestamp < feeEnabledAfter || block.timestamp > feeDisabledAfter) {
            super._update(_from, _to, _value);
            return;
        }

        uint256 _taxPct = _value * 309 / 100000; // 0.309 %
        super._update(_from, multiSignContractAddress, _taxPct);
        super._update(_from, royaltyAddress, _taxPct);
        super._update(_from, _to, _value - _taxPct * 2);
    }

    function ecosystemMint()
    external
    {
        if (multiSignContractAddress == address(0)) {
            revert Token_MultisigNotSet();
        }

        uint256 _availableForMint = getEcosystemUnlocked();
        uint256 _minUnlockAmount = oneDistributionPart / 5;

        if (_availableForMint >= _minUnlockAmount) {
            _mint(multiSignContractAddress, _minUnlockAmount);
            ecosystemVestingMinted += _minUnlockAmount;
        }
    }

    // @title Get ecosystem amount available for mint
    function getEcosystemUnlocked()
    public view
    returns (uint256)
    {
        return getEcosystemMarketingUnlocked() - ecosystemVestingMinted;
    }

    function marketingMint()
    external
    {
        if (multiSignContractAddress == address(0)) {
            revert Token_MultisigNotSet();
        }

        uint256 _availableForMint = getMarketingUnlocked();
        uint256 _minUnlockAmount = oneDistributionPart / 5;

        if (_availableForMint >= _minUnlockAmount) {
            _mint(multiSignContractAddress, _minUnlockAmount);
            marketingVestingMinted += _minUnlockAmount;
        }
    }

    // @title Get marketing amount available for mint
    function getMarketingUnlocked()
    public view
    returns (uint256)
    {
        return getEcosystemMarketingUnlocked() - marketingVestingMinted;
    }

    // @title Get ecosystem & marketing unlocked amount
    function getEcosystemMarketingUnlocked()
    public view
    returns (uint256)
    {
        if (block.timestamp < vestingStart || vestingEnd < vestingStart) {
            return 0;
        }

        uint256 _unlockedAmount;
        if (block.timestamp >= vestingEnd) {
            _unlockedAmount = oneDistributionPart - marketingEcosystemUnlocked;
        } else {
            uint64 _duration = vestingEnd - vestingStart;
            _unlockedAmount = ((oneDistributionPart - marketingEcosystemUnlocked) * (block.timestamp - vestingStart)) / _duration;
        }

        return _unlockedAmount;
    }

    // @title Buy BHP tokens for ERC20 token
    // amount - count of tokens to buy (not wei)
    function preSaleMint(uint32 _amount)
    external
    {
        uint256 _amountWei = uint256(_amount) * 10 ** 18;
        if (_amount == 0) {
            revert Token_WrongInputUint();
        }
        if (presaleMinted + _amountWei > oneDistributionPart) {
            revert Token_PresaleLimitReached();
        }

        uint256 _totalPrice = getPreSalePrice(_amount);
        IERC20 _token = IERC20(preSalePaymentToken);
        SafeERC20.safeTransferFrom(_token, msg.sender, multiSignContractAddress, _totalPrice);

        presaleMinted += _amountWei;
        _mint(msg.sender, _amountWei);

        emit PresaleMinted(msg.sender, _amount);
    }

    // @title Buy BHP tokens for ETH
    // amount - count of tokens to buy (not wei)
    function preSaleMintEth(uint32 _amount)
    external payable
    {
        uint256 _amountWei = uint256(_amount) * 10 ** 18;
        if (_amount == 0) {
            revert Token_WrongInputUint();
        }
        if (presaleMinted + _amountWei > oneDistributionPart) {
            revert Token_PresaleLimitReached();
        }

        uint256 _totalPriceETH = getPreSalePriceEth(_amount);
        if (msg.value < _totalPriceETH) {
            revert Token_PresaleNotEnoughETH();
        }

        presaleMinted += _amountWei;
        _mint(msg.sender, _amountWei);

        emit PresaleMinted(msg.sender, _amount);
    }

    // @title Get pre-sale price for ERC20 token
    // amount - count of tokens to buy (not wei)
    function getPreSalePrice(uint32 _amount)
    public view
    returns (uint256)
    {
        uint256 _denominator = 1000;
        uint256 _priceOne = 10 ** 6 / 1000;
        uint256 _amountWei = uint256(_amount) * 10 ** 18;
        uint256 _soldPct = (presaleMinted + _amountWei) * 100 * _denominator / oneDistributionPart;

        if (_soldPct < 20 * _denominator) {
            return 1 * _priceOne * _amount;
        } else if (_soldPct < 40 * _denominator) {
            return 3 * _priceOne * _amount;
        } else if (_soldPct < 60 * _denominator) {
            return 8 * _priceOne * _amount;
        } else if (_soldPct < 80 * _denominator) {
            return 21 * _priceOne * _amount;
        }
        return 34 * _priceOne * _amount;
    }

    // @title Get pre-sale price for ETH
    function getPreSalePriceEth(uint32 _amount)
    public view
    returns (uint256)
    {
        return (getPreSalePrice(_amount) * 10 ** 12) / 2000;
    }

    // ------------------ Only Owner ------------------

    function exclude(address _addr, bool _status)
    external
    onlyOwner
    {
        excludedFromFee[_addr] = _status;
    }


    function setGovernanceTokenAddress(address _govAddress)
    external
    onlyOwner
    {
        if (_govAddress == address(0)) {
            revert Token_WrongInputAddress();
        }
        if (governanceContractAddress != address(0)) {
            revert Token_GovernanceAlreadySet();
        }
        governanceContractAddress = _govAddress;
    }

    function setStakingContractAddress(address _stakingAddress)
    external
    onlyOwner
    {
        if (_stakingAddress == address(0)) {
            revert Token_WrongInputAddress();
        }
        if (stakingContractAddress != address(0)) {
            revert Token_StakingAlreadySet();
        }

        // Staking contract, exclude from fee
        stakingContractAddress = _stakingAddress;
        excludedFromFee[stakingContractAddress] = true;

        // Mint 20% for staking
        _mint(stakingContractAddress, oneDistributionPart);
    }
}


