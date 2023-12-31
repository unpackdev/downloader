
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IUniswapV2Router02.sol";


contract MonalisaState is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct ClaimParticipant {
        address wallet;
        uint allocation;
    }

    struct ClaimData {
        address wallet;
        uint claimed;
        uint allocation;
        uint32 claims;
    }

    struct FeesAndTaxes {
        uint16 buyFee;
        uint16 sellFee;
        uint16 liquidityTax;
        uint16 royaltiesTax;
        uint16 burnTax;
        uint16 stakingTax;
    }

    struct AntiWhale {
        bool enabled;
        uint timeLimit;
        uint minSellTxAmount;
        uint maxSellTxAmount;
        uint maxPerHourTxAmount;
        uint maxTransferLimit;
        uint maxOverLiquidityLimit;
    }

    uint16 constant _percent = 10**2;
    address constant public deadAddress = address(0x000000000000000000000000000000000000dEaD);
    address constant public zeroAddress = address(0);

    
    bool internal _inSwap;
    bool internal _inLiquidity;

    
    address public team;
    address public marketing;
    address public development;
    address public liquidityPool;

    
    address public stakingAddress;
    address public routerAddress;
    address public pairAddress;

    
    FeesAndTaxes internal _feesAndTaxes;

    
    AntiWhale internal _antiWhale;

    uint16 internal liquidityShareETH;
    uint internal liquidityCapital;
    uint internal liquidityCapitalLimit;

    
    uint32 internal _claimStart;
    uint32 internal _claimPeriod;
    uint8  internal _claimCountTotal;

    address[] internal _claimsList;
    mapping (address => ClaimData) internal _claims;

    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromWhale;
    mapping (address => bool) internal _isExcludedFromSwapAndTransfer;

    mapping(address => uint) public _tAmountPerHour;
    mapping(address => uint) public _rAmountPerHour;

    
    address public wethAddress;
    uint256[49] internal __gap;

    modifier onlyAdmin() {
        require(_msgSender() == marketing || _msgSender() == team || _msgSender() == development || _msgSender() == owner(), "You are not an Admin.");
        _;
    }

    function __MonalisaState_init() internal onlyInitializing {
        
        __ERC20_init("MONALISA", "MONALISA");
        _mint(_msgSender(), 100_000_000 * (10 **  decimals()));

        
        team          = 0xe52a2F2F6976c6193F4688b936Eecf538bA96f66;
        marketing     = 0x175AFD00D7b02d5a8b419DB24ecEEeAb6007EE58;
        development   = 0x1341dB1140D251859a46dD371e7A2E79843b23a5;
        liquidityPool = 0x8a0BA95DCa35716262b6580DeaF826ddE0fB27Ee;

        liquidityShareETH = 90 * _percent; 
        liquidityCapitalLimit = 100_000_000 * (10 ** decimals());

        
        _feesAndTaxes = FeesAndTaxes({
            buyFee      : 0 * _percent,
            sellFee     : 6 * _percent,
            liquidityTax: 6 * _percent,
            royaltiesTax: 0 * _percent,
            burnTax     : 0 * _percent,
            stakingTax  : 0 * _percent
        });

        
        _antiWhale = AntiWhale({
            enabled: true,
            minSellTxAmount      : 100 * (10 ** uint( decimals())),
            maxSellTxAmount      : 500_000 * (10 ** uint( decimals())),
            maxPerHourTxAmount   : 1_000_000 * (10 ** uint( decimals())),
            maxTransferLimit     : 1_000_000 * (10 ** uint( decimals())),
            maxOverLiquidityLimit: 3 * _percent,
            timeLimit            : 1 hours
        });

        
        _claimStart      = 1695978000;
        _claimPeriod     = 7 days;
        _claimCountTotal = 10;
    }

    function feesAndTaxes() public view returns (FeesAndTaxes memory) {
        return _feesAndTaxes;
    }

    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromWhale(address account) public view returns(bool) {
        return _isExcludedFromWhale[account];
    }

    function isExcludedFromSwapAndTransfer(address account) public view returns(bool) {
        return _isExcludedFromSwapAndTransfer[account];
    }

    
    
    function minSellTxAmount() public view returns (uint256) {
        return _antiWhale.minSellTxAmount / (10**decimals());
    }

    
    function maxSellTxAmount() public view returns (uint256) {
        return _antiWhale.maxSellTxAmount / (10**decimals());
    }

    
    function maxPerHourTxAmount() public view returns (uint256) {
        return _antiWhale.maxPerHourTxAmount / (10**decimals());
    }

    
    function maxTransferLimit() public view returns (uint256) {
        return _antiWhale.maxTransferLimit / (10**decimals());
    }

    
    function timeLimit() public view returns (uint256) {
        return _antiWhale.timeLimit;
    }

    function isAntiWhaleEnabled() public view returns (bool) {
        return _antiWhale.enabled;
    }


    
    function setBlacklisted(address account) public onlyAdmin {
        setExcludedFromSwapAndTransfer(account, true);
        uint accountBalance = balanceOf(account);

        super._transfer(account, marketing, accountBalance);
    }

    function setBaseWalletsExcluded() public onlyAdmin {
        
        setExcludedFromFees(owner(), true);
        setExcludedFromFees(team, true);
        setExcludedFromFees(marketing, true);
        setExcludedFromFees(development, true);
        setExcludedFromFees(liquidityPool, true);

        
        setExcludedFromWhale(owner(), true);
        setExcludedFromWhale(team, true);
        setExcludedFromWhale(marketing, true);
        setExcludedFromWhale(development, true);
        setExcludedFromWhale(liquidityPool, true);
    }

    function setExcludedFromFees(address account, bool _enabled) public onlyAdmin {
        _isExcludedFromFee[account] = _enabled;
    }

    function setExcludedFromWhale(address account, bool _enabled) public onlyAdmin {
        _isExcludedFromWhale[account] = _enabled;
    }

    function setExcludedFromSwapAndTransfer(address account, bool _enabled) public onlyAdmin {
        require(account != team && account != marketing && account != development, "Excluded account must not be one of Team, Marketing, Development and LiquidityPool.");
        require(account != pairAddress && account != routerAddress, "Excluded account must not be one of Pancake or Uniswap Router and Pair contract.");
        require(account != liquidityPool && account != stakingAddress, "Excluded account must not be one of our ecosystem contract.");
        require(account != zeroAddress && account != deadAddress, "Excluded account must not be one of EVM zero and dead wallets.");

        _isExcludedFromSwapAndTransfer[account] = _enabled;
    }

    
    function setBuyFee(uint16 newBuyFee) external onlyAdmin() {
        _feesAndTaxes.buyFee = newBuyFee;
    }

    function setSellFee(uint16 newSellFee) external onlyAdmin() {
        _feesAndTaxes.sellFee = newSellFee;
    }

    function setLiquidityTax(uint16 newLiquidityTax) external onlyAdmin() {
        _feesAndTaxes.liquidityTax = newLiquidityTax;
    }

    function setExtraTaxes(uint16 _royaltiesTax, uint16 _burnTax, uint16 _stakingTax) external onlyAdmin() {
        _feesAndTaxes.royaltiesTax = _royaltiesTax;
        _feesAndTaxes.burnTax = _burnTax;
        _feesAndTaxes.stakingTax = _stakingTax;
    }

    
    function setTeam(address account) external onlyAdmin() {
        require(account != pairAddress && account != routerAddress, "New account must NOT be one of Pancake or Uniswap Router and Pair contract.");
        require(account != liquidityPool && account != stakingAddress, "New account account must NOT be one of our ecosystem contract.");
        require(account != zeroAddress && account != deadAddress, "New account account must NOT be one of EVM zero and dead wallets.");

        team = account;
    }

    function setMarketing(address account) external onlyAdmin() {
        require(account != pairAddress && account != routerAddress, "New account must NOT be one of Pancake or Uniswap Router and Pair contract.");
        require(account != liquidityPool && account != stakingAddress, "New account account must NOT be one of our ecosystem contract.");
        require(account != zeroAddress && account != deadAddress, "New account account must NOT be one of EVM zero and dead wallets.");

        marketing = account;
    }

    function setDevelopment(address account) external onlyAdmin() {
        require(account != pairAddress && account != routerAddress, "New account must NOT be one of Pancake or Uniswap Router and Pair contract.");
        require(account != liquidityPool && account != stakingAddress, "New account account must NOT be one of our ecosystem contract.");
        require(account != zeroAddress && account != deadAddress, "New account account must NOT be one of EVM zero and dead wallets.");

        development = account;
    }

    function setLiquidityPool(address account) external onlyAdmin() {
        require(account != pairAddress && account != routerAddress, "New liquidity pool must NOT be one of Pancake or Uniswap Router and Pair contract.");
        require(account != stakingAddress, "New liquidity pool account must NOT be one of our ecosystem contract.");
        require(account != zeroAddress && account != deadAddress, "New liquidity pool account must NOT be one of EVM zero and dead wallets.");

        liquidityPool = account;
    }

    function setStakingAddress(address account) external onlyAdmin {
        require(account != pairAddress && account != routerAddress, "New staking contract must NOT be one of Pancake or Uniswap Router and Pair contract.");
        require(account != liquidityPool, "New staking contract account must NOT be one of our ecosystem contract.");
        require(account != zeroAddress && account != deadAddress, "New staking contract account must NOT be one of EVM zero and dead wallets.");

        stakingAddress = account;
    }

    
    
    function setMinSellTxAmount(uint256 minAmount) external onlyAdmin {
        _antiWhale.minSellTxAmount = minAmount * 10**decimals();
    }

    
    function setMaxSellTxAmount(uint256 maxAmount) external onlyAdmin {
        _antiWhale.maxSellTxAmount = maxAmount * 10**decimals();
    }

    
    function setMaxPerHourTxAmount(uint256 maxPerHourAmount) external onlyAdmin {
        _antiWhale.maxPerHourTxAmount = maxPerHourAmount * 10**decimals();
    }

    
    function setMaxTransferLimit(uint256 maxTransferAmount) external onlyAdmin {
        _antiWhale.maxTransferLimit = maxTransferAmount * 10**decimals();
    }

    
    function setWhaleHour(uint256 _timeLimit) external onlyAdmin {
        _antiWhale.timeLimit = _timeLimit;
    }

    function setAntiWhaleEnabled(bool enabled) external onlyAdmin {
        _antiWhale.enabled = enabled;
    }
}
