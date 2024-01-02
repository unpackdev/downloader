//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SafeMath.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./AccessControlEnumerable.sol";
import "./Math.sol";
import "./IConfig.sol";
import "./IBananChef.sol";
import "./IDexInterfacer.sol";
import "./IUniswapV2Router02.sol";
import "./IStolenPool.sol";
import "./ReentrancyGuard.sol";


/**
 * Banans: Rabbits seem to love these tokens can't stop trying to steal them from our users...
Dapp: https://www.jungle-protocol.com/
Telegram: https://t.me/Jungle_Protocol
Twitter: https://twitter.com/Jungle_Protocol
 */

contract Banan is Context, AccessControlEnumerable, ERC20Burnable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    uint256 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint256 public constant BANANS_DECIMALS = 1e18;
    uint256 public constant BANANS_INTERNAL_DECIMALS = 1e24;

    /**
     * @notice 1,000,000 is total supply
     * LP (80%) = 800_000
     * Team (10%) = 100_000
     * Burn (10%) = 100_000
     */
    uint256 public constant BANANS_LP_SUPPLY =  800_000 * BANANS_DECIMALS;
    uint256 public constant BANANS_TEAM_SUPPLY =  185_000 * BANANS_DECIMALS;
    uint256 public constant BANANS_DEVS_SUPPLY =  15_000 * BANANS_DECIMALS;

    IConfig public config;

    address public outputAddress;

    bool private isInitialized;
    bool public tradingIsOpen;
    bool private inSwap;

    uint16 public sellTaxRate = 2000; //will decrease to 2buy/2sell
    uint16 public buyTaxRate = 2000;
    uint16 public maxScaleFactorDecreasePercentagePerDebase = 1200; //1200/10000 = 12%
    uint64 public banansScalingFactor;
    uint160 public _totalFragmentSupply;
    uint256 public maxWallet = 2 / 100 * 1_000_000 * BANANS_DECIMALS; //2% of total supply

    uint256 public divertTaxToStolenPoolRate = 100; //1% of buy/sell tax goes to stolen pool
    uint256 public taxSwapAmountThreshold = 5_000 * BANANS_DECIMALS; //5k tokens accumulated in-contract before swap to ETH to treasury
    uint256 public maxScaleFactorAdjust = 10; //just if needed to control max scale factor. adding as margin of error.

    address[] public swapPath = new address[](2); 

    mapping(address => uint256) internal _banansBalances;
    mapping(address => mapping(address => uint256)) internal _allowedFragments;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public isDexAddress;
    
    event Rebase(uint256 epoch, uint256 prevBanansScalingFactor, uint256 newBanansScalingFactor);
    event Mint(address to, uint256 amount);
    event Burn(address from, uint256 amount);

    error ForwardFailed();
    error CallerIsNotConfig();
    error TradingIsNotOpen();
    error MaxScalingFactorTooLow();
    error InvalidRecipient();
    error MustHaveMinterRole();
    error MustHaveRebaserRole();
    error NotEnoughBalance();
    error OutputAddressNotSet();
    error CallerIsNotStolenPool();
    error ZeroAddressNotAllowed();

    constructor(
        address _configManagerAddress, address _devAddy
    ) ERC20("Banan", "BANANS") {
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(REBASER_ROLE, _msgSender());
        
        config = IConfig(_configManagerAddress);
        banansScalingFactor = uint64(BANANS_DECIMALS);
        swapPath[0] = address(this); 
        swapPath[1] = IUniswapV2Router02(config.uniswapRouterAddress()).WETH();
        outputAddress = config.treasuryAddress();

        _mint(config.dexInterfacerAddress(), BANANS_LP_SUPPLY);
        _mint(_msgSender(), BANANS_TEAM_SUPPLY);
        _mint(_devAddy, BANANS_DEVS_SUPPLY);
        
    }

    receive() external payable {}

    modifier validRecipient(address to) {
        if(to == address(0x0) || to == address(this)) {
            revert InvalidRecipient();
        }
        _;
    }

    modifier onlyConfig() {
        if (msg.sender != address(config) && msg.sender != owner()) {
            revert CallerIsNotConfig();
        }
        _;
    }

    //=========================================================================
    // ERC20 OVERRIDES
    //=========================================================================

    /**
     * @return The total number of fragments.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalFragmentSupply;
    }

    /**
     * @notice Computes the current max scaling factor
     */

    function maxScalingFactor() public view returns (uint256) {
        // scaling factor can only go up to 2**256-1 = _fragmentToBanans(_totalFragmentSupply) * banansScalingFactor
        // this is used to check if banansScalingFactor will be too high to compute balances when rebasing.
        return Math.mulDiv(type(uint256).max / _fragmentToBanans(_totalFragmentSupply),1, maxScaleFactorAdjust);
    }

    /**
     * @notice Mints new tokens, increasing totalSupply, and a users balance.
     */
    function mint(address to, uint256 amount) external returns (bool) {

        if(!hasRole(MINTER_ROLE, _msgSender())){
            revert MustHaveMinterRole();
        }

        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal override {
        // increase totalSupply
        _totalFragmentSupply += uint160(amount);

        // get underlying value
        uint256 banansAmount = _fragmentToBanans(amount);

        // make sure the mint didnt push maxScalingFactor too low
        if(banansScalingFactor > maxScalingFactor()) {
            revert MaxScalingFactorTooLow();
        }

        // add balance
        _banansBalances[to] = _banansBalances[to].add(banansAmount);

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @notice Burns tokens from msg.sender, decreases totalSupply, and a users balance.
     */

    function burn(uint256 amount) public override {
        _burn(amount);
    }

    function _burn(uint256 amount) internal {
        // decrease totalSupply
        _totalFragmentSupply -= uint160(amount);

        // get underlying value
        uint256 banansAmount = _fragmentToBanans(amount);

        // decrease balance
        _banansBalances[msg.sender] = _banansBalances[msg.sender].sub(banansAmount);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /* - ERC20 functionality - */

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return True on success, false otherwise.
     */

    function transfer(address to, uint256 amount) public override validRecipient(to) returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param amount The amount of tokens to be transferred.
     */

    function transferFrom(address from, address to, uint256 amount) public override validRecipient(to) returns (bool) {        
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(amount);
        _transfer(from, to, amount);
        return true;
    }


    /**
     * @dev transfer tokens from one address to another
     * @param from address to send tokens from
     * @param to address to transfer tokens to
     * @param amount amount of tokens to transfer
     * @notice tax value should be in terms of 1e24 like the balances.
     * @notice event value should be in terms of 1e18 for events.
     */

    function _transfer(address from, address to, uint256 amount) internal override {
        if(from == address(0) || to == address(0)){
            revert ZeroAddressNotAllowed();
        }

        // get value in banans
        uint256 banansValue = _fragmentToBanans(amount);
        uint256 thisTaxValue = 0;
        uint256 maxWalletAmount = _fragmentToBanans(maxWallet);
        
        // no internal swaps call this, only user-called swaps
        if( !inSwap && (isDexAddress[to] || isDexAddress[from]) ){
            require(tradingIsOpen, "Trading is not open yet");
            require(_banansBalances[to] + banansValue <= maxWalletAmount || isDexAddress[to], "Transfer amount exceeds the maxWalletAmount.");
            // [!] should use banansValue instead of value - same 10^24 that adjusts the balances below
            thisTaxValue = computeTax(to, from, banansValue);

            // add tax value to contract, for swap to ETH and send to treasury
            _banansBalances[address(this)] = _banansBalances[address(this)].add(thisTaxValue);            
        
            if(thisTaxValue > 0){
                emit Transfer(from, address(this), _banansToFragment(thisTaxValue));
            }

            // if we're not already within an ETH swap, over the threshold, and user is selling
            // swap the tax value to eth and send to treasury (input is 10^18)            
            if( (balanceOf(address(this)) > taxSwapAmountThreshold) && isDexAddress[to]){
                _swapContractBanansToEth();
            }
        }

        // sub from from, add to to, minus the taxed value
        _banansBalances[from] = _banansBalances[from].sub(banansValue);
        _banansBalances[to] = _banansBalances[to].add(banansValue.sub(thisTaxValue));   

        //show event in terms of 10^18
        emit Transfer(from, to, amount.sub(_banansToFragment(thisTaxValue)));

    }

    /**
     * @dev swaps contract's banans balance for eth as part of tax collection
     * @notice inSwap prevents recursive transferFrom calls
     * @notice also diverts divertTaxToStolenPoolRate of tax to the stolen pool
     */
    
    function _swapContractBanansToEth() private nonReentrant {

        inSwap = true;

        // balanceOf returns 10^18 units
        uint256 _contractBananAmount = balanceOf(address(this));

        // 10^18 * N/10000
        uint256 _divertedAmount = Math.mulDiv(_contractBananAmount, divertTaxToStolenPoolRate, PERCENTAGE_DENOMINATOR);
        
        // 10^18 - 10^18
        uint256 _swapToEthAmount = _contractBananAmount - _divertedAmount;

        // Ensure the Uniswap router has enough allowance (the amount to swap)
        if ( allowance(address(this),config.uniswapRouterAddress()) < _swapToEthAmount) {
            _allowedFragments[address(this)][config.uniswapRouterAddress()] = _swapToEthAmount;
        }

        // divert _divertedAmount to stolen pool (burn, then virtual deposit)
        this.burn(_divertedAmount);
        IStolenPool(config.bananStolenPoolAddress()).virtualDeposit(_divertedAmount);

        // Swap _swapEthAmount to ETH
        IUniswapV2Router02(config.uniswapRouterAddress()).swapExactTokensForETHSupportingFeeOnTransferTokens(
            _swapToEthAmount,
            0,
            swapPath,
            outputAddress,
            block.timestamp
        );

        inSwap = false;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _banansToFragment(_banansBalances[who]);
    }

    /** 
     * @notice Currently returns the internal storage amount
     * @param who The address to query.
     * @return The underlying balance of the specified address.
     */
    function balanceOfUnderlying(address who) public view returns (uint256) {
        return _banansBalances[who];
    }


    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev rebases the token
     * @param epoch the epochtime of the rebase
     * @param indexDelta the delta of the rebase
     * @param positive whether or not the rebase is positive
     * @notice returns the new scale factor based on the supplied indexDelta
     * @notice if debase (most of the time, unless manually altered), new scaling factor < old scaling factor. 
     *         the degree to how much less it is is regulated by _minScalingFactorForThisDebase
     */

    function rebase(uint256 epoch, uint256 indexDelta, bool positive) public nonReentrant returns (uint256) {
        if(!hasRole(REBASER_ROLE, _msgSender())) {
            revert MustHaveRebaserRole();
        }
        // no change
        if (indexDelta == 0) {
            emit Rebase(epoch, banansScalingFactor, banansScalingFactor);
            return _totalFragmentSupply;
        }

        // for events
        uint256 prevBanansScalingFactor = banansScalingFactor;

        if (!positive) {
            banansScalingFactor = uint64(Math.mulDiv(uint256(banansScalingFactor), BANANS_DECIMALS, BANANS_DECIMALS.add(indexDelta)));
            banansScalingFactor = uint64(Math.max(banansScalingFactor, _minScalingFactorForThisDebase(prevBanansScalingFactor)));
        } else {
            uint256 newScalingFactor = uint64(Math.mulDiv(uint256(banansScalingFactor), BANANS_DECIMALS.add(indexDelta), BANANS_DECIMALS));
            banansScalingFactor = uint64(Math.min(uint256(newScalingFactor), maxScalingFactor()));
        }

        emit Rebase(epoch, prevBanansScalingFactor, banansScalingFactor);
        return _totalFragmentSupply;
    }

    function swapContractBanansToEth() public onlyOwner {
        _swapContractBanansToEth();
    }

    //=========================================================================
    // GETTERS
    //=========================================================================

    /**
     * @dev called within _transfer to determine the tax amount. does not apply tax during pool creation
     *  @param _to the address to transfer to
     *  @param _from the address to transfer from
     *  @param _value the amount to transfer (in units of 10^24!)
     */
    function computeTax(address _to, address _from, uint256 _value) public view returns (uint256) {
        if (isDexAddress[_to] && _from != config.dexInterfacerAddress()) {
            return _value.mul(sellTaxRate).div(PERCENTAGE_DENOMINATOR);
        } else if (isDexAddress[_from]) {
            return _value.mul(buyTaxRate).div(PERCENTAGE_DENOMINATOR);
        } else {
            return 0;
        }            
    }

    function banansToFragment(uint256 banans) public view returns (uint256) {
        return _banansToFragment(banans);
    }

    function fragmentToBanans(uint256 fragment) public view returns (uint256) {
        return _fragmentToBanans(fragment);
    }

    // 10^24 --> 10^18
    function _banansToFragment(uint256 banans) internal view returns (uint256) {
        return banans.mul(banansScalingFactor).div(BANANS_INTERNAL_DECIMALS);
    }

    //10^18 --> 10^24
    function _fragmentToBanans(uint256 value) internal view returns (uint256) {
        return value.mul(BANANS_INTERNAL_DECIMALS).div(banansScalingFactor);
    }

    function getTotalSupply() external view returns (uint256) {
        return _totalFragmentSupply;
    }

    function _minScalingFactorForThisDebase(uint256 _previousScalingFactor) internal view returns (uint256) {
        return Math.mulDiv(_previousScalingFactor, PERCENTAGE_DENOMINATOR - maxScaleFactorDecreasePercentagePerDebase, PERCENTAGE_DENOMINATOR);
    }

    //=========================================================================
    // SETTERS
    //=========================================================================

    function setConfigManagerAddress(address _configManager) external onlyOwner {
        config = IConfig(_configManager);
    }

    function setSellTaxRate(uint16 _sellTaxRate) external onlyConfig {
        sellTaxRate = _sellTaxRate;
    }

    function setBuyTaxRate(uint16 _buyTaxRate) external onlyConfig {
        buyTaxRate = _buyTaxRate;
    }

    function setFinalTaxRate() external onlyConfig {
        sellTaxRate = 200;
        buyTaxRate = 200;
    }

    function removeMaxWallet() external onlyConfig {
        maxWallet = 1_000_000 * BANANS_DECIMALS;
    }

    function enableTrading() external onlyConfig {
        tradingIsOpen = true;
    }

    function addDexAddress(address _addr) external onlyConfig {
        isDexAddress[_addr] = true;
    }

    function removeDexAddress(address _addr) external onlyConfig {
        isDexAddress[_addr] = false;
    }

    function setMaxScaleFactorDecreasePercentagePerDebase(uint256 _maxScaleFactorDecreasePercentagePerDebase) external onlyConfig {
        maxScaleFactorDecreasePercentagePerDebase = uint16(_maxScaleFactorDecreasePercentagePerDebase);
    }

    function setTaxSwapAmountThreshold(uint256 _taxSwapAmountThreshold) external onlyConfig {
        taxSwapAmountThreshold = _taxSwapAmountThreshold;
    }

    function setOutputAddress(address _outputAddress) external onlyOwner {
        outputAddress = _outputAddress;
    }

    function setDivertTaxToStolenPoolRate(uint256 _divertTaxToStolenPoolRate) external onlyConfig {
        divertTaxToStolenPoolRate = _divertTaxToStolenPoolRate;
    }

    function setMaxScaleFactorAdjust(uint256 _adjustFactor) external onlyOwner {
        maxScaleFactorAdjust = _adjustFactor;
    }

    //=========================================================================
    // WITHDRAWALS
    //=========================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        if(_to == address(0) || _to == address(this)){
            revert InvalidRecipient();
        }

        bool os = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if (!os) {
            revert ForwardFailed();
        }
    }

    function withdrawEthFromContract(address _to) external onlyOwner {
        if(_to == address(0) || _to == address(this)){
            revert InvalidRecipient();
        }

        (bool os, ) = payable(_to).call{value: address(this).balance}("");
        if (!os) {
            revert ForwardFailed();
        }
    }
}