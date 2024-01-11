// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./IAssetManager.sol";
import "./IERC20Metadata.sol";
import "./IWETH.sol";
import "./SafeMathExtends.sol";
import "./UniV3SwapExtends.sol";

import "./BasicVault.sol";
import "./SmartPoolStorage.sol";
import "./RouteStorage.sol";

pragma abicoder v2;
/// @title Vault Contract - The implmentation of vault contract
/// @notice This contract extends Basic Vault and defines the join and redeem activities
contract Vault is BasicVault, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMathExtends for uint256;
    using Address for address;
    using Path for bytes;
    using UniV3SwapExtends for mapping(address => mapping(address => bytes));

    event PoolJoined(address indexed investor, uint256 amount);
    event PoolExited(address indexed investor, uint256 amount);

    /// @notice deny contract
    modifier notAllowContract() {
        require(!address(msg.sender).isContract(), "is contract");
        _;
    }
    /// @notice not in lup
    modifier notInLup() {
        bool inLup = block.timestamp <= lup();
        require(!inLup, "in lup");
        _;
    }

    /// @notice allow input token check
    /// @param token input token address
    modifier onlyWhiteList(address[] memory whiteList, address token) {
        bool isWhiteList = false;
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (token == whiteList[i]) {
                isWhiteList = true;
                break;
            }
        }
        require(isWhiteList, "!whiteList");
        _;
    }

    constructor(
        string memory name,
        string memory symbol
    ) BasicVault(name, symbol){

    }

    receive() external payable {
        require(msg.sender == SmartPoolStorage.load().weth, 'Not WETH');
    }

    /// @notice lock-up period
    function lup() public view returns (uint256){
        return SmartPoolStorage.load().lup;
    }

    /// @notice lock-up period
    /// @param _lup period value
    function setLup(uint256 _lup) external onlyAdminOrGovernance {
        SmartPoolStorage.load().lup = _lup;
    }

    /// @notice Set asset swap route
    /// @dev Only the governance and admin identity is allowed to set the asset swap path, and the firstToken and lastToken contained in the path will be used as the underlying asset token address by default
    /// @param path Swap path byte code
    function settingSwapRoute(bytes memory path) external onlyAdminOrGovernance {
        require(path.valid(), 'path is not valid');
        address fromToken = path.getFirstAddress();
        address toToken = path.getLastAddress();
        RouteStorage.load().swapRoute[fromToken][toToken] = path;
    }

    /// @notice get swapRoute
    function swapRoute(address fromToken, address toToken) public view returns (bytes memory)  {
        return RouteStorage.load().swapRoute[fromToken][toToken];
    }

    /// @notice setting inputs list
    /// @param inputs inputs token address
    function setAllowInput(address[] memory inputs) external onlyGovernance {
        RouteStorage.load().allowInputs = inputs;
    }

    /// @notice get white list
    function getAllowInputs() public view returns (address[] memory)  {
        return RouteStorage.load().allowInputs;
    }

    /// @notice setting output list
    /// @param outputs outputs token address
    function setAllowOutput(address[] memory outputs) external onlyGovernance {
        RouteStorage.load().allowOutputs = outputs;
    }

    /// @notice get white list
    function getAllowOutputs() public view returns (address[] memory)  {
        return RouteStorage.load().allowOutputs;
    }

    function _updateBasicInfo(
        string memory name,
        string memory symbol,
        address token,
        address am,
        address weth
    ) internal {
        _name = name;
        _symbol = symbol;
        _decimals = IERC20Metadata(token).decimals();
        SmartPoolStorage.load().token = token;
        SmartPoolStorage.load().am = am;
        SmartPoolStorage.load().weth = weth;
        SmartPoolStorage.load().suspend = false;
        SmartPoolStorage.load().allowJoin = true;
        SmartPoolStorage.load().allowExit = true;
    }

    function init(
        string memory name,
        string memory symbol,
        address token,
        address am,
        address weth
    ) public {
        require(getGovernance() == address(0), 'Already init');
        super._init();
        _updateBasicInfo(name, symbol, token, am, weth);
    }

    /// @notice Bind join and redeem address with asset management contract
    /// @dev Make the accuracy of the vault consistent with the accuracy of the bound token; it can only be bound once and cannot be modified
    /// @param token Join and redeem vault token address
    /// @param am Asset managemeent address
    function bind(
        string memory name,
        string memory symbol,
        address token,
        address am,
        address weth) external onlyGovernance {
        _updateBasicInfo(name, symbol, token, am, weth);
    }

    /// @notice Subscript vault by default Token
    /// @dev When subscribing to the vault, fee will be collected, and contract access is not allowed
    /// @param amount Subscription amount
    function joinPool(uint256 amount) external isAllowJoin notAllowContract {
        _joinPool(msg.sender, address(ioToken()), amount);
    }

    /// @notice Subscript vault by token
    /// @dev When subscribing to the vault, fee will be collected, and contract access is not allowed
    /// @param token Subscription token
    /// @param amount Subscription amount
    function joinPool2(address token, uint256 amount) external isAllowJoin notAllowContract {
        _joinPool(msg.sender, token, amount);
    }


    /// @notice Subscript vault
    /// @param _inputToken Subscription token
    /// @param _inputAmount Subscription amount
    function _joinPool(address payer, address _inputToken, uint256 _inputAmount)
    internal onlyWhiteList(
        RouteStorage.load().allowInputs,
        _inputToken
    ) {
        IERC20 inputToken = IERC20(_inputToken);
        require(_inputAmount <= inputToken.balanceOf(payer) && _inputAmount > 0, "Insufficient balance");
        uint256 value = estimateTokenValue(_inputToken, address(ioToken()), _inputAmount);
        uint256 vaultAmount = convertToShare(value);
        //take management fee
        takeOutstandingManagementFee();
        //take join fee
        uint256 fee = _takeJoinFee(msg.sender, vaultAmount);
        uint256 realVaultAmount = vaultAmount.sub(fee);
        _mint(msg.sender, realVaultAmount);
        inputToken.safeTransferFrom(payer, AM(), _inputAmount);
        emit PoolJoined(msg.sender, realVaultAmount);
    }

    /// @notice estimate value
    /// @param inputToken input token
    /// @param outputToken output token
    /// @param inputAmount input amount
    function estimateTokenValue(address inputToken, address outputToken, uint256 inputAmount) public view returns (uint256){
        uint256 value = inputAmount;
        if (inputToken != outputToken) {
            value = RouteStorage.load().swapRoute.estimateAmountOut(inputToken, outputToken, inputAmount);
        }
        return value;
    }

    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPool(uint256 amount) external isAllowExit notInLup notAllowContract {
        require(balanceOf(msg.sender) >= amount && amount > 0, "Insufficient balance");
        _exitPool(msg.sender, address(ioToken()), amount);
    }

    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param outputToken Redeem token address
    /// @param amount Redeem amount
    function exitPool2(address outputToken, uint256 amount) external isAllowExit notInLup notAllowContract {
        require(balanceOf(msg.sender) >= amount && amount > 0, "Insufficient balance");
        _exitPool(msg.sender, outputToken, amount);
    }


    /// @notice Redeem vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param rec rec address
    /// @param outputToken output token
    /// @param amount Redeem amount
    function _exitPool(address rec, address outputToken, uint256 amount)
    internal nonReentrant onlyWhiteList(
        RouteStorage.load().allowOutputs,
        outputToken
    ) {
        address investor = msg.sender;
        //take exit fee
        uint256 exitFee = _takeExitFee(investor, amount);
        uint256 exitAmount = amount.sub(exitFee);
        //take performance fee
        takeOutstandingPerformanceFee(investor);
        //replace exitAmount
        uint256 balance = balanceOf(investor);
        exitAmount = balance < exitAmount ? balance : exitAmount;
        uint256 scale = exitAmount.bdiv(totalSupply());
        uint256 cashAmount = convertToCash(exitAmount);
        uint256 withdrawAmount = estimateTokenValue(address(ioToken()), outputToken, cashAmount);
        //take management fee
        takeOutstandingManagementFee();
        // withdraw cash
        IAssetManager(AM()).withdraw(outputToken, rec, withdrawAmount, scale);
        _burn(investor, exitAmount);
        emit PoolExited(investor, exitAmount);
    }

    /// @notice Redeem the underlying assets of the vault
    /// @dev When the vault is redeemed, fees will be collected, and contract access is not allowed
    /// @param amount Redeem amount
    function exitPoolOfUnderlying(uint256 amount) external isAllowExit notInLup nonReentrant notAllowContract {
        address investor = msg.sender;
        require(balanceOf(investor) >= amount && amount > 0, "Insufficient balance");
        //take exit fee
        uint256 exitFee = _takeExitFee(investor, amount);
        uint256 exitAmount = amount.sub(exitFee);
        //take performance fee
        takeOutstandingPerformanceFee(investor);
        //replace exitAmount
        uint256 balance = balanceOf(investor);
        exitAmount = balance < exitAmount ? balance : exitAmount;
        uint256 scale = exitAmount.bdiv(totalSupply());
        //take management fee
        takeOutstandingManagementFee();
        //harvest underlying
        IAssetManager(AM()).withdrawOfUnderlying(investor, scale);
        _burn(investor, exitAmount);
        emit PoolExited(investor, exitAmount);
    }

    /// @notice Vault token address for joining and redeeming
    /// @dev This is address is created when the vault is first created.
    /// @return Vault token address
    function ioToken() public view returns (IERC20){
        return IERC20(SmartPoolStorage.load().token);
    }

    /// @notice Vault mangement contract address
    /// @dev The vault management contract address is bind to the vault when the vault is created
    /// @return Vault management contract address
    function AM() public view returns (address){
        return SmartPoolStorage.load().am;
    }


    /// @notice Convert vault amount to cash amount
    /// @dev This converts the user vault amount to cash amount when a user redeems the vault
    /// @param vaultAmount Redeem vault amount
    /// @return Cash amount
    function convertToCash(uint256 vaultAmount) public virtual override view returns (uint256){
        uint256 cash = 0;
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            cash = 0;
        } else {
            cash = _assets.mul(vaultAmount).div(totalSupply);
        }
        return cash;
    }

    /// @notice Convert cash amount to share amount
    /// @dev This converts cash amount to share amount when a user buys the vault
    /// @param cashAmount Join cash amount
    /// @return share amount
    function convertToShare(uint256 cashAmount) public virtual override view returns (uint256){
        uint256 totalSupply = totalSupply();
        uint256 _assets = assets();
        if (totalSupply == 0 || _assets == 0) {
            return cashAmount;
        } else {
            return cashAmount.mul(totalSupply).div(_assets);
        }
    }

    /// @notice Vault total asset
    /// @dev This calculates vault net worth or AUM
    /// @return Vault total asset
    function assets() public view returns (uint256){
        return IAssetManager(AM()).assets();
    }
}
