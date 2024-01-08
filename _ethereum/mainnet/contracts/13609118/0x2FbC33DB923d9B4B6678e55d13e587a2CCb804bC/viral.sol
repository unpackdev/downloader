// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

/*
BEGIN KEYBASE SALTPACK SIGNED MESSAGE. kXR7VktZdyH7rvq v5weRa0zkYfegFM 5cM6gB7cyPatQvp 6KyygX8PsvQVo4n Ugo6Il5bm5uWrwV gfKz4IMGvvw0ZCQ QJai8AcoC5xNiFh PGioCgTkGBEInLL uz40oe8lYwjoXoM eTXsRVcG6KdNwsH nQS2X4ruHIv5Ffi QLYkL1vejSBJL8Z RvdM02suYKeOkm0 Hwf7STe3UtViWlg J7QZUO3TuLtxC1i L9Gy5HSUv8k9ZXE T1jUkD7myLRQ1MO SDAAAIpj9yVw7i. END KEYBASE SALTPACK SIGNED MESSAGE.
*/

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 * @dev Implementation of the VIRAL token.
 *
 * Viral is a GSN supporting ERC20 token with:
 *  - a variable token supply
 *  - a 5% fee on transfer such that:
 *    - 3% is redistributed to all eligible token holders
 *    - 1% is awarded to the team wallet (aka the default referrer)
 *    - 1% is awarded to the referrer of the recipient address (fallbacks to the default referrer)
 *
 * Every address can chose to set (only once) its referrer, by calling the `addReferrer` function.
 * The default value for addresses that chose not to set this value is the default referrer address
 *
 * The `owner` has the ability to:
 *  - exclude/include addresses from/in fees on transfer
 *  - exclude/include addresses from/in reflection rewards
 *  - allow/disallow an address to mint VIRAL tokens
 *  - allow/disallow an address to burn VIRAL tokens
 *  - update the trustedForwarder address
 *  - update the fee on transfer (upto a maximum of 5% of transaction amount)
 */
