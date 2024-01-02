// SPDX-License-Identifier: MIT
// File: Context.sol


pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: Ownable.sol


pragma solidity ^0.8.20;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

 
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



// File: IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20USDT {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external;
}

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20NATI {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: TradingContract.sol


pragma solidity ^0.8.20;

// Import the ERC20 interface


interface ITradingContract {
    enum STATUS { DEPOSITING, TRADING, WITHDRAWING }

    function deposit(address, uint256) external returns (uint256);
    function withdraw(address, uint256) external;
    function withdrawAll(address) external;
    function getUserBalance(address) external view returns (uint256);
    function getUserDeposit(address) external view returns (uint256);
    function getUserProfit(address) external view returns (uint256);
    function getContractBalance() external view returns (uint256);
    function getTotalDeposit() external view returns (uint256);
    function getAdminWithdraw() external view returns (uint256);
    function getAdminDeposit() external view returns (uint256);
    function getTradingStatus() external view returns (STATUS);
    function getAdminTaxProfit() external view returns (uint256);
    function getTaxRate() external view returns (uint256);
    function setTaxRate(uint256) external;
    function withdrawForTrading(uint256) external;
    function withdrawTaxProfit(uint256) external;
    function depositTradingResult(uint256) external;
    function updateStatus(STATUS) external;
}

contract TradingContract is Ownable, ITradingContract {
    mapping(address => uint256) private initialBalances;
    mapping(address => uint256) private finalBalances;
    mapping(address => bool) private profitCalculated;
    uint256 private totalDeposit;
    uint256 private adminWithdraw;
    uint256 private adminDeposit;
    uint256 private contractBalance;
    uint256 private adminTaxProfit;
    STATUS private status = STATUS.DEPOSITING;
    uint256 private taxRate = 10; //1000 is 100% and 10 is 1%

    constructor() {}

    function deposit(address account, uint256 amount) external override onlyOwner returns (uint256) {
        require(amount > 0, "Amount must be greater than zero");
        require(status == STATUS.DEPOSITING, "Trading is in another progress and you can't deposit for now.");
       
        // Update the user's deposit balance
        uint256 _amount = amount * (1000 - taxRate) / (1000);
        initialBalances[account] += _amount;
        totalDeposit += _amount;
        contractBalance += amount;
        adminTaxProfit += (amount - _amount);

        return _amount;
    }

    function _withdraw(address account, uint256 amount) internal onlyOwner {
        require(status == STATUS.WITHDRAWING, "Trading is in another progress and you can't withdraw for now.");
        uint256 currentBalance = _updateAndGetBalance(account);
        require(currentBalance >= amount, "You don't have enough balance.");
        require(currentBalance > 0, "You don't have any balance for withdrawal");

        // Update the user's deposit balance
        finalBalances[account] = currentBalance - amount;
        contractBalance -= amount;
    }

    function calcEarning(address account) internal view onlyOwner returns (uint256) {
        if (totalDeposit == 0) {
            return 0;
        }
        
        if (adminDeposit >= adminWithdraw) {
            uint256 diff = adminDeposit - adminWithdraw;
            uint256 newBalance = initialBalances[account] + diff * (initialBalances[account]) / (totalDeposit);
            return newBalance;
        } else {
            uint256 diff = adminWithdraw - adminDeposit;
            uint256 newBalance = initialBalances[account] - diff * (initialBalances[account]) / (totalDeposit);
            return newBalance;
        }
    }

    function _updateAndGetBalance(address account) internal onlyOwner returns (uint256) {
        if (profitCalculated[account]) {
            return finalBalances[account];
        } else {
            uint256 newBalance = calcEarning(account);
            finalBalances[account] = newBalance;
            profitCalculated[account] = true;
            return newBalance;
        }
    }

    function withdraw(address account, uint256 amount) external override onlyOwner {
        _withdraw(account, amount);
    }

    function withdrawAll(address account) external override onlyOwner {
        uint256 currentBalance = _updateAndGetBalance(account);
        _withdraw(account, currentBalance);
    }

    function getUserBalance(address account) external view override onlyOwner returns (uint256) {
        if (profitCalculated[account]) {
            return finalBalances[account];
        } else {
            uint256 profit = calcEarning(account);
            return profit;
        }
    }

    function getUserDeposit(address account) external view override onlyOwner returns (uint256) {
        return initialBalances[account];
    }

    function getUserProfit(address account) external view override onlyOwner returns (uint256) {
        uint256 profit = calcEarning(account);
        return profit;
    }

    function getContractBalance() external view onlyOwner returns (uint256) {
        return contractBalance;
    }

    function getTotalDeposit() external view override onlyOwner returns (uint256) {
        return totalDeposit;
    }

    function getAdminWithdraw() external view override onlyOwner returns (uint256) {
        return adminWithdraw;
    }

    function getAdminDeposit() external view override onlyOwner returns (uint256) {
        return adminDeposit;
    }

    function getTradingStatus() external view onlyOwner returns (STATUS) {
        return status;
    }

    function getAdminTaxProfit() external view override onlyOwner returns (uint256) {
        return adminTaxProfit;
    }

    function getTaxRate() external view override onlyOwner returns (uint256) {
        return taxRate;
    }

    function setTaxRate(uint256 _taxRate) external override onlyOwner {
        require(_taxRate <= 50, "The maximun tax rate is 5%");
        taxRate = _taxRate;
    }

    function withdrawForTrading(uint256 amount) external override onlyOwner {
        require(status == STATUS.TRADING, "You should update the trading status first.");
        require(amount > 0 && amount <= contractBalance - adminTaxProfit, "Amount must be greater than zero and smaller than balance");

        // Start trading
        adminWithdraw += amount;
        contractBalance -= amount;
    }

    function withdrawTaxProfit(uint256 amount) external override onlyOwner {
        require(amount > 0 && amount <= adminTaxProfit, "Amount must be greater than zero and smaller than total tax profit");
        adminTaxProfit -= amount;
        contractBalance -= amount;
    }

    function depositTradingResult(uint256 amount) external override onlyOwner {
        require(status == STATUS.TRADING, "You should update the trading status first.");
        require(amount > 0, "Amount must be greater than zero");
        
        adminDeposit += amount;
        contractBalance += amount;
    }

    function updateStatus(STATUS _status) external override onlyOwner {
        status = _status;
    }
}


contract TradingRouter is Ownable {
    event TradingCreated(uint256 _tradingId);
    event Deposit(uint256 _tradingId, address _sender, uint256 _amount);
    event Withdraw(uint256 _tradingId, address _sender, uint256 _amount);
    event TaxRateSet(uint256 _tradingId, uint256 _newRate);
    event WithdrawForTrading(uint256 _tradingId, uint256 _amount);
    event WithdrawTaxProfit(uint256 _tradingId, uint256 _amount);
    event DepositTradingResult(uint256 _tradingId, uint256 _amount);
    event StatusUpdated(uint256 _tradingId, ITradingContract.STATUS _newStatus);

    mapping(uint256 => address) private tradings;
    uint256 private tradingId;
    uint256 private natiThreshold = 1 ether;
    
    IERC20USDT private usdtToken = IERC20USDT(0xacb00767576f3E4DD61086a3A927C085AAcC243A);
    IERC20NATI private natiToken = IERC20NATI(0x4a7Bf2BD2DE2f52be0908ed147f0123f5035F24b);

    constructor() {}

    modifier onlyValidTrading(uint256 _id) {
        require(_id >= 0 && _id < tradingId, "Invalid trading ID.");
        _;
    }

    modifier onlyNatiHolder(address _account) {
        uint256 natiBalance = natiToken.balanceOf(_account);
        require(natiBalance >= natiThreshold, "Insufficient Nati Balance.");
        _;
    }

    function checkNati() external view returns (bool) {
        uint256 natiBalance = natiToken.balanceOf(msg.sender);
        if (natiBalance >= natiThreshold) return true;
        else return false;
    }

    function getNatiThreshold() external view returns (uint256) {
        return natiThreshold;
    }

    function setNatiThreshold(uint256 _newThreshold) external onlyOwner {
        natiThreshold = _newThreshold;
    }

    function createTrading() external onlyOwner {
        TradingContract _trading = new TradingContract();
        tradings[tradingId] = address(_trading);
        tradingId ++;

        emit TradingCreated(tradingId - 1);
    }

    function deposit(uint256 _tradingId, uint256 _amount) external onlyValidTrading(_tradingId) onlyNatiHolder(msg.sender) {
        uint256 depositAmount = ITradingContract(tradings[_tradingId]).deposit(msg.sender, _amount);
        usdtToken.transferFrom(msg.sender, address(this), _amount);
        
        emit Deposit(_tradingId, msg.sender, depositAmount);
    }

    function withdraw(uint256 _tradingId, uint256 _amount) external onlyValidTrading(_tradingId) onlyNatiHolder(msg.sender) {
        ITradingContract(tradings[_tradingId]).withdraw(msg.sender, _amount);
        usdtToken.transfer(msg.sender, _amount);

        emit Withdraw(_tradingId, msg.sender, _amount);
    }

    function withdrawAll(uint256 _tradingId) external onlyValidTrading(_tradingId) onlyNatiHolder(msg.sender) {
        uint256 userBalance = ITradingContract(tradings[_tradingId]).getUserBalance(msg.sender);
        ITradingContract(tradings[_tradingId]).withdraw(msg.sender, userBalance);
        usdtToken.transfer(msg.sender, userBalance);

        emit Withdraw(_tradingId, msg.sender, userBalance);
    }

    function getUserBalance(uint256 _tradingId, address _account) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 balance = ITradingContract(tradings[_tradingId]).getUserBalance(_account);
        return balance;
    }

    function getUserBalanceAll(address _account) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getUserBalance(_account);
        }

        return res;
    }

    function getUserDeposit(uint256 _tradingId, address _account) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 balance = ITradingContract(tradings[_tradingId]).getUserDeposit(_account);
        return balance;
    }

    function getUserDepositAll(address _account) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getUserDeposit(_account);
        }

        return res;
    }

    function getUserProfit(uint256 _tradingId, address _account) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 profit = ITradingContract(tradings[_tradingId]).getUserProfit(_account);
        return profit;
    }

    function getUserProfitAll(address _account) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getUserProfit(_account);
        }

        return res;
    }

    function getTradingStatus(uint256 _tradingId) external view onlyValidTrading(_tradingId) returns (ITradingContract.STATUS) {
        return ITradingContract(tradings[_tradingId]).getTradingStatus();
    }

    function getTradingStatusAll() external view returns (ITradingContract.STATUS[] memory) {
        ITradingContract.STATUS [] memory res = new ITradingContract.STATUS[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getTradingStatus();
        }

        return res;
    }

    function getContractBalance(uint256 _tradingId) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 _balance = ITradingContract(tradings[_tradingId]).getContractBalance();
        return _balance;
    }

    function getContractBalanceAll() external view onlyOwner returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getContractBalance();
        }

        return res;
    }

    function getAdminTaxProfit(uint256 _tradingId) external view onlyOwner onlyValidTrading(_tradingId) returns (uint256) {
        uint256 _profit = ITradingContract(tradings[_tradingId]).getAdminTaxProfit();
        return _profit;
    }

    function getAdminTaxProfitAll() external view onlyOwner returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getAdminTaxProfit();
        }

        return res;
    }

    function getTotalDeposit(uint256 _tradingId) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 _deposit = ITradingContract(tradings[_tradingId]).getTotalDeposit();
        return _deposit;
    }

    function getTotalDepositAll() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getTotalDeposit();
        }

        return res;
    }

    function getTaxRate(uint256 _tradingId) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 _taxRate = ITradingContract(tradings[_tradingId]).getTaxRate();
        return _taxRate;
    }

    function getTaxRateAll() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getTaxRate();
        }

        return res;
    }

    function setTaxRate(uint256 _tradingId, uint256 _taxRate) external onlyOwner onlyValidTrading(_tradingId) {
        ITradingContract(tradings[_tradingId]).setTaxRate(_taxRate);

        emit TaxRateSet(_tradingId, _taxRate);
    }

    function getAdminWithdraw(uint256 _tradingId) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 _withdraw = ITradingContract(tradings[_tradingId]).getAdminWithdraw();
        return _withdraw;
    }

    function getAdminWithdrawAll() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getAdminWithdraw();
        }

        return res;
    }

    function getAdminDeposit(uint256 _tradingId) external view onlyValidTrading(_tradingId) returns (uint256) {
        uint256 _deposit = ITradingContract(tradings[_tradingId]).getAdminDeposit();
        return _deposit;
    }

    function getAdminDepositAll() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tradingId);

        for (uint256 i = 0; i < tradingId; i++) {
            res[i] = ITradingContract(tradings[i]).getAdminDeposit();
        }

        return res;
    }

    function withdrawForTrading(uint256 _tradingId, uint256 _amount) public onlyOwner onlyValidTrading(_tradingId) {
        ITradingContract(tradings[_tradingId]).withdrawForTrading(_amount);
        usdtToken.transfer(msg.sender, _amount);

        emit WithdrawForTrading(_tradingId, _amount);
    }

    function withdrawAllForTrading(uint256 _tradingId) external onlyOwner onlyValidTrading(_tradingId) {
        uint256 contractBalance = ITradingContract(tradings[_tradingId]).getContractBalance();
        uint256 adminTaxProfit = ITradingContract(tradings[_tradingId]).getAdminTaxProfit();
        withdrawForTrading(_tradingId, contractBalance - adminTaxProfit);

        emit WithdrawForTrading(_tradingId, contractBalance - adminTaxProfit);
    }

    function withdrawTaxProfit(uint256 _tradingId, uint256 _amount) external onlyOwner onlyValidTrading(_tradingId) {
        ITradingContract(tradings[_tradingId]).withdrawTaxProfit(_amount);
        usdtToken.transfer(msg.sender, _amount);

        emit WithdrawTaxProfit(_tradingId, _amount);
    }

    function withdrawTaxProfitAll(uint256 _tradingId) external onlyOwner onlyValidTrading(_tradingId) {
        uint256 adminTaxProfit = ITradingContract(tradings[_tradingId]).getAdminTaxProfit();
        ITradingContract(tradings[_tradingId]).withdrawTaxProfit(adminTaxProfit);
        usdtToken.transfer(msg.sender, adminTaxProfit);

        emit WithdrawTaxProfit(_tradingId, adminTaxProfit);
    }

    function depositTradingResult(uint256 _tradingId, uint256 _amount) external onlyOwner onlyValidTrading(_tradingId) {
        usdtToken.transferFrom(msg.sender, address(this), _amount);
        ITradingContract(tradings[_tradingId]).depositTradingResult(_amount);

        emit DepositTradingResult(_tradingId, _amount);
    }

    function updateStatus(uint256 _tradingId, ITradingContract.STATUS _status) external onlyOwner onlyValidTrading(_tradingId) {
        ITradingContract(tradings[_tradingId]).updateStatus(_status);

        emit StatusUpdated(_tradingId, _status);
    }

    function getCurrentTradingId() external view returns (uint256) {
        return tradingId;
    }

    function getTradingContract(uint256 _tradingId) external view onlyOwner onlyValidTrading(_tradingId) returns (address) {
        return tradings[_tradingId];
    }
}