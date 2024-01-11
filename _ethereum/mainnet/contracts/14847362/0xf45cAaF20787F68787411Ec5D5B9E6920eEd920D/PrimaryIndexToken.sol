// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ProxyAdmin.sol";
import "./TransparentUpgradeableProxy.sol";

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IPriceProviderAggregator.sol";
import "./BLendingToken.sol";

contract PrimaryIndexToken is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for ERC20Upgradeable;

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    string public name;

    string public symbol;

    IPriceProviderAggregator public priceOracle; // address of price oracle with interface of PriceProviderAggregator

    address[] public projectTokens;
    mapping(address => ProjectTokenInfo) public projectTokenInfo; // project token address => ProjectTokenInfo

    address[] public lendingTokens;
    mapping(address => LendingTokenInfo) public lendingTokenInfo; // lending token address => LendingTokenInfo

    mapping(address => uint256) public totalDepositedProjectToken; // tokenAddress => PRJ token staked
    mapping(address => mapping(address => mapping(address => DepositPosition))) public depositPosition; // user address => PRJ token address => lendingToken address => DepositPosition
    mapping(address => mapping(address => mapping(address => BorrowPosition))) public borrowPosition; // user address => project token address => lending token address => BorrowPosition

    mapping(address => mapping(address => uint256)) public totalBorrow; //project token address => total borrow by project token []
    mapping(address => mapping(address => uint256)) public borrowLimit; //project token address => limit of borrowing; [borrowLimit]=$

    struct Ratio {
        uint8 numerator;
        uint8 denominator;
    }

    struct ProjectTokenInfo {
        bool isListed;
        bool isDepositPaused; // true - paused, false - not paused
        bool isWithdrawPaused; // true - paused, false - not paused
        Ratio loanToValueRatio;
        Ratio liquidationThresholdFactor;
        Ratio liquidationIncentive;
    }

    struct LendingTokenInfo {
        bool isListed;
        bool isPaused;
        BLendingToken bLendingToken;
    }
    
    struct DepositPosition {
        uint256 depositedProjectTokenAmount;
    }

    struct BorrowPosition {
        uint256 loanBody;   // [loanBody] = lendingToken
        uint256 accrual;   // [accrual] = lendingToken
    }

    event AddPrjToken(address indexed tokenPrj);

    event LoanToValueRatioSet(address indexed tokenPrj, uint8 lvrNumerator, uint8 lvrDenominator);

    event LiquidationThresholdFactorSet(address indexed tokenPrj, uint8 ltfNumerator, uint8 ltfDenominator);

    event LiquidationIncentiveSet(address indexed tokenPrj, uint8 ltfNumerator, uint8 ltfDenominator);

    event Deposit(address indexed who, address indexed tokenPrj, address lendingToken, uint256 prjDepositAmount, address indexed beneficiary);

    event Withdraw(address indexed who, address indexed tokenPrj, address lendingToken, uint256 prjWithdrawAmount, address indexed beneficiary);

    event Supply(address indexed who, address indexed supplyToken, uint256 supplyAmount, address indexed supplyBToken, uint256 amountSupplyBTokenReceived);

    event Redeem(address indexed who, address indexed redeemToken, address indexed redeemBToken, uint256 redeemAmount);

    event RedeemUnderlying(address indexed who, address indexed redeemToken, address indexed redeemBToken, uint256 redeemAmountUnderlying);

    event Borrow(address indexed who, address indexed borrowToken, uint256 borrowAmount, address indexed prjAddress, uint256 prjAmount);

    event RepayBorrow(address indexed who, address indexed borrowToken, uint256 borrowAmount, address indexed prjAddress, bool isPositionFullyRepaid);

    event Liquidate(address indexed liquidator, address indexed borrower, address lendingToken, address indexed prjAddress, uint256 amountPrjLiquidated);

    function initialize() public initializer {
        name = "Primary Index Token";
        symbol = "PIT";
        __AccessControl_init();
        __ReentrancyGuard_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MODERATOR_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the Admin");
        _;
    }

    modifier onlyModerator() {
        require(hasRole(MODERATOR_ROLE, msg.sender), "Caller is not the Moderator");
        _;
    }

    modifier isProjectTokenListed(address projectToken) {
        require(projectTokenInfo[projectToken].isListed, "PIT: project token is not listed");
        _;
    }

    modifier isLendingTokenListed(address lendingToken) {
        require(lendingTokenInfo[lendingToken].isListed, "PIT: lending token is not listed");
        _;
    }

    //************* ADMIN FUNCTIONS ********************************

    function addProjectToken(
        address _projectToken,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator,
        uint8 _liquidationThresholdFactorNumerator,
        uint8 _liquidationThresholdFactorDenominator,
        uint8 _liquidationIncentiveNumerator,
        uint8 _liquidationIncentiveDenominator
    ) public onlyAdmin {
        require(_projectToken != address(0), "invalid _projectToken");

        if(!projectTokenInfo[_projectToken].isListed){ 
            projectTokens.push(_projectToken);
            projectTokenInfo[_projectToken].isListed = true;
        }
        
        setProjectTokenInfo(
            _projectToken, 
            _loanToValueRatioNumerator, 
            _loanToValueRatioDenominator, 
            _liquidationThresholdFactorNumerator,
            _liquidationThresholdFactorDenominator,
            _liquidationIncentiveNumerator, 
            _liquidationIncentiveDenominator
        );

        setPausedProjectToken(_projectToken, false, false);

        emit AddPrjToken(_projectToken);
    }

    function removeProjectToken(
        uint256 _projectTokenId
    ) public onlyAdmin isProjectTokenListed(projectTokens[_projectTokenId]) {
        address projectToken = projectTokens[_projectTokenId];
        delete projectTokenInfo[projectToken];

        require(totalDepositedProjectToken[projectToken] == 0, "PIT: projectToken amount exist on PIT");

        projectTokens[_projectTokenId] = projectTokens[projectTokens.length - 1];
        projectTokens.pop();
    }

    function addLendingToken(
        address _lendingToken, 
        address _bLendingToken,
        bool _isPaused
    ) public onlyAdmin {
        require(_lendingToken != address(0), "invalid _lendingToken");

        if(!lendingTokenInfo[_lendingToken].isListed){
            lendingTokens.push(_lendingToken);
            lendingTokenInfo[_lendingToken].isListed = true;
        }

        setLendingTokenInfo(
            _lendingToken, 
            _bLendingToken, 
            _isPaused
        );
    }

    function removeLendingToken(
        uint256 _lendingTokenId
    ) public onlyAdmin isLendingTokenListed(lendingTokens[_lendingTokenId]) {
        address lendingToken = lendingTokens[_lendingTokenId];
        delete lendingTokenInfo[lendingToken];

        for(uint256 i = 0; i < projectTokens.length; i++) {
            require(totalBorrow[projectTokens[i]][lendingToken] == 0, "PIT: exist borrow of lendingToken");
        }

        lendingTokens[_lendingTokenId] = lendingTokens[lendingTokens.length - 1];
        lendingTokens.pop();
    }

    function setPriceOracle(address _priceOracle) public onlyAdmin {
        require(_priceOracle != address(0), "invalid _priceOracle");
        priceOracle = IPriceProviderAggregator(_priceOracle);
    }

    function grandModerator(address newModerator) public onlyAdmin {
        grantRole(MODERATOR_ROLE, newModerator);
    }

    function revokeModerator(address moderator) public onlyAdmin {
        revokeRole(MODERATOR_ROLE, moderator);
    }

    //************* MODERATOR FUNCTIONS ********************************

    function setBorrowLimit(address projectToken, address lendingToken, uint256 _borrowLimit) public onlyModerator isProjectTokenListed(projectToken) {
        require(_borrowLimit > 0, "PIT: borrowLimit=0");
        borrowLimit[projectToken][lendingToken] = _borrowLimit;
        //emit set borrow limit
    }

    function setProjectTokenInfo(
        address _projectToken,
        uint8 _loanToValueRatioNumerator,
        uint8 _loanToValueRatioDenominator,
        uint8 _liquidationThresholdFactorNumerator,
        uint8 _liquidationThresholdFactorDenominator,
        uint8 _liquidationIncentiveNumerator,
        uint8 _liquidationIncentiveDenominator
    ) public onlyModerator isProjectTokenListed(_projectToken) {
        require(_loanToValueRatioNumerator <= _loanToValueRatioDenominator, "invalid loanToValueRatio");
        require(_liquidationThresholdFactorNumerator >= _liquidationThresholdFactorDenominator, "invalid liquidationTresholdFactor");
        require(_liquidationIncentiveNumerator >= _liquidationIncentiveDenominator, "invalid liquidationIncentive");
        
        ProjectTokenInfo storage info = projectTokenInfo[_projectToken];
        info.loanToValueRatio = Ratio(_loanToValueRatioNumerator, _loanToValueRatioDenominator);
        info.liquidationThresholdFactor = Ratio(_liquidationThresholdFactorNumerator, _liquidationThresholdFactorDenominator);
        info.liquidationIncentive = Ratio(_liquidationIncentiveNumerator, _liquidationIncentiveDenominator);
    
        emit LoanToValueRatioSet(_projectToken, _loanToValueRatioNumerator, _loanToValueRatioDenominator);
        emit LiquidationThresholdFactorSet(_projectToken, _liquidationThresholdFactorNumerator, _liquidationThresholdFactorDenominator);
        emit LiquidationIncentiveSet(_projectToken, _liquidationIncentiveNumerator, _liquidationIncentiveDenominator);
    }

    function setPausedProjectToken(
        address _projectToken, 
        bool _isDepositPaused, 
        bool _isWithdrawPaused
    ) public onlyModerator isProjectTokenListed(_projectToken) {
        projectTokenInfo[_projectToken].isDepositPaused = _isDepositPaused;
        projectTokenInfo[_projectToken].isWithdrawPaused = _isWithdrawPaused;
    }

    function setLendingTokenInfo(
        address _lendingToken, 
        address _bLendingToken,
        bool _isPaused
    ) public onlyModerator isLendingTokenListed(_lendingToken){
        require(_bLendingToken != address(0), "invalid _bLendingToken");
        LendingTokenInfo storage info = lendingTokenInfo[_lendingToken];
        
        info.isPaused = _isPaused;
        info.bLendingToken = BLendingToken(_bLendingToken);
        require(info.bLendingToken.underlying() == _lendingToken, "PIT: underlyingOfbLendingToken!=lendingToken");
    }

    function setPausedLendingToken(address _lendingToken, bool _isPaused) public onlyModerator isLendingTokenListed(_lendingToken) {
        lendingTokenInfo[_lendingToken].isPaused = _isPaused;
    }

    //************* PUBLIC FUNCTIONS ********************************

    function deposit(address projectToken, address lendingToken, uint256 projectTokenAmount) public isProjectTokenListed(projectToken) isLendingTokenListed(lendingToken) nonReentrant() {
        require(!projectTokenInfo[projectToken].isDepositPaused, "PIT: projectToken is paused");
        require(projectTokenAmount > 0, "PIT: projectTokenAmount==0");
        DepositPosition storage _depositPosition = depositPosition[msg.sender][projectToken][lendingToken];
        ERC20Upgradeable(projectToken).safeTransferFrom(msg.sender, address(this), projectTokenAmount);
        _depositPosition.depositedProjectTokenAmount += projectTokenAmount;
        totalDepositedProjectToken[projectToken] += projectTokenAmount;
        emit Deposit(msg.sender,  projectToken, lendingToken, projectTokenAmount, msg.sender);
    }

    function withdraw(address projectToken, address lendingToken, uint256 projectTokenAmount) public isProjectTokenListed(projectToken) isLendingTokenListed(lendingToken) nonReentrant {
        require(!projectTokenInfo[projectToken].isWithdrawPaused, "PIT: projectToken is paused");
        require(projectTokenAmount > 0, "PIT: projectTokenAmount==0");
        DepositPosition storage _depositPosition = depositPosition[msg.sender][projectToken][lendingToken];
        if (projectTokenAmount == type(uint256).max) {
            if (borrowPosition[msg.sender][projectToken][lendingToken].loanBody > 0) {
                updateInterestInBorrowPositions(msg.sender, lendingToken);
                uint8 projectTokenDecimals = ERC20Upgradeable(projectToken).decimals();
                uint8 lendingTokenDecimals = ERC20Upgradeable(lendingToken).decimals();
                Ratio memory lvr = projectTokenInfo[projectToken].loanToValueRatio;
                uint256 depositedProjectTokenAmount = _depositPosition.depositedProjectTokenAmount;
                uint256 _totalOutstanding = totalOutstanding(msg.sender, projectToken, lendingToken);
                if (lendingTokenDecimals > decimals()) {
                    _totalOutstanding = _totalOutstanding / 10 ** (lendingTokenDecimals - decimals());
                }
                uint256 collateralProjectTokenAmount = _totalOutstanding * lvr.denominator * (10 ** projectTokenDecimals) / getProjectTokenEvaluation(projectToken, 10 ** projectTokenDecimals) / lvr.numerator;
                if (depositedProjectTokenAmount >= collateralProjectTokenAmount){
                    projectTokenAmount = depositedProjectTokenAmount - collateralProjectTokenAmount;
                } else {
                    revert("Position under liquidation");
                }
            } else {
                projectTokenAmount = _depositPosition.depositedProjectTokenAmount;
            }
        }
        require(projectTokenAmount <= _depositPosition.depositedProjectTokenAmount, "PIT: try to withdraw more than available");
        _depositPosition.depositedProjectTokenAmount -= projectTokenAmount;
        (uint256 healthFactorNumerator, uint256 healthFactorDenominator) = healthFactor(msg.sender, projectToken, lendingToken);
        if (healthFactorNumerator < healthFactorDenominator) {
            revert("PIT: withdrawable amount makes healthFactor<1");
        }
        totalDepositedProjectToken[projectToken] -= projectTokenAmount;
        ERC20Upgradeable(projectToken).safeTransfer(msg.sender, projectTokenAmount);
        emit Withdraw(msg.sender, projectToken, lendingToken, projectTokenAmount, msg.sender);
    }

    function supply(address lendingToken, uint256 lendingTokenAmount) public isLendingTokenListed(lendingToken) {
        require(!lendingTokenInfo[lendingToken].isPaused, "PIT: lending token is paused");
        require(lendingTokenAmount > 0, "PIT: lendingTokenAmount==0");

        (uint256 mintError, uint256 mintedAmount) = lendingTokenInfo[lendingToken].bLendingToken.mintTo(msg.sender, lendingTokenAmount);
        require(mintError == 0,"PIT: mintError!=0");
        require(mintedAmount > 0, "PIT: mintedAmount==0");

        emit Supply(msg.sender, lendingToken, lendingTokenAmount, address(lendingTokenInfo[lendingToken].bLendingToken), mintedAmount);
    }

    function redeem(address lendingToken, uint256 bLendingTokenAmount) public isLendingTokenListed(lendingToken) {
        require(!lendingTokenInfo[lendingToken].isPaused, "PIT: lending token is paused");
        require(bLendingTokenAmount > 0, "PIT: bLendingTokenAmount==0");

        uint256 redeemError = lendingTokenInfo[lendingToken].bLendingToken.redeemTo(msg.sender, bLendingTokenAmount);
        require(redeemError == 0,"PIT: redeemError!=0. redeem>=supply.");

        emit Redeem(msg.sender, lendingToken, address(lendingTokenInfo[lendingToken].bLendingToken), bLendingTokenAmount);
    }

    function redeemUnderlying(address lendingToken, uint256 lendingTokenAmount) public isLendingTokenListed(lendingToken) {
        require(!lendingTokenInfo[lendingToken].isPaused, "PIT: lending token is paused");
        require(lendingTokenAmount > 0, "PIT: lendingTokenAmount==0");

        uint256 redeemUnderlyingError = lendingTokenInfo[lendingToken].bLendingToken.redeemUnderlyingTo(msg.sender, lendingTokenAmount);
        require(redeemUnderlyingError == 0,"PIT:redeem>=supply");

        emit RedeemUnderlying(msg.sender, lendingToken, address(lendingTokenInfo[lendingToken].bLendingToken), lendingTokenAmount);
    }

    function borrow(address projectToken, address lendingToken, uint256 lendingTokenAmount) public isProjectTokenListed(projectToken) isLendingTokenListed(lendingToken) {        
        updateInterestInBorrowPositions(msg.sender, lendingToken);
        if (lendingTokenAmount == type(uint256).max) {
            lendingTokenAmount = pitRemaining(msg.sender, projectToken, lendingToken);
        }
        require(lendingTokenAmount <= pitRemaining(msg.sender, projectToken, lendingToken), "PIT: lendingTokenAmount exceeds pitRemaining");
        require(totalBorrow[projectToken][lendingToken] + lendingTokenAmount <= borrowLimit[projectToken][lendingToken], "PIT: totalBorrow exceeded borrowLimit");
        BorrowPosition storage _borrowPosition = borrowPosition[msg.sender][projectToken][lendingToken];
        LendingTokenInfo memory info = lendingTokenInfo[lendingToken];
        if (_borrowPosition.loanBody == 0) {
            info.bLendingToken.borrowTo(msg.sender, lendingTokenAmount);
            _borrowPosition.loanBody += lendingTokenAmount;
            totalBorrow[projectToken][lendingToken] += lendingTokenAmount;
        } else {
            info.bLendingToken.borrowTo(msg.sender, lendingTokenAmount);
            _borrowPosition.loanBody += lendingTokenAmount;
            totalBorrow[projectToken][lendingToken] += lendingTokenAmount;
        }
        emit Borrow(msg.sender, lendingToken, lendingTokenAmount, projectToken, depositPosition[msg.sender][projectToken][lendingToken].depositedProjectTokenAmount);
    }
    
    function repay(address projectToken, address lendingToken, uint256 lendingTokenAmount) public isProjectTokenListed(projectToken) isLendingTokenListed(lendingToken) returns (uint256) {
        require(lendingTokenAmount > 0, "PIT: lendingTokenAmount==0");
        return repayInternal(msg.sender, msg.sender, projectToken, lendingToken, lendingTokenAmount);
    }

    function repayInternal(address repairer, address borrower, address projectToken, address lendingToken, uint256 lendingTokenAmount) internal returns (uint256) {
        uint256 borrowPositionsAmount = 0;
        for(uint256 i = 0; i < projectTokens.length; i++) { 
            if (borrowPosition[borrower][projectTokens[i]][lendingToken].loanBody > 0) {
                borrowPositionsAmount++;
            }
        }
        BorrowPosition storage _borrowPosition = borrowPosition[borrower][projectToken][lendingToken];
        if (borrowPositionsAmount == 0 || _borrowPosition.loanBody == 0) {
            revert("PIT: no borrow position");
        }
        LendingTokenInfo memory info = lendingTokenInfo[lendingToken];
        updateInterestInBorrowPositions(borrower, lendingToken);
        uint256 amountRepaid;
        bool isPositionFullyRepaid;
        uint256 _totalOutstanding = totalOutstanding(borrower, projectToken, lendingToken);        
        if (borrowPositionsAmount == 1) {
            if (lendingTokenAmount > info.bLendingToken.borrowBalanceStored(borrower) || 
                lendingTokenAmount >= _totalOutstanding || 
                lendingTokenAmount == type(uint256).max) {
                (, amountRepaid) = info.bLendingToken.repayTo(repairer, borrower, type(uint256).max);
                totalBorrow[projectToken][lendingToken] -= _borrowPosition.loanBody;
                _borrowPosition.loanBody = 0;
                _borrowPosition.accrual = 0;
                isPositionFullyRepaid = true;
            } else {
                uint256 lendingTokenAmountToRepay = lendingTokenAmount;
                (, amountRepaid) = info.bLendingToken.repayTo(repairer, borrower,  lendingTokenAmountToRepay);
                if (lendingTokenAmountToRepay > _borrowPosition.accrual) {
                    lendingTokenAmountToRepay -= _borrowPosition.accrual;
                    _borrowPosition.accrual = 0;
                    totalBorrow[projectToken][lendingToken] -= lendingTokenAmountToRepay;
                    _borrowPosition.loanBody -= lendingTokenAmountToRepay;
                } else {
                    _borrowPosition.accrual -= lendingTokenAmountToRepay;
                }
                isPositionFullyRepaid = false;
            }
        } else {
            if (lendingTokenAmount >= _totalOutstanding || lendingTokenAmount == type(uint256).max) {
                (, amountRepaid) = info.bLendingToken.repayTo(repairer, borrower, _totalOutstanding);
                totalBorrow[projectToken][lendingToken] -= _borrowPosition.loanBody;
                _borrowPosition.loanBody = 0;
                _borrowPosition.accrual = 0;
                isPositionFullyRepaid = true;
            } else {
                uint256 lendingTokenAmountToRepay = lendingTokenAmount;
                (, amountRepaid) = info.bLendingToken.repayTo(repairer, borrower, lendingTokenAmountToRepay);
                if(lendingTokenAmountToRepay > _borrowPosition.accrual){
                    lendingTokenAmountToRepay -= _borrowPosition.accrual;
                    _borrowPosition.accrual = 0;
                    totalBorrow[projectToken][lendingToken] -= lendingTokenAmountToRepay;
                    _borrowPosition.loanBody -= lendingTokenAmountToRepay;
                } else {
                    _borrowPosition.accrual -= lendingTokenAmountToRepay;
                }
                isPositionFullyRepaid = false;
            }
        }

        emit RepayBorrow(repairer, lendingToken, amountRepaid, projectToken, isPositionFullyRepaid);
        return amountRepaid;
    }

    function liquidate(address account, address projectToken, address lendingToken) public isProjectTokenListed(projectToken) isLendingTokenListed(lendingToken) {
        //liquidation v3.0
        //require(!projectTokenInfo[projectToken].isPaused, "PIT: projectToken is paused");
        updateInterestInBorrowPositions(account, lendingToken);
        (uint256 healthFactorNumerator, uint256 healthFactorDenominator) = healthFactor(account, projectToken, lendingToken);
        if(healthFactorNumerator >= healthFactorDenominator){ 
            revert("PIT: healthFactor>=1");
        }
        ProjectTokenInfo memory info = projectTokenInfo[projectToken];
        uint256 projectTokenMultiplier = 10 ** ERC20Upgradeable(projectToken).decimals();
        uint256 repaid = repayInternal(msg.sender, account, projectToken, lendingToken, type(uint256).max);
        uint256 projectTokenEvaluation = repaid * projectTokenMultiplier / getProjectTokenEvaluation(projectToken, projectTokenMultiplier);
        uint256 projectTokenToSendToLiquidator = projectTokenEvaluation * info.liquidationIncentive.numerator / info.liquidationIncentive.denominator;
        
        uint256 depositedProjectTokenAmount = depositPosition[account][projectToken][lendingToken].depositedProjectTokenAmount;
        if(projectTokenToSendToLiquidator > depositedProjectTokenAmount){
            projectTokenToSendToLiquidator = depositedProjectTokenAmount;
        }

        depositPosition[account][projectToken][lendingToken].depositedProjectTokenAmount -= projectTokenToSendToLiquidator;
        totalDepositedProjectToken[projectToken] -= projectTokenToSendToLiquidator;
        ERC20Upgradeable(projectToken).safeTransfer(msg.sender, projectTokenToSendToLiquidator);
        emit Liquidate(msg.sender, account, lendingToken, projectToken, projectTokenToSendToLiquidator);
    }

    function updateInterestInBorrowPositions(address account, address lendingToken) public {
        uint256 cumulativeLoanBody = 0;
        uint256 cumulativeTotalOutstanding = 0;
        for(uint256 i = 0; i < projectTokens.length; i++) {
            BorrowPosition memory _borrowPosition = borrowPosition[account][projectTokens[i]][lendingToken];
            cumulativeLoanBody += _borrowPosition.loanBody;
            cumulativeTotalOutstanding += _borrowPosition.loanBody + _borrowPosition.accrual;
        }
        if (cumulativeLoanBody == 0) {
            return;
        }
        uint256 currentBorrowBalance = lendingTokenInfo[lendingToken].bLendingToken.borrowBalanceCurrent(account);
        if (currentBorrowBalance >= cumulativeTotalOutstanding){
            uint256 estimatedAccrual = currentBorrowBalance - cumulativeTotalOutstanding;
            BorrowPosition storage _borrowPosition;
            for(uint i = 0; i < projectTokens.length; i++) {
                _borrowPosition = borrowPosition[account][projectTokens[i]][lendingToken];
                _borrowPosition.accrual += estimatedAccrual * _borrowPosition.loanBody / cumulativeLoanBody;
            }
        }
    }

    //************* VIEW FUNCTIONS ********************************

    function pit(address account, address projectToken, address lendingToken) public view returns (uint256) {
        uint8 lvrNumerator = projectTokenInfo[projectToken].loanToValueRatio.numerator;
        uint8 lvrDenominator = projectTokenInfo[projectToken].loanToValueRatio.denominator;
        uint256 evaluation = getProjectTokenEvaluation(projectToken, depositPosition[account][projectToken][lendingToken].depositedProjectTokenAmount);
        return evaluation * lvrNumerator / lvrDenominator;
    }

    function pitRemaining(address account, address projectToken, address lendingToken) public view returns (uint256) {
        uint256 _pit = pit(account, projectToken, lendingToken);
        uint256 _totalOutstanding = totalOutstanding(account, projectToken, lendingToken);
        if (_pit >= _totalOutstanding) {
            return _pit - _totalOutstanding;
        } else {
            return 0;
        }
    }

    function liquidationThreshold(address account, address projectToken, address lendingToken) public view returns (uint256) {
        ProjectTokenInfo memory info = projectTokenInfo[projectToken];   
        uint256 liquidationThresholdFactorNumerator = info.liquidationThresholdFactor.numerator;
        uint256 liquidationThresholdFactorDenominator = info.liquidationThresholdFactor.denominator;
        uint256 _totalOutstanding = totalOutstanding(account, projectToken, lendingToken);
        return _totalOutstanding * liquidationThresholdFactorNumerator / liquidationThresholdFactorDenominator;
    }

    function totalOutstanding(address account, address projectToken, address lendingToken) public view returns (uint256) {
        BorrowPosition memory _borrowPosition = borrowPosition[account][projectToken][lendingToken];
        return _borrowPosition.loanBody + _borrowPosition.accrual;
    }

    function healthFactor(address account, address projectToken, address lendingToken) public view returns (uint256 numerator, uint256 denominator) {
        numerator = pit(account, projectToken, lendingToken);
        uint8 lendingTokenDecimals = ERC20Upgradeable(lendingToken).decimals();
        denominator = totalOutstanding(account, projectToken, lendingToken) / (10 ** (lendingTokenDecimals - decimals()));
    }

    function getProjectTokenEvaluation(address projectToken, uint256 projectTokenAmount) public view returns (uint256) {
        return priceOracle.getEvaluation(projectToken, projectTokenAmount);
    }

    function lendingTokensLength() public view returns (uint256) {
        return lendingTokens.length;
    }

    function projectTokensLength() public view returns (uint256) {
        return projectTokens.length;
    }

    function getPosition(address account, address projectToken, address lendingToken) public view returns (uint256 depositedProjectTokenAmount, uint256 loanBody, uint256 accrual, uint256 healthFactorNumerator, uint256 healthFactorDenominator) {
        depositedProjectTokenAmount = depositPosition[account][projectToken][lendingToken].depositedProjectTokenAmount;
        loanBody = borrowPosition[account][projectToken][lendingToken].loanBody;
        uint256 cumulativeTotalOutstanding = 0;
        uint256 cumulativeLoanBody = 0;
        for(uint256 i = 0; i < projectTokens.length; i++) {
            cumulativeLoanBody += borrowPosition[account][projectTokens[i]][lendingToken].loanBody;
            cumulativeTotalOutstanding += totalOutstanding(account, projectTokens[i], lendingToken);

        }
        uint256 estimatedBorrowBalance = lendingTokenInfo[lendingToken].bLendingToken.getEstimatedBorrowBalanceStored(account);
        accrual = borrowPosition[account][projectToken][lendingToken].accrual;
        if (estimatedBorrowBalance >= cumulativeTotalOutstanding && cumulativeLoanBody > 0) {
            accrual += loanBody * (estimatedBorrowBalance - cumulativeTotalOutstanding) / cumulativeLoanBody;
        }
        healthFactorNumerator = pit(account, projectToken, lendingToken);
        healthFactorDenominator = loanBody + accrual;
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }
}