contract Viral is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private _isMinter;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;

    mapping(address => bool) private _isReferredYet;
    mapping(address => address) private _referrerOf;
    mapping(address => uint256) private _referralCountOf;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lastDividendPoints;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant pointMultiplier = 10**18;
    uint256 private _totalSupply;
    uint256 private _totalReferrals;
    uint256 private _totalDividendPoints;
    uint256 private _excludedFromRewardSupply;

    uint256 public totalFee = 5;
    uint256 public viralFee = 1;
    uint256 public referralFee = 1;

    address public defaultReferrer;
    address public trustedForwarder;

    bool public isMintingAllowed = true;

    string private _name = "Viral";
    string private _symbol = "VIRAL";

    constructor(address _defaultReferrer) public {

        defaultReferrer = _defaultReferrer;

        _isMinter[owner()] = true;
        _isExcludedFromFee[owner()] = true;

        _isExcludedFromReward[address(0)] = true;
        _isExcludedFromReward[_defaultReferrer] = true;

        _referrerOf[_defaultReferrer] = address(0);
        _isReferredYet[_defaultReferrer] = true;

        _mint(_msgSender(), 10000000 * 10**18); // a starting supply of 10,000,000 tokens worth $100
    }

    modifier onlyMinter() {
        require(_isMinter[_msgSender()], "VIRAL: Minter only");
        _;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function versionRecipient() external pure returns (string memory) {
        return "1.0.0";
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function totalReferrals() external view returns (uint256) {
        return _totalReferrals;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account].add(_dividendsOwing(account));
    }

    function referrerOf(address account) public view returns (address) {
        if(_isReferredYet[account]) {
            return _referrerOf[account];
        }
        return defaultReferrer;
    }

    function referralCountOf(address account) public view returns (uint256) {
        return _referralCountOf[account];
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function addReferrer(address _referrer) external {
        _addReferrer(_msgSender(), _referrer);
    }

    function burn(uint256 amount) external onlyMinter() {
        _burn(_msgSender(), amount);
    }

    function mint(address account, uint256 amount) external onlyMinter() {
        require(isMintingAllowed, "VIRAL: Minting not allowed anymore");
        _mint(account, amount);
    }

    function disableMinting() external onlyMinter() {
        require(isMintingAllowed, "VIRAL: Minting already disabled");
        isMintingAllowed = false;
    }

    function enableMinting() external onlyOwner() {
        require(!isMintingAllowed, "VIRAL: Minting already enabled");
        isMintingAllowed = true;
    }

    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromReward[account], "VIRAL: Account already excluded");
        _updateAccount(account);
        _isExcludedFromReward[account] = true;
        _excludedFromRewardSupply = _excludedFromRewardSupply.add(_balances[account]);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "VIRAL: Account not excluded");
        _updateAccount(account);
        _isExcludedFromReward[account] = false;
        _excludedFromRewardSupply = _excludedFromRewardSupply.sub(_balances[account]);
    }

    function excludeFromFee(address account) external onlyOwner() {
        require(!_isExcludedFromFee[account], "VIRAL: Account already excluded");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        require(_isExcludedFromFee[account], "VIRAL: Account not excluded");
        _isExcludedFromFee[account] = false;
    }

    function addMinter(address account) external onlyOwner() {
        require(!_isMinter[account], "VIRAL: Account already a minter");
        _isMinter[account] = true;
    }

    function removeMinter(address account) external onlyOwner() {
        require(_isMinter[account], "VIRAL: Account is not a minter");
        _isMinter[account] = false;
    }

    function updateTrustedForwarder(address forwarder) external onlyOwner() {
        trustedForwarder = forwarder;
    }

    function _disburse(uint256 rAmount) private {
        if(rAmount != 0) {
            uint256 newDividendPoints = rAmount.mul(pointMultiplier).div(_totalSupply.sub(_excludedFromRewardSupply));
            _totalDividendPoints = _totalDividendPoints.add(newDividendPoints);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != recipient, "ERC20: transfer to self");

        _beforeTokenTransfer(sender, recipient);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        address defaultReferrer_ = defaultReferrer;
        address rReferrer = referrerOf(recipient);

        bool isDistinctDefaultRef;
        bool isDistinctRecipientRef;

        if(defaultReferrer_ != sender && defaultReferrer_ != recipient) {
            isDistinctDefaultRef = true;
        }

        if(rReferrer != recipient && rReferrer != sender && rReferrer != defaultReferrer_) {
            isDistinctRecipientRef = true;
        }

        uint256 dAmount;
        uint256 tAmount = amount;
        if (!_isExcludedFromFee[sender]) {
            /*
            amount : input amount
            tAmount : transfer amount
            fAmount : fee amount
            rAmount : referrer amount
            vAmount : viral team amount
            dAmount : distribution amount
            */
            uint256 totalFee_ = totalFee;
            uint256 fAmount = amount.mul(totalFee_).div(100);
            tAmount = amount.sub(fAmount);

            uint256 rAmount = referralFee.mul(fAmount).div(totalFee_);
            uint256 vAmount = viralFee.mul(fAmount).div(totalFee_);
            dAmount = fAmount.sub(rAmount).sub(vAmount);

            if (isDistinctDefaultRef) {
                _updateAccount(defaultReferrer_);
            }
            if (isDistinctRecipientRef) {
                _updateAccount(rReferrer);
            }

            _balances[defaultReferrer_] = _balances[defaultReferrer_].add(vAmount);
            _balances[rReferrer] = _balances[rReferrer].add(rAmount);

            if (isDistinctDefaultRef && _isExcludedFromReward[defaultReferrer_]) {
                _excludedFromRewardSupply = _excludedFromRewardSupply.add(vAmount);
            }
            if (isDistinctRecipientRef && _isExcludedFromReward[rReferrer]) {
                _excludedFromRewardSupply = _excludedFromRewardSupply.add(rAmount);
            }
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tAmount);

        if (_isExcludedFromReward[sender]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.sub(amount);
        }
        if (_isExcludedFromReward[recipient]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.add(tAmount);
        }

        _disburse(dAmount);

        emit Transfer(sender, recipient, tAmount);
    }

    function _addReferrer(address _referee, address _referrer) internal {
        require(!_isReferredYet[_referee], "VIRAL: Account already referred");

        _referrerOf[_referee] = _referrer;
        _isReferredYet[_referee] = true;

        _referralCountOf[_referrer] = _referralCountOf[_referrer].add(1);
        _totalReferrals = _totalReferrals.add(1);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        if(_isExcludedFromReward[account]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.add(amount);
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        if(_isExcludedFromReward[account]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.sub(amount);
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _dividendsOwing(address account) internal view returns (uint256) {
        if (_isExcludedFromReward[account]) {
            return 0;
        }
        uint256 newDividendPoints = _totalDividendPoints.sub(_lastDividendPoints[account]);
        return _balances[account].mul(newDividendPoints).div(pointMultiplier);
    }

    function _updateAccount(address account) internal {
        uint256 owing = _dividendsOwing(account);
        if (owing > 0) {
            _balances[account] = _balances[account].add(owing);
            if(_isExcludedFromReward[account]) {
                _excludedFromRewardSupply = _excludedFromRewardSupply.add(owing);
            }
        }
        _lastDividendPoints[account] = _totalDividendPoints;
    }

    function _beforeTokenTransfer(address from, address to) internal {
        _updateAccount(from);
        _updateAccount(to);
    }

    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}
