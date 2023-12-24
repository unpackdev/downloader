// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================== IncentivizingLiquidityAMO =======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett

import "./IFrax.sol";
import "./IFxs.sol";
import "./IIncentivizationHandler.sol";
import "./TransferHelper.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract IncentivizingLiquidityAmo is Ownable {
    /* ============================================= STATE VARIABLES ==================================================== */

    // Addresses Config
    address public operatorAddress;
    address public targetTokenAddress; // Token that AMO incentivize
    address public incentiveTokenAddress; // Token that AMO uses as an incentive
    

    // Pools related
    address[] public poolArray;
    struct LiquidityPool {
        // Pool Addresses
        address poolAddress; // Where the actual tokens are in the pool
        address incentivePoolAddress; // Contract that handle incentive distribution e.g. Bribe contract
        address incentivizationHandlerAddress; // Incentive handler contract e.g. votemarket handler
        address gaugeAddress; // Gauge address
        uint256 incentivizationId; // Votemarket Bounty ID
        bool isPaused;
        uint lastIncentivizationTimestamp; // timestamp of last time this pool was incentivized
        uint lastIncentivizationAmount; // Max amount of incentives
    }
    mapping(address => bool) public poolInitialized;
    mapping(address => LiquidityPool) private poolInfo;

    // Constant Incentivization can be set (e.g. DAO Deal)
    mapping(address => bool) public poolHasFixedIncent; 
    mapping(address => uint256) public poolFixedIncentAmount; // Constant Incentivization amount

    // Configurations
    uint256 public minTvl; // Min TVL of pool for being considered for incentivization

    /* =============================================== CONSTRUCTOR ====================================================== */

    /// @notice constructor
    /// @param _operatorAddress Address of AMO Operator
    /// @param _targetTokenAddress Address of Token that AMO incentivize (e.g. crvFRAX)
    /// @param _incentiveTokenAddress Address of Token that AMO uses as an incentive (e.g. FXS)
    /// @param _minTvl Min TVL of pool for being considered for incentivization
    constructor(
        address _operatorAddress,
        address _targetTokenAddress,
        address _incentiveTokenAddress,
        uint256 _minTvl
    ) Ownable() {
        operatorAddress = _operatorAddress;
        targetTokenAddress = _targetTokenAddress;
        incentiveTokenAddress = _incentiveTokenAddress;
        minTvl = _minTvl;
        emit StartAMO(_operatorAddress, _targetTokenAddress, _incentiveTokenAddress);
    }

    /* ================================================ MODIFIERS ======================================================= */

    modifier onlyByOwnerOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner(), "Not owner or operator");
        _;
    }

    modifier activePool(address _poolAddress) {
        require(poolInitialized[_poolAddress] && !poolInfo[_poolAddress].isPaused, "Pool is not active");
        require(showPoolTvl(_poolAddress) > minTvl, "Pool is small");
        _;
    }

    /* ================================================= EVENTS ========================================================= */

    /// @notice The ```StartAMO``` event fires when the AMO deploys
    /// @param _operatorAddress Address of operator
    /// @param _targetTokenAddress Address of Token that AMO incentivize (e.g. crvFRAX)
    /// @param _incentiveTokenAddress Address of Token that AMO uses as an incentive (e.g. FXS)
    event StartAMO(address _operatorAddress, address _targetTokenAddress, address _incentiveTokenAddress);

    /// @notice The ```SetOperator``` event fires when the operatorAddress is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetOperator(address _oldAddress, address _newAddress);

    /// @notice The ```AddOrSetPool``` event fires when a pool is added or modified
    /// @param _poolAddress The pool address
    /// @param _gaugeAddress The gauge address
    /// @param _incentivePoolAddress Contract that handle incentive distribution e.g. Bribe contract
    /// @param _incentivizationHandlerAddress Incentive handler contract e.g. votemarket handler
    /// @param _indexId indexID in Votium or Votemarket
    event AddOrSetPool(
        address _poolAddress,
        address _gaugeAddress,
        address _incentivePoolAddress,
        address _incentivizationHandlerAddress,
        uint256 _indexId
    );

    /// @notice The ```ChangePauseStatusPool``` event fires when a pool is added or modified
    /// @param _poolAddress The pool address
    /// @param _isPaused Pool Pause Status
    event ChangePauseStatusPool(address _poolAddress, bool _isPaused);

    /// @notice The ```SetPoolFixedIncent``` event fires when a pool's constant incentivization is updated 
    /// @param _poolAddress The pool address
    /// @param _hasFixedIncent Pool Deal Status
    /// @param _amountPerCycle Pool Deal Amount
    event SetPoolFixedIncent(address _poolAddress, bool _hasFixedIncent, uint256 _amountPerCycle);

    /// @notice The ```IncentivizePool``` event fires when a deposit happens to a pair
    /// @param _poolAddress The pool address
    /// @param _amount Incentive amount
    event IncentivizePool(address _poolAddress, uint256 _amount);

    /* ================================================== VIEWS ========================================================= */

    /// @notice Show TVL of targeted token in all active pools
    /// @return TVL of targeted token in all active pools
    function showActivePoolsTvl() public view returns (uint256) {
        uint tvl = 0;
        for (uint i = 0; i < poolArray.length; i++) {
            if (!poolInfo[poolArray[i]].isPaused) {
                tvl += showPoolTvl(poolArray[i]);
            }
        }
        return tvl;
    }

    /// @notice Show TVL of targeted token in liquidity pool
    /// @param _poolAddress Address of liquidity pool
    /// @return TVL of targeted token in liquidity pool
    function showPoolTvl(address _poolAddress) public view returns (uint256) {
        ERC20 targetToken = ERC20(targetTokenAddress);
        return targetToken.balanceOf(_poolAddress);
    }

    /// @notice Show Pool parameters
    /// @param _poolAddress Address of liquidity pool
    /// @return _gaugeAddress Gauge Contract Address
    /// @return _incentivePoolAddress Contract that handle incentive distribution e.g. Bribe contract
    /// @return _incentivizationHandlerAddress Incentive handler contract e.g. votemarket handler
    /// @return _incentivizationId Pool General Incentivization ID (e.g. in Votemarket it is BountyID)
    function showPoolInfo(
        address _poolAddress
    )
        external
        view
        returns (
            address _gaugeAddress,
            address _incentivePoolAddress,
            address _incentivizationHandlerAddress,
            uint256 _incentivizationId
        )
    {
        _incentivePoolAddress = poolInfo[_poolAddress].incentivePoolAddress;
        _incentivizationHandlerAddress = poolInfo[_poolAddress].incentivizationHandlerAddress;
        _gaugeAddress = poolInfo[_poolAddress].gaugeAddress;
        _incentivizationId = poolInfo[_poolAddress].incentivizationId;
    }

    /// @notice Show Pool status
    /// @param _poolAddress Address of liquidity pool
    /// @return _isInitialized Pool registered or not
    /// @return _lastIncentivizationTimestamp timestamp of last time this pool was incentivized
    /// @return _lastIncentivizationAmount last cycle incentive amount
    /// @return _isPaused puased or not
    function showPoolStatus(
        address _poolAddress
    )
        external
        view
        returns (
            bool _isInitialized,
            uint _lastIncentivizationTimestamp,
            uint _lastIncentivizationAmount,
            bool _isPaused
        )
    {
        _isInitialized = poolInitialized[_poolAddress];
        _lastIncentivizationTimestamp = poolInfo[_poolAddress].lastIncentivizationTimestamp;
        _lastIncentivizationAmount = poolInfo[_poolAddress].lastIncentivizationAmount;
        _isPaused = poolInfo[_poolAddress].isPaused;
    }

    /* ============================================== INCENTIVIZATION FUNCTIONS ==================================================== */

    /// @notice Function to deposit incentives to one pool
    /// @param _poolAddress Address of liquidity pool
    /// @param _amount Amount of incentives to be deposited
    function incentivizePoolByAmount(
        address _poolAddress,
        uint256 _amount
    ) public activePool(_poolAddress) onlyByOwnerOperator {
        ERC20 _incentiveToken = ERC20(incentiveTokenAddress);
        _incentiveToken.approve(poolInfo[_poolAddress].incentivePoolAddress, _amount);

        (bool success, ) = poolInfo[_poolAddress].incentivizationHandlerAddress.delegatecall(
            abi.encodeWithSignature(
                "incentivizePool(address,address,address,address,uint256,uint256)",
                _poolAddress,
                poolInfo[_poolAddress].gaugeAddress,
                poolInfo[_poolAddress].incentivePoolAddress,
                incentiveTokenAddress,
                poolInfo[_poolAddress].incentivizationId,
                _amount
            )
        );
        require(success, "delegatecall failed");

        poolInfo[_poolAddress].lastIncentivizationTimestamp = block.timestamp;
        poolInfo[_poolAddress].lastIncentivizationAmount = _amount;
        emit IncentivizePool(_poolAddress, _amount);
    }

    /// @notice Function to deposit incentives to one pool (based on ratio)
    /// @param _poolAddress Address of liquidity pool
    /// @param _totalIncentAmount Total budget for incentivization
    /// @param _totalTvl Total active pools TVL
    function incentivizePoolByTvl(
        address _poolAddress,
        uint256 _totalIncentAmount,
        uint256 _totalTvl
    ) public onlyByOwnerOperator {
        uint256 _poolTvl = showPoolTvl(_poolAddress);
        uint256 _amount = (_totalIncentAmount * _poolTvl) / _totalTvl;
        incentivizePoolByAmount(_poolAddress, _amount);
    }

    /// @notice Function to deposit incentives to one pool (based on budget per unit)
    /// @param _poolAddress Address of liquidity pool
    /// @param _unitIncentAmount Incentive per single unit of target Token
    function incentivizePoolByUnitBudget(
        address _poolAddress,
        uint256 _unitIncentAmount
    ) public onlyByOwnerOperator {
        uint256 _poolTvl = showPoolTvl(_poolAddress);
        uint256 _amount = (_unitIncentAmount * _poolTvl) / (10 ** ERC20(targetTokenAddress).decimals());
        incentivizePoolByAmount(_poolAddress, _amount);
    }

    /// @notice Function to deposit incentives to one pool (based on Constant Incentivization)
    /// @param _poolAddress Address of liquidity pool
    function incentivizePoolByFixedIncent(
        address _poolAddress
    ) public onlyByOwnerOperator {
        if (poolHasFixedIncent[_poolAddress]){
            uint256 _amount = poolFixedIncentAmount[_poolAddress];
            incentivizePoolByAmount(_poolAddress, _amount);
        }
    }

    /// Functions For depositing incentives to all active pools

    /// @notice Function to deposit incentives to all active pools (based on TVL ratio)
    /// @param _totalIncentAmount Total Incentive budget
    /// @param _FixedIncent Incentivize considering FixedIncent
    function incentivizeAllPoolsByTvl(uint256 _totalIncentAmount, bool _FixedIncent) public onlyByOwnerOperator {
        uint256 _totalTvl = showActivePoolsTvl();
        for (uint i = 0; i < poolArray.length; i++) {
            if (_FixedIncent && poolHasFixedIncent[poolArray[i]]) {
                incentivizePoolByFixedIncent(poolArray[i]);
            } else if (!poolInfo[poolArray[i]].isPaused && showPoolTvl(poolArray[i]) > minTvl) {
                incentivizePoolByTvl(poolArray[i], _totalIncentAmount, _totalTvl);
            }
        }
    }
    
    /// @notice Function to deposit incentives to all active pools (based on budget per unit of target Token)
    /// @param _unitIncentAmount Incentive per single unit of target Token
    /// @param _FixedIncent Incentivize considering FixedIncent
    function incentivizeAllPoolsByUnitBudget(uint256 _unitIncentAmount, bool _FixedIncent) public onlyByOwnerOperator {
        for (uint i = 0; i < poolArray.length; i++) {
            if (_FixedIncent && poolHasFixedIncent[poolArray[i]]) {
                incentivizePoolByFixedIncent(poolArray[i]);
            } else if (!poolInfo[poolArray[i]].isPaused && showPoolTvl(poolArray[i]) > minTvl) {
                incentivizePoolByUnitBudget(poolArray[i], _unitIncentAmount);
            }
        }
    }

    /// @notice Add/Set liquidity pool
    /// @param _poolAddress Address of liquidity pool
    /// @param _incentivePoolAddress Contract that handle incentive distribution e.g. Bribe contract
    /// @param _incentivizationHandlerAddress Incentive handler contract e.g. votemarket handler
    /// @param _gaugeAddress Address of liquidity pool gauge
    /// @param _incentivizationId Pool General Incentivization ID (e.g. in Votemarket it is BountyID)
    function addOrSetPool(
        address _poolAddress,
        address _incentivePoolAddress,
        address _incentivizationHandlerAddress,
        address _gaugeAddress,
        uint256 _incentivizationId
    ) external onlyByOwnerOperator {
        if (poolInitialized[_poolAddress]) {
            poolInfo[_poolAddress].incentivePoolAddress = _incentivePoolAddress;
            poolInfo[_poolAddress].incentivizationHandlerAddress = _incentivizationHandlerAddress;
            poolInfo[_poolAddress].gaugeAddress = _gaugeAddress;
            poolInfo[_poolAddress].incentivizationId = _incentivizationId;
        } else {
            poolInitialized[_poolAddress] = true;
            poolArray.push(_poolAddress);
            poolInfo[_poolAddress] = LiquidityPool({
                poolAddress: _poolAddress,
                incentivePoolAddress: _incentivePoolAddress,
                incentivizationHandlerAddress: _incentivizationHandlerAddress,
                gaugeAddress: _gaugeAddress,
                lastIncentivizationTimestamp: 0,
                lastIncentivizationAmount: 0,
                isPaused: false,
                incentivizationId: _incentivizationId
            });
        }

        emit AddOrSetPool(
            _poolAddress,
            _gaugeAddress,
            _incentivePoolAddress,
            _incentivizationHandlerAddress,
            _incentivizationId
        );
    }

    /// @notice Pause/Unpause liquidity pool
    /// @param _poolAddress Address of liquidity pool
    /// @param _isPaused bool
    function pausePool(address _poolAddress, bool _isPaused) external onlyByOwnerOperator {
        if (poolInitialized[_poolAddress]) {
            poolInfo[_poolAddress].isPaused = _isPaused;
            emit ChangePauseStatusPool(_poolAddress, _isPaused);
        }
    }

    /// @notice Add/Change/Remove Constant Incentivization can be set (e.g. DAO Deal)
    /// @param _poolAddress Address of liquidity pool
    /// @param _hasFixedIncent bool
    /// @param _amountPerCycle Amount of constant incentives
    function setFixedIncent(address _poolAddress, bool _hasFixedIncent, uint256 _amountPerCycle) external onlyByOwnerOperator {
        if (poolInitialized[_poolAddress]) {
            poolHasFixedIncent[_poolAddress] = _hasFixedIncent;
            poolFixedIncentAmount[_poolAddress] = _amountPerCycle;
            emit SetPoolFixedIncent(_poolAddress, _hasFixedIncent, _amountPerCycle);
        }
    }

    /* ====================================== RESTRICTED GOVERNANCE FUNCTIONS =========================================== */

    /// @notice Change the Operator address
    /// @param _newOperatorAddress Operator address
    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        emit SetOperator(operatorAddress, _newOperatorAddress);
        operatorAddress = _newOperatorAddress;
    }

    /// @notice Change the Min TVL for incentivization
    /// @param _minTvl Min TVL of pool for being considered for incentivization
    function setMinTvl(uint256 _minTvl) external onlyOwner {
        minTvl = _minTvl;
    }

    /// @notice Recover ERC20 tokens
    /// @param tokenAddress address of ERC20 token
    /// @param tokenAmount amount to be withdrawn
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Can only be triggered by owner
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{ value: _value }(_data);
        return (success, result);
    }
}