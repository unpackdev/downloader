// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./IStrategy.sol";
import "./RankedList.sol";

import "./IterableMap.sol";


contract Vault is ERC20 {
    // Add the library methods
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableMap for IterableMap.AddressToUintMap;

    //策略总资产
    struct StrategyState {
        uint256 totalAssets;//当前总资产
        uint256 totalDebt;//投入未返还成本
    }

    //协议总资产
    struct ProtocolState {
        uint256 lastReportTime;//计算时间
        uint256 totalAssets;//当前总资产
    }

    //协议APY设置参数
    struct StrategyApy {
        address strategyAddress;//策略地址
        uint256 apy;//策略APY
    }

    //最大百分比100%
    uint256 constant MAX_BPS = 10000;

    //用户提款队列
    IterableMap.AddressToUintMap private userWithdrawMap;

    //用户存款队列
    IterableMap.AddressToUintMap private userDepositMap;

    //策略集合
    EnumerableSet.AddressSet private strategySet;

    //策略状态
    mapping(address => StrategyState) public strategyStates;
    //协议状态
    mapping(uint256 => ProtocolState) public protocolStates;

    //用户存款成本总计，用于计算用户收益
    mapping(address => uint256) public userDebts;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping (address => bool) public greyList;

    //池子接收的token
    ERC20 public token;
    //池子接收的token的精度，也是池子aToken的精度
    uint8 public myDecimals;

    //池子币种的精度单位，比如精度6，则为10的6次方：1000000
    uint256 public underlyingUnit;

    //精度因子：如果aToken精度为6，则精度因子为10 ** (18-6)；否则精度因子为1
    uint256 public precisionFactor;
    //国库收益地址
    address public rewards;
    //治理方地址
    address public governance;
    //管理者地址
    address public management;
    //定时器账户地址
    address public keeper;
    //收益提成费用
    uint256 public profitManagementFee;
    //每个策略投资金额，不能超过储蓄池的20%
    uint256 public maxPercentPerStrategy;
    //每个协议的所有策略投资金额，不能超过储蓄池的30%
    uint256 public maxPercentPerProtocol;
    //每个策略投资金额，不能超过目标第三方投资池子的20%
    uint256 public maxPercentInvestVault;

    //兑换时允许超出预言机返回汇率的最大百分比,default:2%
    uint256 public maxExchangeRateDeltaThreshold = 200;

    // The minimum number of seconds between doHardWork calls.
    uint256 public minWorkDelay;
    uint256 public lastWorkTime;

    //上次的净值
    uint256 public pricePerShare;

    //上上次的净值
    uint256 public lastPricePerShare;

    uint256 public apy = 0;

    //是否紧急关停
    bool public emergencyShutdown;

    //今天的存款总额，这样不用循环用户存款队列计算总额
    uint256 public todayDepositAmounts;
    //今天的取款份额，这样不用循环用户取款队列计算总额
    uint256 public todayWithdrawShares;

    //所有策略的总资产
    uint256 public strategyTotalAssetsValue;

    /**
    * 限制只能管理员或者治理方可以发起调用
    **/
    modifier onlyGovernance(){
        require(msg.sender == governance || msg.sender == management, "The caller must be management or governance");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper || msg.sender == management || msg.sender == governance, 'only keeper');
        _;
    }

    // Only smart contracts will be affected by this modifier
    modifier defense() {
        require((msg.sender == tx.origin) || !greyList[msg.sender], "This smart contract has been grey listed");
        _;
    }

    /**
    * 构建函数
    * @param _token：目前都应该是USDT地址
    * @param _management：管理者地址
    * @param _rewards：国库合约地址
    **/
    constructor(address _token, address _management, address _keeper, address _rewards) ERC20(
        string(abi.encodePacked("PIGGY_", ERC20(_token).name())),
        string(abi.encodePacked("p", ERC20(_token).symbol()))
    ) {
        governance = msg.sender;
        management = _management;
        keeper = _keeper;

        token = ERC20(_token);

        myDecimals = token.decimals();
        require(myDecimals < 256);

        if (myDecimals < 18) {
            precisionFactor = 10 ** (18 - myDecimals);
        } else {
            precisionFactor = 1;
        }
        underlyingUnit = 10 ** myDecimals;
        require(_rewards != address(0), 'rewards: ZERO_ADDRESS');
        rewards = _rewards;

        pricePerShare=underlyingUnit;

        //默认25%的收益管理费
        profitManagementFee = 2500;
        //每个策略投资金额，不能超过储蓄池的20%
        maxPercentPerStrategy = 2000;
        //每个协议的所有策略投资金额，不能超过储蓄池的30%
        maxPercentPerProtocol = 3000;
        //每个策略投资金额，不能超过目标第三方投资池子的20%，则策略投入的资金应该是策略投入前的25%
        maxPercentInvestVault = 2000;

        //最小工作时间间隔
        minWorkDelay = 0;
    }

    function decimals() public view virtual override returns (uint8) {
        return myDecimals;
    }

    function setGovernance(address _governance) onlyGovernance external {
        governance = _governance;
    }

    function setManagement(address _management) onlyGovernance external {
        management = _management;
    }

    function setRewards(address _rewards) onlyGovernance external {
        rewards = _rewards;
    }

    function setProfitManagementFee(uint256 _profitManagementFee) onlyGovernance external {
        require(_profitManagementFee <= MAX_BPS);
        profitManagementFee = _profitManagementFee;
    }

    function setMaxPercentPerStrategy(uint256 _maxPercentPerStrategy) onlyGovernance external {
        require(_maxPercentPerStrategy <= MAX_BPS);
        maxPercentPerStrategy = _maxPercentPerStrategy;
    }

    function setMaxPercentPerProtocole(uint256 _maxPercentPerProtocol) onlyGovernance external {
        require(_maxPercentPerProtocol <= MAX_BPS);
        maxPercentPerProtocol = _maxPercentPerProtocol;
    }

    function setMaxPercentInvestVault(uint256 _maxPercentInvestVault) onlyGovernance external {
        require(_maxPercentInvestVault <= MAX_BPS);
        maxPercentInvestVault = _maxPercentInvestVault;
    }

    function setMinWorkDelay(uint256 _delay) external onlyGovernance {
        minWorkDelay = _delay;
    }

    function setMaxExchangeRateDeltaThreshold(uint256 _threshold) public onlyGovernance {
        require(_threshold <= MAX_BPS);
        maxExchangeRateDeltaThreshold = _threshold;
    }

    function setEmergencyShutdown(bool active) onlyGovernance external {
        emergencyShutdown = active;
    }

    function setKeeper(address keeperAddress) onlyGovernance external {
        keeper = keeperAddress;
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function totalAssets() public view returns (uint256) {
        return token.balanceOf(address(this)) + strategyTotalAssetsValue;
    }

    //    /**
    //    * 测试临时使用重置Vault
    //    */
    //    function reTestInit() external onlyGovernance () {
    //        //将策略的钱全部取出来
    //        for (uint256 i = 0; i < strategySet.length(); i++)
    //        {
    //            IStrategy(strategySet.at(i)).withdrawToVault(1, 1);
    //            protocolStates[IStrategy(strategySet.at(i)).protocol()].totalAssets =0;
    //            strategyStates[strategySet.at(i)].totalAssets = 0;
    //        }
    //
    //        for (uint256 i = 0; i < userWithdrawMap.length();) {
    //            (address userAddress, uint256 userShares) = userWithdrawMap.at(i);
    //            userWithdrawMap.remove(userAddress);
    //        }
    //
    //        for (uint256 i = 0; i < userDepositMap.length();) {
    //            (address userAddress, uint256 amount) = userDepositMap.at(i);
    //            userDepositMap.remove(userAddress);
    //        }
    //
    //        //上次的净值
    //        pricePerShare=0;
    //        //今天的存款总额，这样不用循环用户存款队列计算总额
    //        todayDepositAmounts=0;
    //        //今天的取款份额，这样不用循环用户取款队列计算总额
    //        todayWithdrawShares=0;
    //        //所有策略的总资产
    //        strategyTotalAssetsValue=0;
    //
    //        token.safeTransfer(rewards, token.balanceOf(address(this)));
    //    }

    /**
    * 返回策略数组
    */
    function strategies() external view returns (address[] memory) {
        address[] memory strategyArray = new address[](strategySet.length());
        for (uint256 i = 0; i < strategySet.length(); i++)
        {
            strategyArray[i] = strategySet.at(i);
        }
        return strategyArray;
    }

    /**
    * 返回策略资产
    */
    function strategyState(address strategyAddress) external view returns (StrategyState memory) {
        return strategyStates[strategyAddress];
    }

    /**
    * 设置策略APY
    */
    function setApys(StrategyApy[] memory strategyApys) external onlyKeeper {
        for (uint i = 0; i < strategyApys.length; i++) {
            StrategyApy memory strategyApy = strategyApys[i];
            if (strategySet.contains(strategyApy.strategyAddress) && strategyStates[strategyApy.strategyAddress].totalAssets <= 0) {
                IStrategy(strategyApy.strategyAddress).updateApy(strategyApy.apy);
            }
        }
    }

    /**
    * 地址to使用amount的token，换取了返回的shares量的股份凭证
    */
    function _issueSharesForAmount(address to, uint256 amount) internal returns (uint256) {
        uint256 shares = 0;
        //如果昨天没有净值价格，则为第一次doHardWork之前的投入，1：1
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            require(pricePerShare != 0);
            //            shares = amount.mul(totalSupply()).div(totalAssets() - todayDepositAmounts);
            shares = amount.mul(underlyingUnit).div(pricePerShare);
        }
        _mint(to, shares);
        return shares;
    }

    /**
    * 转账时，同时转移用户成本
    **/
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override
    {


        super._beforeTokenTransfer(from, to, amount);
        //用户之间转账的时候，需要将成本也随之移动
        if(from != address(0) && to!= address(0)){
            uint256 transferDebt = userDebts[from].mul(balanceOf(from)).div(amount);

            if(transferDebt>userDebts[from]){
                transferDebt = userDebts[from];
            }
            userDebts[from] -= transferDebt;
            userDebts[to] += transferDebt;


        }
    }

    /**
     * 存款，当前只是加入存款队列，每日定时任务处理分派份额
     * @param _amount：目前都应该是USDT数量
     **/
    function deposit(uint256 _amount) external defense {
        require(_amount > 0, "amount should more than 0");
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        userDepositMap.plus(msg.sender, _amount);
        todayDepositAmounts += _amount;
        token.safeTransferFrom(msg.sender, address(this), _amount);

    }

    /**
     * 计算shares份额当前价值多少token
     * @param shares：份额
     **/
    function _shareValue(uint256 shares) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return shares;
        }
        //return shares.mul(totalAssets() - todayDepositAmounts).div(totalSupply());
        return shares.mul(pricePerShare).div(underlyingUnit);
    }

    /**
     * 取款，当前只是加入取款队列，每日定时任务处理取款
     * @param shares：份额
     **/
    function withdraw(uint256 shares) external {
        require(shares > 0, "amount should more than 0");
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        require(shares <= balanceOf(msg.sender), "can not withdraw more than user total");
        userWithdrawMap.plus(msg.sender, shares);
        todayWithdrawShares += shares;
        require(userWithdrawMap.get(msg.sender) <= balanceOf(msg.sender));
    }

    /**
     * 还未处理的用户存款
     * @return USDT 存款USDT数量
     **/
    function inQueueDeposit(address userAddress) public view returns (uint256) {
        return userDepositMap.get(userAddress);
    }

    /**
     * 用户还未赎回的成本
     * @return USDT 成本存款USDT数量
     **/
    function userDebt(address userAddress) public view returns (uint256) {
        return userDebts[userAddress];
    }

    /**
     * 还未处理的用户提取份额
     * @return share 提取的share数量
     **/
    function inQueueWithdraw(address userAddress) public view returns (uint256) {
        return userWithdrawMap.get(userAddress);
    }

    //    /**
    //     * 每个份额等于多少的USDT，基于上一次的hardWork结果
    //     **/
    //    function getPricePerShare() public view returns (uint256) {
    //        return _shareValue(10 ** myDecimals);
    //    }

    /**
     * 添加策略
     **/
    function addStrategy(address strategy) onlyGovernance external {
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        require(strategy != address(0), "strategy address can't be 0");
        require(strategySet.contains(strategy) == false, "strategy already exists");
        require(IStrategy(strategy).vault() == address(this), "strategy's vault error");
        require(IStrategy(strategy).want() == address(token), "strategy's token doesn't match");

        strategySet.add(strategy);
        strategyStates[strategy] = StrategyState({
        totalAssets : 0,
        totalDebt : 0
        });
    }

    /**
     * 移除策略
     **/
    function removeStrategy(address strategy) onlyGovernance external {
        require(strategySet.contains(strategy) == true, "strategy not exists");

        strategySet.remove(strategy);

        uint256 strategyTotalAssets = strategyStates[strategy].totalAssets;
        strategyTotalAssetsValue -= strategyTotalAssets;
        protocolStates[IStrategy(strategy).protocol()].totalAssets -= strategyTotalAssets;
        strategyStates[strategy].totalAssets = 0;

        //将策略的钱全部取回Vault
        (uint256 value, uint256 partialClaimValue, uint256 claimValue) = IStrategy(strategy).withdrawToVault(1, 1);
        uint256 strategyActualTotal = value + claimValue;
        if (strategyStates[strategy].totalDebt <= strategyActualTotal) {
            strategyStates[strategy].totalDebt = 0;
        } else {
            strategyStates[strategy].totalDebt -= strategyActualTotal;
        }
    }

    /**
     * 策略迁移
     **/
    function migrateStrategy(address oldVersion, address newVersion) onlyGovernance external {
        require(newVersion != address(0), "strategy address can't be 0");
        require(strategySet.contains(oldVersion) == true, "strategy will be migrate doesn't exists");
        require(strategySet.contains(newVersion) == false, "new strategy already exists");

        StrategyState memory strategy = strategyStates[oldVersion];
        strategyStates[oldVersion].totalAssets = 0;
        strategyStates[oldVersion].totalDebt = 0;

        protocolStates[IStrategy(oldVersion).protocol()].totalAssets -= strategy.totalAssets;

        strategyStates[newVersion] = StrategyState({
        totalAssets : strategy.totalAssets,
        totalDebt : strategy.totalDebt
        });

        protocolStates[IStrategy(newVersion).protocol()].totalAssets += strategy.totalAssets;

        IStrategy(oldVersion).migrate(newVersion);

        strategySet.add(newVersion);
        strategySet.remove(oldVersion);

    }

    //计算策略是否超出它的贷款限额，并且返回应该提取多少金额返回给池子
    function _calDebt(address strategy,uint256 vaultAssetsLimit,uint256 protocolDebtLimit) internal view returns (uint256 debt) {
        //策略当前已投入资产
        uint256 strategyTotalAssets = strategyStates[strategy].totalAssets;



        //不超过策略投资池子总资金量的20%
        uint256 invest_vault_assets_limit = IStrategy(strategy).getInvestVaultAssets().mul(maxPercentInvestVault).div(MAX_BPS);


        //协议下所有策略总投资资金不超过总资金的30%

        //本策略协议的已投资总资金
        uint256 protocol_debt = protocolStates[IStrategy(strategy).protocol()].totalAssets;

        uint256 strategy_protocol_limit = protocolDebtLimit;
        //如果超出协议资金的30%，则返还可返还的超出部分，然后和上面那个应该返还的，取应该返还的大值
        if (protocol_debt > protocolDebtLimit) {
            //协议还需要退还多少资金
            uint256 shouldProtocolReturn = protocol_debt - protocolDebtLimit;

            //排除本策略资金，其他策略占了多少资金
            uint256 other_strategy_debt = protocol_debt - strategyTotalAssets;

            //如果其他协议加起来，还是超过限制，则超出部分，本策略退还
            if (shouldProtocolReturn > other_strategy_debt) {
                strategy_protocol_limit = strategyTotalAssets - (shouldProtocolReturn - other_strategy_debt);

            }
            //如果后面低APY的协议资金够抽取，则本策略不提取；
        }
        uint256 strategy_limit = Math.min(strategy_protocol_limit, Math.min(vaultAssetsLimit, invest_vault_assets_limit));

        if (strategy_limit > strategyTotalAssets) {
            return 0;
        } else {
            return (strategyTotalAssets - strategy_limit);
        }
    }

    //计算策略是否超出它的贷款限额，并且返回应该提取多少金额返回给池子
    function _calCredit(address strategy,uint256 vaultAssetsLimit,uint256 protocolDebtLimit) internal view returns (uint256 credit) {

        //        //如果紧急情况，全部返还
        //        if (emergencyShutdown) {
        //            return 0;
        //        }

        //策略当前已投入资产
        uint256 strategyTotalAssets = strategyStates[strategy].totalAssets;



        if (strategyTotalAssets >= vaultAssetsLimit) {
            return 0;
        }

        //不超过策略投资池子总资金量的20%
        uint256 invest_vault_assets_limit = IStrategy(strategy).getInvestVaultAssets().mul(maxPercentInvestVault).div(MAX_BPS);


        if (strategyTotalAssets >= invest_vault_assets_limit) {
            return 0;
        }

        //协议下所有策略总投资资金不超过总资金的30%

        //本策略协议的已投资总资金
        uint256 protocol_debt = protocolStates[IStrategy(strategy).protocol()].totalAssets;

        //如果超出协议资金的30%，则返还可返还的超出部分，然后和上面那个应该返还的，取应该返还的大值
        if (protocol_debt >= protocolDebtLimit) {
            return 0;
        }
        uint256 strategy_limit = Math.min((protocolDebtLimit - protocol_debt), Math.min((vaultAssetsLimit - strategyTotalAssets), (invest_vault_assets_limit - strategyTotalAssets)));

        return strategy_limit;
    }

    /**
     * 每日工作的定时任务
     **/
    function doHardWork() onlyKeeper external {
        require(emergencyShutdown == false, "vault has been emergency shutdown");
        uint256 now = block.timestamp;
        require(now.sub(lastWorkTime) >= minWorkDelay, "Should not trigger if not waited long enough since previous doHardWork");

        //1. 先办理未处理的提款
        //根据用户要提取的份额，策略提取出的总金额
        uint256 strategyWithdrawForUserValue = 0;
        //策略用户提取后的总资产，需要重新算
        uint256 newStrategyTotalAssetsValue = 0;
        //按APY对策略进行排序
        RankedList sortedStrategies = new RankedList();
        //策略归属协议的资产也需要重算
        uint256 reportTime = block.timestamp;


        //在从策略提取钱之前，先计算余额多少
        uint256 userWithdrawBalanceTotal = totalSupply() == 0 ? 0 : (token.balanceOf(address(this)) - todayDepositAmounts).mul(todayWithdrawShares).div(totalSupply());

        for (uint256 i = 0; i < strategySet.length(); i++)
        {
            address strategy = strategySet.at(i);
            IStrategy strategyInstant = IStrategy(strategy);

            uint256 strategyWithdrawValue;
            uint256 value;
            uint256 partialClaimValue;
            uint256 claimValue;
            //先进行用户取款
            if (todayWithdrawShares > 0) {
                (value, partialClaimValue, claimValue) = strategyInstant.withdrawToVault(todayWithdrawShares, totalSupply());

            } else {
                //用户取款为0，那就需要手动百分之一，用来评估策略当前净值
                (value, partialClaimValue, claimValue) = strategyInstant.withdrawToVault(1, 100);

            }

            strategyWithdrawValue = value + claimValue;

            strategyWithdrawForUserValue += (value + partialClaimValue);

            //计算用户取款后的策略资产
            uint strategyAssets = strategyInstant.estimatedTotalAssets();

            strategyStates[strategy].totalAssets = strategyAssets;

            if (strategyWithdrawValue > strategyStates[strategy].totalDebt) {
                strategyStates[strategy].totalDebt = 0;
            } else {
                strategyStates[strategy].totalDebt -= strategyWithdrawValue;
            }

            uint256 protocol = strategyInstant.protocol();
            if (protocolStates[protocol].lastReportTime == reportTime) {
                protocolStates[protocol].totalAssets += strategyAssets;
            } else {
                protocolStates[protocol].lastReportTime = reportTime;
                protocolStates[protocol].totalAssets = strategyAssets;
            }


            //评估用户提款后的策略总资产
            newStrategyTotalAssetsValue += strategyAssets;

            //根据策略APY维护排序队列,进行投资
            sortedStrategies.insert(uint256(strategyInstant.apy()), strategy);
        }
        strategyTotalAssetsValue = newStrategyTotalAssetsValue;
        //计算token净值
        lastPricePerShare = pricePerShare;
        pricePerShare = totalSupply() == 0 ? underlyingUnit : (totalAssets() - todayDepositAmounts).mul(underlyingUnit).div(totalSupply());


        if(pricePerShare>lastPricePerShare){
            apy = (pricePerShare-lastPricePerShare).mul(31536000).mul(1e4).div(now-lastWorkTime).div(lastPricePerShare);
        }else{
            apy=0;
        }


        uint256 userWithdrawTotal = strategyWithdrawForUserValue + userWithdrawBalanceTotal;

        //净值增长，表示有收益
        uint256 totalProfitFee = 0;
        for (uint256 i = 0; i < userWithdrawMap.length();) {
            (address userAddress, uint256 userShares) = userWithdrawMap.at(i);

            //用户按成本应该提取的金额
            uint256 userCost= userDebts[userAddress].mul(userShares).div(balanceOf(userAddress));

            //用户现在实际提取的金额
            uint256 toUserAll = userWithdrawTotal.mul(userShares).div(todayWithdrawShares);

            //如果有收益，提取25%
            if (toUserAll > userCost) {
                uint256 profitFee = ((toUserAll - userCost).mul(profitManagementFee).div(MAX_BPS));

                totalProfitFee += profitFee;
                toUserAll -= profitFee;
                userDebts[userAddress] -= userCost;
            } else {

                userDebts[userAddress] -= toUserAll;
            }
            _burn(userAddress, userShares);
            //用户份额都提取完，则成本重置为0
            if(balanceOf(userAddress)==0){
                userDebts[userAddress]=0;
            }

            token.safeTransfer(userAddress, toUserAll);
            userWithdrawMap.remove(userAddress);
        }
        if (totalProfitFee > 0) {

            token.safeTransfer(rewards, totalProfitFee);
        }
        todayWithdrawShares = 0;
        //如果紧急关闭，不做hardWork，储蓄池可以调用removeStrategy移除策略
        //        if (emergencyShutdown) {

        //            //3. 返还未处理的存款
        //            for (uint256 i = 0; i < userDepositMap.length();) {
        //                (address userAddress, uint256 amount) = userDepositMap.at(i);
        //                token.safeTransfer(userAddress, amount);
        //                userDepositMap.remove(userAddress);
        //            }
        //            todayDepositAmounts = 0;
        //        } else {

        //3. 办理未处理的存款，包括提取收益
        //给用户按上次的token净值，分派shares
        for (uint256 i = 0; i < userDepositMap.length();) {
            (address userAddress, uint256 amount) = userDepositMap.at(i);
            userDebts[userAddress] += amount;
            uint shares = _issueSharesForAmount(userAddress, amount);

            userDepositMap.remove(userAddress);
        }
        todayDepositAmounts = 0;


        uint256 vaultTotalAssets = totalAssets();

        //不超过总投资资金的20%
        uint256 vaultAssetsLimit = vaultTotalAssets.mul(maxPercentPerStrategy).div(MAX_BPS);
        uint256 protocolDebtLimit = vaultTotalAssets.mul(maxPercentPerProtocol).div(MAX_BPS);
        //4. 办理策略超额调整
        uint256 strategyPosition = 0;
        uint256 nextId = sortedStrategies.head();
        while (nextId != 0) {
            (uint256 id, uint256 next, uint256 prev, uint256 rank, address strategy) = sortedStrategies.get(nextId);

            //计算策略需要返还vault的金额
            uint256 debt = _calDebt(strategy,vaultAssetsLimit,protocolDebtLimit);

            if (debt > 0) {
                uint256 debtReturn = IStrategy(strategy).cutOffPosition(debt);
                strategyStates[strategy].totalAssets -= debt;
                if (debtReturn > strategyStates[strategy].totalDebt) {
                    strategyStates[strategy].totalDebt = 0;
                } else {
                    strategyStates[strategy].totalDebt -= debtReturn;
                }

                protocolStates[IStrategy(strategy).protocol()].totalAssets -= debt;
                strategyTotalAssetsValue -= debt;

            }
            nextId = next;
            strategyPosition++;
        }

        //5. 办理策略补充资金及投资

        strategyPosition = 0;
        nextId = sortedStrategies.head();
        while (nextId != 0) {
            //没有钱可以投了，就退出
            uint256 vault_balance = token.balanceOf(address(this));

            if (vault_balance <= 0) {

                break;
            }

            (uint256 id, uint256 next, uint256 prev, uint256 rank, address strategy) = sortedStrategies.get(nextId);

            uint256 calCredit = _calCredit(strategy,vaultAssetsLimit,protocolDebtLimit);
            if (calCredit > 0) {
                //计算策略最多可从vault中取走的金额
                uint256 credit = Math.min(calCredit, token.balanceOf(address(this)));

                if (credit > 0) {
                    strategyStates[strategy].totalAssets += credit;
                    strategyStates[strategy].totalDebt += credit;
                    protocolStates[IStrategy(strategy).protocol()].totalAssets += credit;
                    token.safeTransfer(strategy, credit);
                    strategyTotalAssetsValue += credit;



                    //调用策略的invest()开始工作
                    IStrategy(strategy).invest();
                }
            }

            nextId = next;
            strategyPosition++;
        }

        //        }
        lastWorkTime = now;
    }

    /**
     * 治理者可以将错发到本合约的其他货币，转到自己的账户下
     * @param _token：其他货币地址
     **/
    function sweep(address _token) onlyGovernance external {
        require(_token != address(token));
        uint256 value = token.balanceOf(address(this));
        token.safeTransferFrom(address(this), msg.sender, value);
    }

}