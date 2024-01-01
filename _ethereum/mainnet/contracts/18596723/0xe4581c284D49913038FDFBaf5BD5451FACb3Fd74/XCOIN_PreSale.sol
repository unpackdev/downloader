// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external ;
}

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract XCOIN_PreSale is Ownable, Pausable {
    uint256 public salePriceMultipler = 1 ;
    uint256 public salePriceDivider = 1000;
    uint256 public launchPriceMultipler = 5; 
    uint256 public launchPriceDivider = 1000;
    uint256 public totalTokensForPresale = 550_000_000 * 10**18;
    uint256 public inSale = 550_000_000 * 10**18;
    uint256 public totalTokensSoldInPresale = 0;
    uint256 public bonus = 10;
    uint256 public minimumBuyAmount = 0;
    bool public isPresalePaused;
    bool public isPresaleCompleted;
    address public saleToken;
    address public dataOracle = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public dAddress = 0xb5D11E5AD4A7f094156F4fbe3891D2F30cD54d76;

    IERC20 tokenInterface = IERC20(usdtToken);
    uint256 public claimStart;

    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;

    event TokensBought(address indexed user, uint256 indexed tokensBought, address indexed purchaseToken, uint256 amountPaid, uint256 timestamp);

    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);

    modifier checkSaleState(uint256 amount) {
        require(!isPresalePaused, "Presale Completed");
        require(!isPresaleCompleted, "Presale Completed");
        amount += (amount * bonus) / 100;
        require(amount >= minimumBuyAmount, "Too small amount");
        require(amount > 0 && amount <= inSale, "Invalid sale amount");
        _;
    }

    modifier checkSaleStateForUsdt(uint256 amount) {
        require(!isPresalePaused, "Presale Completed");
        require(!isPresaleCompleted, "Presale Completed");
        uint256 tokenAmount = (amount * 10 **12 * salePriceDivider) / salePriceMultipler;
        tokenAmount += (tokenAmount * bonus) / 100;
        require(tokenAmount >= minimumBuyAmount, "Too small amount");
        require(tokenAmount > 0 && tokenAmount <= inSale, "Invalid sale amount");
        _;
    }


    function startClaim( 
        uint256 tokensAmount,  
        address _saleToken
    ) external onlyOwner {
        require(_saleToken != address(0), "Zero token address");
        claimStart = block.timestamp;
        saleToken = _saleToken;
        IERC20(_saleToken).transferFrom(_msgSender(), address(this), tokensAmount);
    }

    function claim() external whenNotPaused {   
        require(isPresaleCompleted, "Presale not Completed yet");
        require(saleToken != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];  
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        IERC20(saleToken).transfer(_msgSender(), amount);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    function setTotalTokensForPresale(uint256 _value) external onlyOwner {
        int256 diffTokensale = int256(_value) - int256(totalTokensForPresale);
        inSale = uint256(int256(inSale) + diffTokensale);
        totalTokensForPresale = _value;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    function getTokenAmountForUSDT(uint256 amount) external view returns (uint256) {
        uint256 usdPrice = calculatePrice(amount);
        return usdPrice;
    }

    function checkSoldUSDvalue() public view returns (uint256) {
        uint256 totalValue = (totalTokensSoldInPresale  * salePriceMultipler) / salePriceDivider ;
        return totalValue;
    }

    function getTokenAmountForETH(uint256 amount) external view returns (uint256) {
        uint256 usdPrice = (amount * getETHLatestPrice()) / (10**18);
        uint256 tokenAmount = (usdPrice * salePriceDivider )/ salePriceMultipler ;
        return tokenAmount;
    }

    function getETHAmount(uint256 amount) external view returns (uint256) {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ETHAmount = ((usdPrice * 10**18) / getETHLatestPrice()) ;
        return ETHAmount;
    }

    function getETHLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = Aggregator(dataOracle).latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    function calculatePrice(uint256 _amount) internal view returns (uint256) {
        uint256 totalValue =  (_amount * salePriceMultipler) / salePriceDivider;
        return totalValue;
    }

    function buyWithETH(uint256 amount) external payable checkSaleState(amount) whenNotPaused {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ETHAmount = (usdPrice * 10**18) / getETHLatestPrice();
        require(msg.value >= ETHAmount, "Less payment");
        uint256 excess = msg.value - ETHAmount;
        amount = amount + (amount * bonus) / 100;
        userDeposits[msg.sender] = userDeposits[msg.sender] + amount;
        totalTokensSoldInPresale = totalTokensSoldInPresale + amount;
        inSale = inSale - amount;
        if(inSale == 0){
            isPresaleCompleted = true;
        }
        sendValue(payable(dAddress), ETHAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        emit TokensBought(_msgSender(), amount, address(0), ETHAmount, block.timestamp);
    }

    function buyWithUSD(uint256 amount) external checkSaleStateForUsdt(amount) whenNotPaused {
        uint256 tokenAmount = (amount * 10 **12 * salePriceDivider) / salePriceMultipler;
        tokenInterface.transferFrom(_msgSender(), dAddress, amount);
        tokenAmount += (tokenAmount * bonus) / 100;
        userDeposits[_msgSender()] += tokenAmount;
        totalTokensSoldInPresale += tokenAmount;
        inSale -= tokenAmount;
        if(inSale == 0){
            isPresaleCompleted = true;
        }
        emit TokensBought(_msgSender(), tokenAmount, address(tokenInterface), amount, block.timestamp);
    }

    function setSalePrice(uint256 _salePriceMultipler, uint256 _salePriceDivider, uint256 _launchPriceMultipler, uint256 _launchPriceDivider) external onlyOwner {
        salePriceMultipler = _salePriceMultipler;
        salePriceDivider = _salePriceDivider;
        launchPriceMultipler = _launchPriceMultipler;
        launchPriceDivider =_launchPriceDivider;
    }

    function pause() external onlyOwner {
        _pause();
        isPresalePaused = true;
    }

    function unpause() external onlyOwner {
        _unpause();
        isPresalePaused = false;
    }

    function setDataOracle(address _dataOracle) external onlyOwner {
        dataOracle = _dataOracle;
    }

    function updateSaleStatus() external onlyOwner {
        isPresaleCompleted = !isPresaleCompleted;
    }

    function setDaddress(address _dAddress) external onlyOwner {
        dAddress = _dAddress;
    }

    function setUSDTAddress(address _usdtAddress) external onlyOwner {
        usdtToken = _usdtAddress;
    }

    function changeMinimumBuyAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0 && _amount != minimumBuyAmount, "Invalid amount");
        minimumBuyAmount = _amount;
    }

    function changeBonusPercentage(uint256 _bonus) external onlyOwner {
        bonus = _bonus;
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(dAddress, amount);
    }

    function withdrawETHs() external onlyOwner {
        (bool success, ) = payable(dAddress).call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}