// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract DeflationaryTokenUpgradeableV2 is ERC20PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public maxTotalSupply; // max total supply

    address public defAddress; // deflationary address
    uint256 public defFixedFee; // deflationary fixed fee
    uint16 public defInterestRate; // deflationary interest rate, 1% equal 100
    uint16 private defMaxInterestRate; // deflationary max interest rate, 1% equal 100

    mapping(address => bool) internal blacklistedAddresses; // blacklisted addresses
    mapping(address => bool) internal whitelistedAddresses; // whitelisted addresses

    event UpdateDefAddress(address defAddress);
    event UpdateDefFixedFee(uint256 defFixedFee);
    event UpdateDefInterestRate(uint16 defInterestRate);
    event UpdateMaxTotalSupply(uint256 maxTotalSupply);

    event AddToBlacklist(address indexed blacklistAddress);
    event RemoveFromBlacklist(address indexed blacklistAddress);
    event AddToWhitelist(address indexed whitelistAddress);
    event RemoveFromWhitelist(address indexed whitelistAddress);

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _maxTotalSupply,
        address _defAddress,
        uint256 _defFixedFee,
        uint16 _defInterestRate
    ) initializer public {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();

        defMaxInterestRate = 2000;
        _setupDecimals(_decimals);
        maxTotalSupply = _maxTotalSupply;

        require(_defAddress != address(0), "DeflationaryToken: Invalid defAddress");
        require(_defInterestRate <= defMaxInterestRate, "DeflationaryToken: Invalid defInterestRate");
        defAddress = _defAddress;
        defFixedFee = _defFixedFee;
        defInterestRate = _defInterestRate;
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function mintAmount(
        address _mintAddress,
        uint256 _amount
    ) external onlyOwner nonReentrant notBlacklistedAddress(_mintAddress) {
        require(_mintAddress != address(0), "DeflationaryToken: Invalid mintAddress");
        _mint(_mintAddress, _amount);
        require(totalSupply() <= maxTotalSupply, "DeflationaryToken: Max total supply limit");
    }

    function updateDefAddress(address _defAddress) external onlyOwner {
        require(_defAddress != address(0), "DeflationaryToken: Invalid defAddress");
        defAddress = _defAddress;
        emit UpdateDefAddress(_defAddress);
    }

    function updateDefFixedFee(uint256 _defFixedFee) external onlyOwner {
        defFixedFee = _defFixedFee;
        emit UpdateDefFixedFee(_defFixedFee);
    }

    function updateDefInterestRate(uint16 _defInterestRate) external onlyOwner {
        require(_defInterestRate <= defMaxInterestRate, "DeflationaryToken: Invalid defInterestRate");
        defInterestRate = _defInterestRate;
        emit UpdateDefInterestRate(_defInterestRate);
    }

    function updateMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        require(_maxTotalSupply >= totalSupply(), "DeflationaryToken: Invalid maxTotalSupply");
        maxTotalSupply = _maxTotalSupply;
        emit UpdateMaxTotalSupply(_maxTotalSupply);
    }

    function addToBlacklist(address _blacklistAddress) external onlyOwner {
        blacklistedAddresses[_blacklistAddress] = true;
        emit AddToBlacklist(_blacklistAddress);
    }

    function removeFromBlacklist(address _blacklistAddress) external onlyOwner {
        blacklistedAddresses[_blacklistAddress] = false;
        emit RemoveFromBlacklist(_blacklistAddress);
    }

    function addToWhitelist(address _whitelistAddress) external onlyOwner {
        whitelistedAddresses[_whitelistAddress] = true;
        emit AddToWhitelist(_whitelistAddress);
    }

    function removeFromWhitelist(address _whitelistAddress) external onlyOwner {
        whitelistedAddresses[_whitelistAddress] = false;
        emit RemoveFromWhitelist(_whitelistAddress);
    }

    function isBlacklistedAddress(address _blacklistAddress) external view returns (bool) {
        return blacklistedAddresses[_blacklistAddress];
    }

    function isWhitelistedAddress(address _whitelistAddress) external view returns (bool) {
        return whitelistedAddresses[_whitelistAddress];
    }

    function calculateFee(address _from, address _to, uint256 _amount) public view returns (uint256) {
        if (whitelistedAddresses[_from] || whitelistedAddresses[_to]) {
            return 0;
        }
        uint256 defInterestFee = _amount.mul(defInterestRate).div(10000);
        return defFixedFee.add(defInterestFee);
    }

    function transfer(
        address _to,
        uint256 _amount
    ) public override notBlacklistedAddress(_msgSender()) notBlacklistedAddress(_to) returns (bool) {
        uint256 calculatedFee = calculateFee(_msgSender(), _to, _amount);
        if (calculatedFee > 0) {
            super.transfer(defAddress, calculatedFee);
        }
        return super.transfer(_to, _amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override notBlacklistedAddress(_msgSender()) notBlacklistedAddress(_from) notBlacklistedAddress(_to) returns (bool) {
        uint256 calculatedFee = calculateFee(_from, _to, _amount);
        if (calculatedFee > 0) {
            super.transferFrom(_from, defAddress, calculatedFee);
        }
        return super.transferFrom(_from, _to, _amount);
    }

    modifier notBlacklistedAddress(address _address) {
        require(!blacklistedAddresses[_address], "DeflationaryToken: Address is blacklisted");
        _;
    }
}
