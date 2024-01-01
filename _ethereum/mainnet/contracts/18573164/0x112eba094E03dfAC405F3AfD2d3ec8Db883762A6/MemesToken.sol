// SPDX-License-Identifier: MIT
/** 
Telegram: https://t.me/MemesTokenOfficial
Twitter: https://twitter.com/MemestokenO
Discord: https://discord.gg/c6xkZSKGXT
Website: https://memestoken.com/
**/

pragma solidity ^0.8.21;

import "./Context.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Memes Token's token contract
 * @author Pwned (https://github.com/Pwnedev)
 */
contract MemesToken is Context, IERC20Metadata, Ownable, ReentrancyGuard {
    string private _name = "Memes Token";
    string private _symbol = "MEMES";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100000000 * 10 ** _decimals; // Aka: "true total" or "tTotal"

    mapping(address => uint256) private _rOwned; // User's balance represented in r-space
    mapping(address => uint256) private _tOwned; // User's balance represented in t-space (only used by non-stakers)
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    address[] private _excludedFromRewardAddresses;

    uint256 private constant MAX = ~uint256(0); // Max value of uint256 === (2^256)-1
    uint256 private _rTotal = (MAX - (MAX % _totalSupply)); // Aka: reflected total (_rTotal is always a multiple of _totalSupply)
    uint256 private _tFeeTotal;

    uint256 private constant MAX_TAX_FEE_VALUE = 9;
    uint256 public _taxFee = 6;
    uint256 private _previousTaxFee = _taxFee;

    bytes32 public _migrationMerkleRoot = 0;
    bool public _isMigrationTokenWithdrawalActive = false;
    mapping(address => bool) public _tokenMigrationClaimed;

    bool public _transfersPaused = false;

    modifier notPaused() {
        require(_transfersPaused == false, "All transfers are currently paused due to an emergency");
        _;
    }

    event TaxFeeChanged(uint256 oldValue, uint256 newValue);
    event TransfersPaused();
    event TransfersResumed();

    constructor() Ownable(_msgSender()) {
        _rOwned[_msgSender()] = _rTotal;

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // Also exclude contract from reward
        _isExcludedFromReward[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @notice Returns token name
     * @dev See {IERC20Metadata}
     * @return Token name
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns token symbol
     * @dev See {IERC20Metadata}
     * @return Token symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns number of token decimals
     * @dev See {IERC20Metadata}
     * @return Number of token decimals
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Returns number of all tokens in existence
     * @dev See {IERC20Metadata}
     * @return Number of all tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns given `account`'s current balance
     * @dev See {IERC20Metadata}
     * @param account The account to get balance from
     * @return Given account's current balance
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
     * @notice Transfers given `ammount` of tokens from caller to `recipient`
     * @dev See {IERC20Metadata}
     * @param recipient The account that will receive the tokens
     * @param amount Amount of tokens that the `recipient` will receive
     * @return true if operation succeeded, false otherwise
     */
    function transfer(address recipient, uint256 amount) public override notPaused() returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice Returns amount of tokens `spender` is allowed to use on behalf of `owner` through {transferFrom}
     * @dev See {IERC20Metadata}
     * @param owner The account that owns the tokens
     * @param spender The account that may spend the tokens
     * @return Amount of tokens `spender` is allowed to use on behalf of `owner` through {transferFrom}
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens
     * @dev See {IERC20Metadata}
     * @param spender Spender account
     * @param amount Amount of tokens to set as allowance of `spender`
     * @return true if operation succeeded, false otherwise
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
     * @dev See {IERC20Metadata}
     * @param sender Account that caller will take tokens from
     * @param recipient Account that receives the tokens
     * @param amount Amount of tokens to send from `sender` to `recipient`
     * @return true if operation succeeded, false otherwise
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override notPaused() returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev This function is only used internaly by the {transfer} function.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Check if we should takeFee
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }

    /**
     * @dev This function is only used internaly by the {approve} function.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Increases the allowance granted to `spender` by the caller.
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * @param spender Target account to increase allowance
     * @param addedValue Amount of tokens added to allowance
     * @return true if operation succeeded, false otherwise
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @notice Decreases the allowance granted to `spender` by the caller.
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * @param spender Target account to decrease allowance
     * @param subtractedValue Amount of tokens removed from allowance
     * @return true if operation succeeded, false otherwise
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Function to withdraw "ERC20" tokens from contract
     */
    function withdrawERC20(IERC20 _token) external onlyOwner() {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(owner(), balance);
    }

    /**
     * @dev Function to withdraw "ETH" from contract
     */
    function withdrawETH() external onlyOwner() {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @notice Returns true if given `account` is excluded from fee, false otherwise
     * @param account Target account to check if excluded from fee
     * @return true if given `account` is excluded from fee, false otherwise
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @dev Excludes target `account` from fee
     */
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @dev Includes target `account` in fee
     */
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @notice Returns true if given `account` is excluded from reward, false otherwise
     * @param account Target account to check if excluded from reward
     * @return true if given `account` is excluded from reward, false otherwise
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    /**
     * @dev Excludes target `account` from reward
     */
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");

        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }

        _isExcludedFromReward[account] = true;
        _excludedFromRewardAddresses.push(account);
    }

    /**
     * @dev Includes target `account` in reward
     */
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");

        for (uint256 i = 0; i < _excludedFromRewardAddresses.length; i++) {
            if (_excludedFromRewardAddresses[i] == account) {
                _excludedFromRewardAddresses[i] = _excludedFromRewardAddresses[_excludedFromRewardAddresses.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromRewardAddresses.pop();
                break;
            }
        }
    }

    /**
     * @dev Function to set fee percentage
     */
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee <= MAX_TAX_FEE_VALUE, "Tax fee must be less or equal to max tax fee value");
        emit TaxFeeChanged(_taxFee, taxFee);
        _taxFee = taxFee;
    }

    /**
     * @dev This function is only used by {_tokenTransfer} to remove fees when an "excluded from fee" address is making a transfer
     */
    function removeAllFee() private {
        if (_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    /**
     * @dev This function is only used by {_tokenTransfer} to remove fees when an "excluded from fee" address is making a transfer
     */
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }

    /**
     * @dev Updates fee total, used on token transfers
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    /**
     * @dev Total fees ever distributed
     */
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    /**
     * @dev Converts a rSpace token amount to tSpace
     */
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount/currentRate;
    }

    /**
     * @dev Returns reflection value from tAmount
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /**
     * @dev This function handles the fees on every token transfer
     */
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else { // If both not excluded
            _transferStandard(sender, recipient, amount);
        }
        
        if (!takeFee) {
            restoreAllFee();
        }
    }

    // Transfer Cases
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Reflection Helpers
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee;

        return (tTransferAmount, tFee);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;
        for (uint256 i = 0; i < _excludedFromRewardAddresses.length; i++) {
            if (_rOwned[_excludedFromRewardAddresses[i]] > rSupply || _tOwned[_excludedFromRewardAddresses[i]] > tSupply) return (_rTotal, _totalSupply);
            rSupply = rSupply - (_rOwned[_excludedFromRewardAddresses[i]]);
            tSupply = tSupply - (_tOwned[_excludedFromRewardAddresses[i]]);
        }
        if (rSupply < (_rTotal/_totalSupply)) return (_rTotal, _totalSupply);
        return (rSupply, tSupply);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFee)/(10**2);
    }
    
    /**
     * @dev Enables {withdrawMyMigrationTokens} calls
     */
    function enableMigrationTokenWithdrawal() external onlyOwner() {
        require(_isMigrationTokenWithdrawalActive != true, "Migration token withdrawal is already enabled");
        _isMigrationTokenWithdrawalActive = true;
    }

    /**
     * @dev Disables {withdrawMyMigrationTokens} calls
     */
    function disableMigrationTokenWithdrawal() external onlyOwner() {
        require(_isMigrationTokenWithdrawalActive != false, "Migration token withdrawal is already disabled");
        _isMigrationTokenWithdrawalActive = false;
    }

    /**
     * @dev Sets new merkle root to use in {withdrawMyMigrationTokens}
     */
    function setMigrationMerkleRoot(bytes32 newMerkleRoot) external onlyOwner() {
        _migrationMerkleRoot = newMerkleRoot;
    }

    /**
     * @notice This function allows holders of the old contract to withdraw their memes in this contract
     * @dev See {MerkleProof}
     * @param merkleProof Proof containing sibling hashes on the branch from the leaf to the root of the tree
     * @param fundsToWithdraw Amount of tokens to withdraw
     */
    function withdrawMyMigrationTokens(bytes32[] calldata merkleProof, uint128 fundsToWithdraw) external nonReentrant() notPaused() {
        require(_isMigrationTokenWithdrawalActive == true, "Migration token withdrawal is disabled");
        require(!_tokenMigrationClaimed[_msgSender()], "This wallet already claimed it's tokens");
        require(fundsToWithdraw > 0, "Funds to withdraw must be greater than zero");
        require(fundsToWithdraw <= 3000000000000000000000000, "Funds to withdraw must be less than the given amount");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), fundsToWithdraw));

        require(
            MerkleProof.verify(merkleProof, _migrationMerkleRoot, leaf),
            "Invalid merkle proof"
        );

        _tokenMigrationClaimed[_msgSender()] = true;
        _transfer(address(this), _msgSender(), fundsToWithdraw);
    }

    /**
     * @notice Pauses all transfers. This will ONLY be used during an emergency or future migration. Giving a new layer of protection in some cases.
     * @dev Pauses transfers
     */
    function pauseTransfers() external onlyOwner() notPaused() {
        _transfersPaused = true;
        emit TransfersPaused();
    }

    /**
     * @notice Unpauses all transfers. This will ONLY be used during an emergency or future migration. Giving a new layer of protection in some cases.
     * @dev Unpauses transfers
     */
    function unpauseTransfers() external onlyOwner() {
        require(_transfersPaused != false, "Transfers are already unpaused");
        _transfersPaused = false;
        emit TransfersResumed();
    }

    receive() external payable {}
}