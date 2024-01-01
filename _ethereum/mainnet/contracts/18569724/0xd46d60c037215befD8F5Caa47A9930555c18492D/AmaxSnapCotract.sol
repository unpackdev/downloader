// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./StringsUpgradeable.sol";

/// @title AMAX Snap Connect metamask
contract AmaxSnapContract is Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // evm from account => amax public key
    mapping(address => string) public evmPublicKeys;
    // amax public key => amax account name
    mapping(string => string) public amaxPublicKeys;
    // amax account name => amax public key
    mapping(string => string) public amaxAccounts;

    // account letter length => number of accounts
    mapping(uint256 => uint256) public freeAcctNumbers;

    // account letter length => number of accounts
    mapping(uint256 => uint256) public accountNumbers;
    // account letter length => payment price
    mapping(uint256 => uint256) public accountPrices;

    // amax account suffix
    string public amaxSuffix;

    // receiver USDT account
    address public receiver;
    // ERC20 USDT contract address
    IERC20Upgradeable public ERC20Usdt;

    // start timestamp
    uint64 public startTime;

    /// @notice bind amax data
    /// @param from - evm from account / 0xabc
    /// @param amax_pubkey - amax public key / AM prefix 52 length
    /// @param amax_acct - amax account name / 12 length
    event BindAmax(address indexed from, string amax_pubkey, string amax_acct);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Bind amax account data use metamask
    /// @param amax_pubkey - amax public key / AM prefix 52 length
    /// @param amax_acct - amax account name / 12 length
    /// @return bool - true is success
    function bind_amax(string calldata amax_pubkey, string calldata amax_acct) external whenNotPaused returns (bool) {
        require(uint64(block.timestamp) >= startTime, "The start time is not yet");
        require(bytes(amax_pubkey).length == 52, "Invalid AMAX publick key");
        require(_checkAmaxAcct(amax_acct), "Invalid AMAX account(1-5a-z)");
        string memory _fullAmaxAcct = string(abi.encodePacked(amax_acct, amaxSuffix));
        require(bytes(_fullAmaxAcct).length <= 12, "Invalid AMAX account");

        require(bytes(amaxAccounts[_fullAmaxAcct]).length == 0, "AMAX account already exists");
        require(bytes(evmPublicKeys[msg.sender]).length == 0, "EVM account already binded");
        require(bytes(amaxPublicKeys[amax_pubkey]).length == 0, "AMAX publick key already binded");

        uint256 _acctLen = bytes(amax_acct).length;
        if (_acctLen <= 5) {
            _paymentAmaxAccount(amax_pubkey, _acctLen, _fullAmaxAcct);
        } else {
            _bindAmaxAccount(amax_pubkey, _fullAmaxAcct);
        }

        return true;
    }

    /// @notice Bound amax account
    /// @param from - evm from account
    /// @param amax_pubkey - amax public key / AM prefix 52 length
    /// @return string - amax account name / 12 length
    function bound_amax(address from, string calldata amax_pubkey) external view returns (string memory) {
        string memory pubkey = evmPublicKeys[from];
        require(keccak256(abi.encodePacked(pubkey)) == keccak256(abi.encodePacked(amax_pubkey)), "Invalid amax_pubkey");
        return amaxPublicKeys[amax_pubkey];
    }

    /// @notice Bind amax account
    /// @param amax_pubkey amax public key
    /// @param fullAmaxAcct amax account name
    function _bindAmaxAccount(string calldata amax_pubkey, string memory fullAmaxAcct) private {
        evmPublicKeys[msg.sender] = amax_pubkey;
        amaxPublicKeys[amax_pubkey] = fullAmaxAcct;
        amaxAccounts[fullAmaxAcct] = amax_pubkey;

        emit BindAmax(msg.sender, amax_pubkey, fullAmaxAcct);
    }

    /// @notice Payment short amax account
    /// @param amax_pubkey amax public key
    /// @param _acctLen amax account length
    /// @param _fullAmaxAcct amax account fullname
    function _paymentAmaxAccount(string calldata amax_pubkey, uint256 _acctLen, string memory _fullAmaxAcct) private {
        uint256 acctNumber = freeAcctNumbers[_acctLen];
        bool isFree = true;
        if (acctNumber == 0) {
            acctNumber = accountNumbers[_acctLen];
            isFree = false;
            accountNumbers[_acctLen] -= 1;
        } else {
            freeAcctNumbers[_acctLen] -= 1;
        }
        require(acctNumber > 0, "Bind amax number is zero");

        if (!isFree) {
            uint256 amount = accountPrices[_acctLen];
            if (amount > 0) {
                ERC20Usdt.transferFrom(msg.sender, receiver, amount);
            }
        }

        _bindAmaxAccount(amax_pubkey, _fullAmaxAcct);
    }

    /// @notice Admin set short free amax account number
    /// @param letterLens short letter length
    /// @param numbers account number
    /// @return bool success return true
    function setFreeAcctNumber(uint256[5] calldata letterLens, uint256[5] calldata numbers) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < letterLens.length; i++) {
            require(letterLens[i] >= 1 && letterLens[i] <= 5, "Invalid account letter length");
            require(numbers[i] > 0, "Invalid account number");

            freeAcctNumbers[letterLens[i]] = numbers[i];
        }
        return true;
    }

    /// @notice Admin set short amax account number
    /// @param letterLens short letter length
    /// @param numbers account number
    /// @return bool success return true
    function setAccountNumber(uint256[5] calldata letterLens, uint256[5] calldata numbers) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < letterLens.length; i++) {
            require(letterLens[i] >= 1 && letterLens[i] <= 5, "Invalid account letter length");
            require(numbers[i] > 0, "Invalid account number");

            accountNumbers[letterLens[i]] = numbers[i];
        }
        return true;
    }

    /// @notice Admin set payment short amax account price
    /// @param letterLens short letter length
    /// @param amounts USDT amount
    /// @return bool success return true
    function setAccountPrice(uint256[5] calldata letterLens, uint256[5] calldata amounts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < letterLens.length; i++) {
            require(letterLens[i] >= 1 && letterLens[i] <= 5, "Invalid account letter length");
            require(amounts[i] > 0, "Invalid amount");

            accountPrices[letterLens[i]] = amounts[i];
        }

        return true;
    }

    /// @notice Admin set amax account suffix
    /// @param suffix bind amax account suffix .eth | .bsc
    /// @return bool success return true
    function setAmaxSuffix(string calldata suffix) external onlyOwner returns (bool) {
        uint256 suffixLen = bytes(suffix).length;
        require(suffixLen > 0 && suffixLen <= 5, "Invalid suffix");

        amaxSuffix = suffix;
        return true;
    }

    /// @notice Admin set ERC20 USDT receiver account
    /// @param _receiver evm receiver account
    /// @return bool success return true
    function setReceiver(address _receiver) external onlyOwner returns (bool) {
        require(_receiver != address(0), "Invalid receiver address");

        receiver = _receiver;
        return true;
    }

    /// @notice Admin set ERC20 USDT contract address
    /// @param usdtAddr ERC20 USDT address
    /// @return bool success return true
    function setUsdtAddress(address usdtAddr) external onlyOwner returns (bool) {
        require(usdtAddr != address(0), "Invalid usdt address");

        ERC20Usdt = IERC20Upgradeable(usdtAddr);
        return true;
    }

    /// @notice get uint256 max value
    /// @return uint256 uint256 max value
    function getMax() external pure returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Check amax account name
    /// @param amaxAcct - amax account name / only 1-5(49-53) a-z(97-122) letter
    /// @return bool success return true
    function _checkAmaxAcct(string calldata amaxAcct) private pure returns (bool) {
        bytes memory _amaxAcct = bytes(amaxAcct);
        bool isSucc = true;
        for (uint256 i = 0; i < _amaxAcct.length; i++) {
            uint8 _acct = uint8(_amaxAcct[i]);
            if (!((49 <= _acct && _acct <= 53) || (97 <= _acct && _acct <= 122))) {
                return false;
            }
        }
        return isSucc;
    }

    /// @notice Admin set start timestamp
    /// @param _timestamp start timestamp
    /// @return bool success return true
    function setStartTime(uint64 _timestamp) external onlyOwner returns (bool) {
        require(_timestamp >= uint64(block.timestamp), "Invalid timestamp");

        startTime = _timestamp;
        return true;
    }
}
