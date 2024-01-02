// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21;

import "./Ownable.sol";
import "./IReferralStorage.sol";

contract ReferralStorage is Ownable, IReferralStorage {
    mapping(address => bool) public isHandler;
    mapping(bytes32 => address) public override codeOwner;
    mapping(address => bytes32) public override accountCodeOwned;
    mapping(address => bytes32) public override accountReferralCode;

    event RegisterCode(address account, bytes32 code);
    event SetAccountReferralCode(address account, bytes32 code);
    event SetCodeOwner(bytes32 code, address newAccount);
    event AdminSetCodeOwner(bytes32 code, address newAccount);

    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable(msg.sender) { }

    /// @dev Registers an handler.
    /// @param _account The account.
    /// @param _isActive Flag to activate/deactivate the handler.
    function registerHandler(address _account, bool _isActive) external onlyOwner {
        isHandler[_account] = _isActive;
    }

    /// @dev Registers a referral code.
    /// @param _code The referral code.
    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: invalid code");
        require(codeOwner[_code] == address(0), "ReferralStorage: code already exists");
        require(accountCodeOwned[msg.sender] == bytes32(0), "ReferralStorage: account already has a code");

        codeOwner[_code] = msg.sender;
        accountCodeOwned[msg.sender] = _code;

        emit RegisterCode(msg.sender, _code);
    }

    /// @dev Sets a referral code for the given account.
    /// @param _account The account to set the referral code for.
    /// @param _code The referral code.
    function setAccountReferralCode(address _account, bytes32 _code) external override {
        require(isHandler[msg.sender], "ReferralStorage: forbidden");
        require(codeOwner[_code] != address(0), "ReferralStorage: code doesn't exist");
        require(codeOwner[_code] != _account, "ReferralStorage: can't set own code");
        _setAccountReferralCode(_account, _code);
    }

    /// @dev Sets a referral code for the caller.
    /// @param _code The referral code.
    function adminSetCodeOwner(bytes32 _code, address _newAccount) external override onlyOwner {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        address oldOwner = codeOwner[_code];

        codeOwner[_code] = _newAccount;
        accountCodeOwned[_newAccount] = _code;
        accountCodeOwned[oldOwner] = bytes32(0);

        emit AdminSetCodeOwner(_code, _newAccount);
    }

    /// @dev Returns referral info for the account.
    /// @param _account The account.
    function getAccountReferralInfo(address _account) external view override returns (bytes32, address) {
        bytes32 code = accountReferralCode[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwner[code];
        }
        return (code, referrer);
    }

    /// @dev Sets a referral code for the account.
    /// @param _account The account.
    /// @param _code The referral code.
    function _setAccountReferralCode(address _account, bytes32 _code) private {
        accountReferralCode[_account] = _code;
        emit SetAccountReferralCode(_account, _code);
    }
}
