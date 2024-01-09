// SPDX-License-Identifier: MIT
/**
 * Created on 2021-02-11
 * @summary: Jibrel Aave Tranche Protocol
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;
// pragma experimental ABIEncoderV2; // needed for getAllAtokens and getAllReservesTokens

import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IAaveProtocolDataProvider.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./TransferETHHelper.sol";
import "./IJAdminTools.sol";
import "./IJTrancheTokens.sol";
import "./IJTranchesDeployer.sol";
import "./JAaveStorage.sol";
import "./IJAave.sol";
import "./TokenInterface.sol";
import "./IWETHGateway.sol";
import "./IAaveIncentivesController.sol";
import "./IIncentivesController.sol";


contract JAave is OwnableUpgradeable, ReentrancyGuardUpgradeable, JAaveStorageV2, IJAave {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev contract initializer
     * @param _adminTools price oracle address
     * @param _feesCollector fees collector contract address
     * @param _tranchesDepl tranches deployer contract address
     * @param _aaveIncentiveController Aave incentive controller address (mainnet: 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5)
     * @param _wethAddress weth / wmatic / wavax contract address
     * @param _blocksPerYear blocks / year or seconds in a year
     */
    function initialize(address _adminTools, 
            address _feesCollector, 
            address _tranchesDepl,
            address _aaveIncentiveController,
            address _wethAddress,
            uint256 _blocksPerYear) external initializer() {
        OwnableUpgradeable.__Ownable_init();
        adminToolsAddress = _adminTools;
        feesCollectorAddress = _feesCollector;
        tranchesDeployerAddress = _tranchesDepl;
        aaveIncentiveControllerAddress = _aaveIncentiveController;
        redeemTimeout = 3; //default
        wrappedEthAddress = _wethAddress;
        totalBlocksPerYear = _blocksPerYear;
    }

    /**
     * @dev admins modifiers
     */
    modifier onlyAdmins() {
        require(IJAdminTools(adminToolsAddress).isAdmin(msg.sender), "JAave: not an Admin");
        _;
    }

    fallback() external payable {}
    receive() external payable {}

    /**
     * @dev set new addresses for price oracle, fees collector and tranche deployer 
     * @param _adminTools price oracle address
     * @param _feesCollector fees collector contract address
     * @param _tranchesDepl tranches deployer contract address
     * @param _aaveIncentiveController Aave incentive controller address
     * @param _wethAddress weth / wmatic / wavax contract address
     */
    function setNewEnvironment(address _adminTools, 
            address _feesCollector, 
            address _tranchesDepl,
            address _aaveIncentiveController,
            address _wethAddress) external onlyOwner{
        require((_adminTools != address(0)) && (_feesCollector != address(0)) && (_tranchesDepl != address(0)), "JAave: check addresses");
        adminToolsAddress = _adminTools;
        feesCollectorAddress = _feesCollector;
        tranchesDeployerAddress = _tranchesDepl;
        aaveIncentiveControllerAddress = _aaveIncentiveController;
        wrappedEthAddress = _wethAddress;
    }

    /**
     * @dev set incentive rewards address
     * @param _incentivesController incentives controller contract address
     */
    function setIncentivesControllerAddress(address _incentivesController) external override onlyAdmins {
        incentivesControllerAddress = _incentivesController;
    }

    /**
     * @dev get incentive rewards address
     */
    function getIncentivesControllerAddress() external view override returns (address) {
        return incentivesControllerAddress;
    }

    /**
     * @dev set how many blocks will be produced per year on the blockchain 
     * @param _newValue new value
     */
    function setBlocksPerYear(uint256 _newValue) external onlyAdmins {
        require(_newValue > 0, "JAave: new value not allowed");
        totalBlocksPerYear = _newValue;
    }

    /**
     * @dev set Aave Pool Address Provider
     * @param _addressProviderContract aave lending pool address provider contract address
     */
    function setAavePoolAddressProvider(address _addressProviderContract) external onlyAdmins {
        lendingPoolAddressProvider = _addressProviderContract;
    }

    /**
     * @dev set Aave Pool Address Provider
     * @param _aaveIncentiveController aave incentive controller address
     */
    function setAaveIncentiveControllerAddress(address _aaveIncentiveController) external onlyAdmins {
        aaveIncentiveControllerAddress = _aaveIncentiveController;
    }

    /**
     * @dev get Aave Pool Address Provider starting from lending pool address provider
     */
    function getDataProvider() public view returns(IAaveProtocolDataProvider) {
        require(lendingPoolAddressProvider != address(0), "JAave: set lending pool address provider");
        return IAaveProtocolDataProvider(ILendingPoolAddressesProvider(lendingPoolAddressProvider)
                    .getAddress(0x0100000000000000000000000000000000000000000000000000000000000000));
    }

    /**
     * @dev get Aave all tokens
     */
    function getAllATokens() external view returns(IAaveProtocolDataProvider.TokenData[] memory) {
        require(lendingPoolAddressProvider != address(0), "JAave: set lending pool address provider");
        IAaveProtocolDataProvider aaveProtocolDataProvider = getDataProvider();
        return aaveProtocolDataProvider.getAllATokens();
    }

    /**
     * @dev get Aave all reserved tokens
     */
    function getAllReservesTokens() external view returns(IAaveProtocolDataProvider.TokenData[] memory) {
        require(lendingPoolAddressProvider != address(0), "JAave: set lending pool address provider");
        IAaveProtocolDataProvider aaveProtocolDataProvider = getDataProvider();
        return aaveProtocolDataProvider.getAllReservesTokens();
    }

    /**
     * @dev get Aave reserve Data for an asset
     * liquidityRate is the return percentage for that asset (multiply by 10^27)
     */
    function getAaveReserveData(uint256 _trancheNum) external view returns(uint256 availableLiquidity, uint256 totalStableDebt,
            uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate,
            uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp) {
        require(lendingPoolAddressProvider != address(0), "JAave: set lending pool address provider");
        IAaveProtocolDataProvider aaveProtocolDataProvider = getDataProvider();
        address asset = trancheAddresses[_trancheNum].buyerCoinAddress;
        if (asset == ETH_ADDR)
            asset = wrappedEthAddress;
        return aaveProtocolDataProvider.getReserveData(asset);
    }

    function getLendingPool() external view returns (address) {
        return ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();
    }

    function changeToWeth(address _token) private view returns(address) {
        if (_token == ETH_ADDR) {
            return wrappedEthAddress;
        }
        return _token;
    }

    /**
     * @dev set Weth Gateway contract address
     * @param _wethGatewayAddress weth gateway contract address
     */
    function setWETHGatewayAddress(address _wethGatewayAddress) external onlyAdmins {
        wethGatewayAddress = _wethGatewayAddress;
    }

    /** 
     * @dev User withdraws tokens from the Aave protocol
     * @param _tokenAddr The address of the token to be withdrawn
     * @param _amount Amount of tokens to be withdrawn
     * @param _to receiver address
     */ 
    function aaveWithdraw(address _tokenAddr, uint256 _amount, address _to) internal {
        address lendingPool = ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();
        _tokenAddr = changeToWeth(_tokenAddr);

        uint256 oldBalance;
        uint256 newBalance;
        if (_tokenAddr == wrappedEthAddress) {
            // get eth balance
            oldBalance = getEthBalance();
            // if weth, pull to proxy and return ETH to user
            ILendingPool(lendingPool).withdraw(_tokenAddr, _amount, address(this));
            // from Weth to Eth, all the Weth balance --> no Weth in contract
            uint256 wethBal = IERC20Upgradeable(wrappedEthAddress).balanceOf(address(this));
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(wrappedEthAddress), wethGatewayAddress, wethBal);
            IWETHGateway(wethGatewayAddress).withdrawETH(wethBal);
            // get new eth balance
            newBalance = getEthBalance();
            if (newBalance > oldBalance)
                TransferETHHelper.safeTransferETH(_to, _amount);
        } else {
            // if not eth send directly to user
            ILendingPool(lendingPool).withdraw(_tokenAddr, _amount, _to);
        }
    }

    /**
     * @dev set decimals on the underlying token of a tranche
     * @param _trancheNum tranche number
     * @param _underlyingDec underlying token decimals
     */
    function setDecimals(uint256 _trancheNum, uint8 _underlyingDec) external onlyAdmins {
        require(_underlyingDec <= 18, "JAave: too many decimals");
        trancheParameters[_trancheNum].underlyingDecimals = _underlyingDec;
    }

    /**
     * @dev set tranche redemption percentage
     * @param _trancheNum tranche number
     * @param _redeemPercent user redemption percent
     */
    function setTrancheRedemptionPercentage(uint256 _trancheNum, uint16 _redeemPercent) external onlyAdmins {
        trancheParameters[_trancheNum].redemptionPercentage = _redeemPercent;
    }

    /**
     * @dev set redemption timeout
     * @param _blockNum timeout (in block numbers)
     */
    function setRedemptionTimeout(uint32 _blockNum) external onlyAdmins {
        redeemTimeout = _blockNum;
    }

    /**
     * @dev set tranche redemption percentage scaled by 1e18
     * @param _trancheNum tranche number
     * @param _newTrAPercentage new tranche A RPB
     */
    function setTrancheAFixedPercentage(uint256 _trancheNum, uint256 _newTrAPercentage) external onlyAdmins {
        trancheParameters[_trancheNum].trancheAFixedPercentage = _newTrAPercentage;
        trancheParameters[_trancheNum].storedTrancheAPrice = setTrancheAExchangeRate(_trancheNum);
    }

    function addTrancheToProtocol(address _buyerCoinAddress, 
            address _aTokenAddress, 
            string memory _nameA, 
            string memory _symbolA, 
            string memory _nameB, 
            string memory _symbolB, 
            uint256 _fixedRpb, 
            uint8 _underlyingDec) external onlyAdmins nonReentrant {
        require(tranchesDeployerAddress != address(0), "JAave: set tranche eth deployer");
        require(lendingPoolAddressProvider != address(0), "JAave: set lending pool address provider");

        trancheAddresses[tranchePairsCounter].buyerCoinAddress = _buyerCoinAddress;
        trancheAddresses[tranchePairsCounter].aTokenAddress = _aTokenAddress;
        trancheAddresses[tranchePairsCounter].ATrancheAddress = 
                IJTranchesDeployer(tranchesDeployerAddress).deployNewTrancheATokens(_nameA, _symbolA, tranchePairsCounter);
        trancheAddresses[tranchePairsCounter].BTrancheAddress = 
                IJTranchesDeployer(tranchesDeployerAddress).deployNewTrancheBTokens(_nameB, _symbolB, tranchePairsCounter); 
        
        trancheParameters[tranchePairsCounter].underlyingDecimals = _underlyingDec;
        trancheParameters[tranchePairsCounter].trancheAFixedPercentage = _fixedRpb;
        trancheParameters[tranchePairsCounter].trancheALastActionBlock = block.timestamp;
        // if we would like to have always 18 decimals
        trancheParameters[tranchePairsCounter].storedTrancheAPrice = uint256(1e18);

        trancheParameters[tranchePairsCounter].redemptionPercentage = 10000;  //default value 100%, no fees

        calcRPBFromPercentage(tranchePairsCounter); // initialize tranche A RPB

        emit TrancheAddedToProtocol(tranchePairsCounter, trancheAddresses[tranchePairsCounter].ATrancheAddress, trancheAddresses[tranchePairsCounter].BTrancheAddress);

        tranchePairsCounter = tranchePairsCounter.add(1);
    } 

    /**
     * @dev enables or disables tranche deposit (default: disabled)
     * @param _trancheNum tranche number
     * @param _enable true or false
     */
    function setTrancheDeposit(uint256 _trancheNum, bool _enable) external onlyAdmins {
        trancheDepositEnabled[_trancheNum] = _enable;
    }
    
    /**
     * @dev set Tranche A exchange rate
     * @param _trancheNum tranche number
     * @return tranche A token current price
     */
    function setTrancheAExchangeRate(uint256 _trancheNum) internal returns (uint256) {
        calcRPBFromPercentage(_trancheNum);
        // uint256 deltaBlocks = (block.number).sub(trancheParameters[_trancheNum].trancheALastActionBlock);
        uint256 deltaTime = (block.timestamp).sub(trancheParameters[_trancheNum].trancheALastActionBlock);
        // uint256 deltaPrice = (trancheParameters[_trancheNum].trancheACurrentRPB).mul(deltaBlocks);
        uint256 deltaPrice = (trancheParameters[_trancheNum].trancheACurrentRPB).mul(deltaTime);
        trancheParameters[_trancheNum].storedTrancheAPrice = (trancheParameters[_trancheNum].storedTrancheAPrice).add(deltaPrice);
        // trancheParameters[_trancheNum].trancheALastActionBlock = block.number;
        trancheParameters[_trancheNum].trancheALastActionBlock = block.timestamp;
        return trancheParameters[_trancheNum].storedTrancheAPrice;
    }

    /**
     * @dev get Tranche A exchange rate
     * @param _trancheNum tranche number
     * @return tranche A token current price
     */
    function getTrancheAExchangeRate(uint256 _trancheNum) public view returns (uint256) {
        return trancheParameters[_trancheNum].storedTrancheAPrice;
    }

    /**
     * @dev get RPB for a given percentage (expressed in 1e18)
     * @param _trancheNum tranche number
     * @return RPB for a fixed percentage
     */
    function getTrancheACurrentRPB(uint256 _trancheNum) external view returns (uint256) {
        return trancheParameters[_trancheNum].trancheACurrentRPB;
    }

    /**
     * @dev get Tranche A exchange rate (tokens with 18 decimals)
     * @param _trancheNum tranche number
     * @return tranche A token current price
     */
    function calcRPBFromPercentage(uint256 _trancheNum) public returns (uint256) {
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        trancheParameters[_trancheNum].trancheACurrentRPB = trancheParameters[_trancheNum].storedTrancheAPrice
                        .mul(trancheParameters[_trancheNum].trancheAFixedPercentage).div(totalBlocksPerYear).div(1e18);
        return trancheParameters[_trancheNum].trancheACurrentRPB;
    }

    /**
     * @dev get Tranche A value in underlying tokens
     * @param _trancheNum tranche number
     * @return trANormValue tranche A value in underlying tokens
     */
    function getTrAValue(uint256 _trancheNum) public view returns (uint256 trANormValue) {
        uint256 totASupply = IERC20Upgradeable(trancheAddresses[_trancheNum].ATrancheAddress).totalSupply();
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        // if (diffDec > 0)
            trANormValue = totASupply.mul(getTrancheAExchangeRate(_trancheNum)).div(1e18).div(10 ** diffDec);
        // else    
        //     trANormValue = totASupply.mul(getTrancheAExchangeRate(_trancheNum)).div(1e18);
        return trANormValue;
    }

    /**
     * @dev get Tranche B value in underlying tokens
     * @param _trancheNum tranche number
     * @return tranche B value in underlying tokens
     */
    function getTrBValue(uint256 _trancheNum) public view returns (uint256) {
        uint256 totProtValue = getTotalValue(_trancheNum);
        uint256 totTrAValue = getTrAValue(_trancheNum);
        if (totProtValue > totTrAValue) {
            return totProtValue.sub(totTrAValue);
        } else
            return 0;
    }

    /**
     * @dev get Tranche total value in underlying tokens
     * @param _trancheNum tranche number
     * @return tranche total value in underlying tokens
     */
    function getTotalValue(uint256 _trancheNum) public view returns (uint256) {
        return getTokenBalance(trancheAddresses[_trancheNum].aTokenAddress);
    }

    /**
     * @dev get Tranche B exchange rate
     * @param _trancheNum tranche number
     * @param _newAmount new amount entering tranche B (underlying token decimals)
     * @return tbPrice tranche B token current price
     */
    function getTrancheBExchangeRate(uint256 _trancheNum, uint256 _newAmount) public view returns (uint256 tbPrice) {
        // set amount of tokens to be minted via taToken price
        // Current tbDai price = ((aDai-(aSupply X taPrice)) / bSupply)
        // where: aDai = How much aDai we hold in the protocol
        // aSupply = Total number of taDai in protocol
        // taPrice = taDai / Dai price
        // bSupply = Total number of tbDai in protocol
        uint256 totTrBValue;

        uint256 totBSupply = IERC20Upgradeable(trancheAddresses[_trancheNum].BTrancheAddress).totalSupply(); // 18 decimals
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        uint256 underlyingDec = uint256(trancheParameters[_trancheNum].underlyingDecimals);
        uint256 normAmount = _newAmount;
        if (underlyingDec < 18)
            normAmount = _newAmount.mul(10 ** uint256(18).sub(underlyingDec));
        uint256 newBSupply = totBSupply.add(normAmount); // 18 decimals

        uint256 totProtValue = getTotalValue(_trancheNum).add(_newAmount); //underlying token decimals
        uint256 totTrAValue = getTrAValue(_trancheNum); //underlying token decimals
        if (totProtValue >= totTrAValue)
            totTrBValue = totProtValue.sub(totTrAValue); //underlying token decimals
        else
            totTrBValue = 0;
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        if (underlyingDec < 18 && totTrBValue > 0) {
            totTrBValue = totTrBValue.mul(10 ** (uint256(18).sub(underlyingDec)));
        }

        if (totTrBValue > 0 && newBSupply > 0) {
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            tbPrice = totTrBValue.mul(1e18).div(newBSupply);
        } else
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            tbPrice = uint256(1e18);

        return tbPrice;
    }
 
    /**
     * @dev set staking details for tranche A holders, with number, amount and time
     * @param _trancheNum tranche number
     * @param _account user's account
     * @param _stkNum staking detail counter
     * @param _amount amount of tranche A tokens
     * @param _time time to be considered the deposit
     */
    function setTrAStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external override onlyAdmins {
        stakeCounterTrA[_account][_trancheNum] = _stkNum;
        StakingDetails storage details = stakingDetailsTrancheA[_account][_trancheNum][_stkNum];
        details.startTime = _time;
        details.amount = _amount;
    }

    /**
     * @dev when redemption occurs on tranche A, removing tranche A tokens from staking information (FIFO logic)
     * @param _trancheNum tranche number
     * @param _amount amount of redeemed tokens
     */
    function decreaseTrancheATokenFromStake(uint256 _trancheNum, uint256 _amount) internal {
        uint256 senderCounter = stakeCounterTrA[msg.sender][_trancheNum];
        uint256 tmpAmount = _amount;
        for (uint i = 1; i <= senderCounter; i++) {
            StakingDetails storage details = stakingDetailsTrancheA[msg.sender][_trancheNum][i];
            if (details.amount > 0) {
                if (details.amount <= tmpAmount) {
                    tmpAmount = tmpAmount.sub(details.amount);
                    details.amount = 0;
                    // delete stakingDetailsTrancheA[msg.sender][_trancheNum][i];
                    // update details number
                    // stakeCounterTrA[msg.sender][_trancheNum] = stakeCounterTrA[msg.sender][_trancheNum].sub(1);
                } else {
                    details.amount = details.amount.sub(tmpAmount);
                    tmpAmount = 0;
                }
            }
            if (tmpAmount == 0)
                break;
        }
    }

    function getSingleTrancheUserStakeCounterTrA(address _user, uint256 _trancheNum) external view override returns (uint256) {
        return stakeCounterTrA[_user][_trancheNum];
    }

    function getSingleTrancheUserSingleStakeDetailsTrA(address _user, uint256 _trancheNum, uint256 _num) external view override returns (uint256, uint256) {
        return (stakingDetailsTrancheA[_user][_trancheNum][_num].startTime, stakingDetailsTrancheA[_user][_trancheNum][_num].amount);
    }

    /**
     * @dev set staking details for tranche B holders, with number, amount and time
     * @param _trancheNum tranche number
     * @param _account user's account
     * @param _stkNum staking detail counter
     * @param _amount amount of tranche B tokens
     * @param _time time to be considered the deposit
     */
    function setTrBStakingDetails(uint256 _trancheNum, address _account, uint256 _stkNum, uint256 _amount, uint256 _time) external override onlyAdmins {
        stakeCounterTrB[_account][_trancheNum] = _stkNum;
        StakingDetails storage details = stakingDetailsTrancheB[_account][_trancheNum][_stkNum];
        details.startTime = _time;
        details.amount = _amount; 
    }
    
    /**
     * @dev when redemption occurs on tranche B, removing tranche B tokens from staking information (FIFO logic)
     * @param _trancheNum tranche number
     * @param _amount amount of redeemed tokens
     */
    function decreaseTrancheBTokenFromStake(uint256 _trancheNum, uint256 _amount) internal {
        uint256 senderCounter = stakeCounterTrB[msg.sender][_trancheNum];
        uint256 tmpAmount = _amount;
        for (uint i = 1; i <= senderCounter; i++) {
            StakingDetails storage details = stakingDetailsTrancheB[msg.sender][_trancheNum][i];
            if (details.amount > 0) {
                if (details.amount <= tmpAmount) {
                    tmpAmount = tmpAmount.sub(details.amount);
                    details.amount = 0;
                    // delete stakingDetailsTrancheB[msg.sender][_trancheNum][i];
                    // update details number
                    // stakeCounterTrB[msg.sender][_trancheNum] = stakeCounterTrB[msg.sender][_trancheNum].sub(1);
                } else {
                    details.amount = details.amount.sub(tmpAmount);
                    tmpAmount = 0;
                }
            }
            if (tmpAmount == 0)
                break;
        }
    }

    function getSingleTrancheUserStakeCounterTrB(address _user, uint256 _trancheNum) external view override returns (uint256) {
        return stakeCounterTrB[_user][_trancheNum];
    }

    function getSingleTrancheUserSingleStakeDetailsTrB(address _user, uint256 _trancheNum, uint256 _num) external view override returns (uint256, uint256) {
        return (stakingDetailsTrancheB[_user][_trancheNum][_num].startTime, stakingDetailsTrancheB[_user][_trancheNum][_num].amount);
    }

    /**
     * @dev buy Tranche A Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function buyTrancheAToken(uint256 _trancheNum, uint256 _amount) external payable nonReentrant {
        require(trancheDepositEnabled[_trancheNum], "JAave: tranche deposit disabled");
        uint256 prevAaveTokenBalance = getTokenBalance(trancheAddresses[_trancheNum].aTokenAddress);
        address lendingPool = ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();
        address _tokenAddr = trancheAddresses[_trancheNum].buyerCoinAddress;
        if (_tokenAddr == ETH_ADDR) {
            require(msg.value == _amount, "JAave: msg.value not equal to amount");
            IWETHGateway(wethGatewayAddress).depositETH{value: msg.value}();
            _tokenAddr = wrappedEthAddress;
        } else {
            // check approve
            require(IERC20Upgradeable(_tokenAddr).allowance(msg.sender, address(this)) >= _amount, "JAave: allowance failed buying tranche A");
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_tokenAddr), msg.sender, address(this), _amount);
        }

        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_tokenAddr), lendingPool, _amount);
        ILendingPool(lendingPool).deposit(_tokenAddr, _amount, address(this), AAVE_REFERRAL_CODE);
        
        uint256 newAaveTokenBalance = getTokenBalance(trancheAddresses[_trancheNum].aTokenAddress);
        setTrancheAExchangeRate(_trancheNum);
        uint256 taAmount;
        if (newAaveTokenBalance > prevAaveTokenBalance) {
            // set amount of tokens to be minted calculate taToken amount via taToken price
            // if normalized price in tranche A price, everything should be scaled to 1e18 
            uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
            uint256 normAmount = _amount.mul(10 ** diffDec);
            taAmount = normAmount.mul(1e18).div(trancheParameters[_trancheNum].storedTrancheAPrice);
            //Mint trancheA tokens and send them to msg.sender and notify to incentive controller BEFORE totalSupply updates
            IIncentivesController(incentivesControllerAddress).trancheANewEnter(msg.sender, trancheAddresses[_trancheNum].ATrancheAddress);
            IJTrancheTokens(trancheAddresses[_trancheNum].ATrancheAddress).mint(msg.sender, taAmount);
        }

        stakeCounterTrA[msg.sender][_trancheNum] = stakeCounterTrA[msg.sender][_trancheNum].add(1);
        StakingDetails storage details = stakingDetailsTrancheA[msg.sender][_trancheNum][stakeCounterTrA[msg.sender][_trancheNum]];
        details.startTime = block.timestamp;
        details.amount = taAmount;

        lastActivity[msg.sender] = block.number;
        emit TrancheATokenMinted(_trancheNum, msg.sender, _amount, taAmount);
    }

    /**
     * @dev redeem Tranche A Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function redeemTrancheAToken(uint256 _trancheNum, uint256 _amount) external nonReentrant {
        require((block.number).sub(lastActivity[msg.sender]) >= redeemTimeout, "JAave: redeem timeout not expired on tranche A");
        // check approve
        require(IERC20Upgradeable(trancheAddresses[_trancheNum].ATrancheAddress).allowance(msg.sender, address(this)) >= _amount, "JAave: allowance failed redeeming tranche A");
        //Transfer DAI from msg.sender to protocol;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(trancheAddresses[_trancheNum].ATrancheAddress), msg.sender, address(this), _amount);

        setTrancheAExchangeRate(_trancheNum);

        uint256 taAmount = _amount.mul(trancheParameters[_trancheNum].storedTrancheAPrice).div(1e18);
        // if normalized price in tranche A price, everything should be scaled to 1e18 
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = taAmount.div(10 ** diffDec);
        // not sure about this, but it should be checked
        uint256 taTotAmount = getTrAValue(_trancheNum);
        if (normAmount > taTotAmount)
            normAmount = taTotAmount;

        uint256 userAmount = normAmount.mul(trancheParameters[_trancheNum].redemptionPercentage).div(PERCENT_DIVIDER);
        aaveWithdraw(trancheAddresses[_trancheNum].buyerCoinAddress, userAmount, msg.sender);
        uint256 feesAmount = normAmount.sub(userAmount);
        if (feesAmount > 0)
            aaveWithdraw(trancheAddresses[_trancheNum].buyerCoinAddress, feesAmount, feesCollectorAddress);
        
        // claim and transfer rewards to msg.sender. Be sure to wait for this function to be completed! 
        bool rewClaimCompleted = IIncentivesController(incentivesControllerAddress).claimRewardsAllMarkets(msg.sender);

        // decrease tokens after claiming rewards
        if (rewClaimCompleted && _amount > 0)
            decreaseTrancheATokenFromStake(_trancheNum, _amount);

        IJTrancheTokens(trancheAddresses[_trancheNum].ATrancheAddress).burn(_amount);
        lastActivity[msg.sender] = block.number;
        emit TrancheATokenRedemption(_trancheNum, msg.sender, _amount, userAmount, feesAmount);
    }

    /**
     * @dev buy Tranche B Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function buyTrancheBToken(uint256 _trancheNum, uint256 _amount) external payable nonReentrant {
        require(trancheDepositEnabled[_trancheNum], "JAave: tranche deposit disabled");
        // refresh value for tranche A
        setTrancheAExchangeRate(_trancheNum);
        // get tranche B exchange rate
        // if normalized price in tranche B price, everything should be scaled to 1e18 
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = _amount.mul(10 ** diffDec);
        uint256 tbAmount = normAmount.mul(1e18).div(getTrancheBExchangeRate(_trancheNum, _amount));
        uint256 prevAaveTokenBalance = getTokenBalance(trancheAddresses[_trancheNum].aTokenAddress);
        address lendingPool = ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();
        address _tokenAddr = trancheAddresses[_trancheNum].buyerCoinAddress;
        if (_tokenAddr == ETH_ADDR) {
            require(msg.value == _amount, "JAave: msg.value not equal to amount");
            IWETHGateway(wethGatewayAddress).depositETH{value: msg.value}();
            _tokenAddr = wrappedEthAddress;
        } else {
            // check approve
            require(IERC20Upgradeable(_tokenAddr).allowance(msg.sender, address(this)) >= _amount, "JAave: allowance failed buying tranche B");
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_tokenAddr), msg.sender, address(this), _amount);
        }

        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_tokenAddr), lendingPool, _amount);
        ILendingPool(lendingPool).deposit(_tokenAddr, _amount, address(this), AAVE_REFERRAL_CODE);

        uint256 newAaveTokenBalance = getTokenBalance(trancheAddresses[_trancheNum].aTokenAddress);
        if (newAaveTokenBalance > prevAaveTokenBalance) {
            //Mint trancheB tokens and send them to msg.sender and notify to incentive controller BEFORE totalSupply updates
            IIncentivesController(incentivesControllerAddress).trancheBNewEnter(msg.sender, trancheAddresses[_trancheNum].BTrancheAddress);
            IJTrancheTokens(trancheAddresses[_trancheNum].BTrancheAddress).mint(msg.sender, tbAmount);
        } else 
            tbAmount = 0;

        stakeCounterTrB[msg.sender][_trancheNum] = stakeCounterTrB[msg.sender][_trancheNum].add(1);
        StakingDetails storage details = stakingDetailsTrancheB[msg.sender][_trancheNum][stakeCounterTrB[msg.sender][_trancheNum]];
        details.startTime = block.timestamp;
        details.amount = tbAmount; 

        lastActivity[msg.sender] = block.number;
        emit TrancheBTokenMinted(_trancheNum, msg.sender, _amount, tbAmount);
    }

    /**
     * @dev redeem Tranche B Tokens
     * @param _trancheNum tranche number
     * @param _amount amount of stable coins sent by buyer
     */
    function redeemTrancheBToken(uint256 _trancheNum, uint256 _amount) external nonReentrant {
        require((block.number).sub(lastActivity[msg.sender]) >= redeemTimeout, "JAave: redeem timeout not expired on tranche B");
        // check approve
        require(IERC20Upgradeable(trancheAddresses[_trancheNum].BTrancheAddress).allowance(msg.sender, address(this)) >= _amount, "JAave: allowance failed redeeming tranche B");
        //Transfer DAI from msg.sender to protocol;
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(trancheAddresses[_trancheNum].BTrancheAddress), msg.sender, address(this), _amount);

        // update tranche A price
        setTrancheAExchangeRate(_trancheNum);
        // get tranche B exchange rate
        uint256 tbAmount = _amount.mul(getTrancheBExchangeRate(_trancheNum, 0)).div(1e18);
        uint256 diffDec = uint256(18).sub(uint256(trancheParameters[_trancheNum].underlyingDecimals));
        uint256 normAmount = tbAmount.div(10 ** diffDec);
        // not sure about this, but it should be checked
        uint256 tbTotAmount = getTrBValue(_trancheNum);
        if (normAmount > tbTotAmount)
            normAmount = tbTotAmount;

        uint256 userAmount = normAmount.mul(trancheParameters[_trancheNum].redemptionPercentage).div(PERCENT_DIVIDER);
        aaveWithdraw(trancheAddresses[_trancheNum].buyerCoinAddress, userAmount, msg.sender);
        uint256 feesAmount = normAmount.sub(userAmount);
        if (feesAmount > 0)
            aaveWithdraw(trancheAddresses[_trancheNum].buyerCoinAddress, feesAmount, feesCollectorAddress);

        // claim and transfer rewards to msg.sender. Be sure to wait for this function to be completed! 
        bool rewClaimCompleted = IIncentivesController(incentivesControllerAddress).claimRewardsAllMarkets(msg.sender);

        // decrease tokens after claiming rewards
        if (rewClaimCompleted && _amount > 0)
            decreaseTrancheBTokenFromStake(_trancheNum, _amount);

        IJTrancheTokens(trancheAddresses[_trancheNum].BTrancheAddress).burn(_amount);
        lastActivity[msg.sender] = block.number;
        emit TrancheBTokenRedemption(_trancheNum, msg.sender, _amount, userAmount, feesAmount);
    }

    /**
     * @dev get every token balance in this contract
     * @param _tokenContract token contract address
     */
    function getTokenBalance(address _tokenContract) public view returns (uint256) {
        return IERC20Upgradeable(_tokenContract).balanceOf(address(this));
    }

    /**
     * @dev get eth balance on this contract
     */
    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev transfer tokens in this contract to fees collector contract
     * @param _tokenContract token contract address
     * @param _amount token amount to be transferred 
     */
    function transferTokenToFeesCollector(address _tokenContract, uint256 _amount) external onlyAdmins {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_tokenContract), feesCollectorAddress, _amount);
    }

    /**
     * @dev transfer ethers in this contract to fees collector contract
     * @param _amount ethers amount to be transferred 
     */
    function withdrawEthToFeesCollector(uint256 _amount) external onlyAdmins {
        TransferETHHelper.safeTransferETH(feesCollectorAddress, _amount);
    }

    /**
     * @dev get token rewards amount
     * @return amount of unclaimed tokens
     */
    function getAaveUnclaimedRewards() public view returns(uint256) {
        return IAaveIncentivesController(aaveIncentiveControllerAddress).getUserUnclaimedRewards(address(this));
    }

    /**
     * @dev claim token rewards from all assets in protocol and transfer them to fees collector
     */
    function claimAaveRewards(/*address _rewardToken, uint256 _amount*/) external {
        address[] memory assets = new address[](tranchePairsCounter);
        for (uint256 i = 0; i < tranchePairsCounter; i++) {
            assets[i] = trancheAddresses[i].aTokenAddress;
        }

        uint256 claimableRewards = getAaveUnclaimedRewards();
        if (claimableRewards > 0)
            IAaveIncentivesController(aaveIncentiveControllerAddress).claimRewards(assets, claimableRewards, feesCollectorAddress);
    }

    /**
     * @dev claim token rewards from a single assets (aToken) and transfer them to fees collector
     * @param _assetToken asset token address (aToken)
     * @param _amount amount of rewards token to claim 
     */
    function claimAaveRewardsSingleAsset(address _assetToken, uint256 _amount) external {
        address[] memory assets = new address[](1);
        assets[0] = _assetToken;
        if (_amount > 0)
            IAaveIncentivesController(aaveIncentiveControllerAddress).claimRewards(assets, _amount, feesCollectorAddress);
    }

}