// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IStrategy.sol";
import "./IAaveLendingPool.sol";
import "./IAaveIncentivesController.sol";

contract AaveStrategy is Ownable, IStrategy {
    using SafeERC20 for IERC20;

    bool public override paused;
    address public override core;
    address public override treasury;
    IAaveLendingPool public immutable lendingPool;
    IAaveIncentivesController public immutable incentivesController;
    mapping(address => uint256) public override totalDeposits;

    modifier onlyCore() {
        require(msg.sender == core, "Strategy: !core");
        _;
    }

    modifier onlyNotPaused() {
        require(!paused, "Strategy: paused");
        _;
    }

    constructor(address _core, address _treasury, address _lendingPool, address _incentivesController) {
        require(_core != address(0), "Strategy: core cannot be 0");
        require(_treasury != address(0), "Strategy: treasury cannot be 0");
        require(_lendingPool != address(0), "Strategy: lending pool cannot be 0");
        require(_incentivesController != address(0), "Strategy: incentives controller cannot be 0");
        core = _core;
        treasury = _treasury;
        lendingPool = IAaveLendingPool(_lendingPool);
        incentivesController = IAaveIncentivesController(_incentivesController);
        initializeOwner();
    }

    /// @notice only callable by core contract
    function invest(address _token, uint256 _amount) external override onlyCore onlyNotPaused {
        // get funds to invest from core
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _approve(IERC20(_token), address(lendingPool), _amount);
        // deposit funds into Aave, keep aTokens in strategy
        lendingPool.deposit(_token, _amount, address(this), 0);
        // increment total deposits
        totalDeposits[_token] += _amount;
    }

    /// divests _amount of _token from Aave
    /// @notice only callable by core contract
    function divest(address _token, uint256 _amount) external override onlyCore onlyNotPaused{
        if (_amount == type(uint256).max) { 
            // if withdrawing all, withdraw to this contract first to collect interest
            lendingPool.withdraw(_token, _amount, address(this));
            uint256 tokensWithdrawn = IERC20(_token).balanceOf(address(this));
            
            // send original invested amount to core
            IERC20(_token).safeTransfer(msg.sender, totalDeposits[_token]);

            // send accrued interest to treasury
            IERC20(_token).safeTransfer(treasury, tokensWithdrawn - totalDeposits[_token]);

            totalDeposits[_token] = 0;
        } else {
            // withdraw exact amount directly to core
            lendingPool.withdraw(_token, _amount, msg.sender);
            totalDeposits[_token] -= _amount;
        }
    }

    /// claim AAVE rewards
    function claimRewards(address[] calldata assets) external onlyOwner {
        uint256 amountToClaim = incentivesController.getRewardsBalance(assets, address(this));
        incentivesController.claimRewards(assets, amountToClaim, treasury);
    }

    /// contract should not hold ANY funds except aTokens
    /// funds sent here can be retreived
    function collect(address _token) external override onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "Strategy: balance is 0");
        IERC20(_token).safeTransfer(treasury, balance);
    }

    function setCore(address _core) external override onlyOwner {
        require(_core != address(0), "Strategy: core cannot be 0");
        emit AddressUpdated("core", core, _core);
        core = _core;
    }

    function setTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), "Strategy: treasury cannot be 0");
        emit AddressUpdated("treasury", treasury, _treasury);
        treasury = _treasury;
    }

    function setPaused(bool _paused) external override onlyOwner {
        paused = _paused;
    }

    function _approve(IERC20 _token, address _spender, uint256 _amount) private {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _amount) {
            if (allowance != 0) {
                _token.safeApprove(_spender, 0);
            }
            _token.safeApprove(_spender, type(uint256).max);
        }
    }
}