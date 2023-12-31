// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "Address.sol";
import { Ownable } from "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ITroveManager.sol";
import "IBorrowerOperations.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface RocketStorageInterface {
    function getAddress(bytes32 _key) external view returns (address);
}

interface RocketDepositPoolInterface {
    function deposit() external payable;
}

contract rETHDepositor {
    bytes32 public constant GET_ADDRESS = keccak256(abi.encodePacked("contract.address", "rocketDepositPool"));
    RocketStorageInterface public immutable rocketStorage;
    IERC20 public immutable rETH;

    constructor(RocketStorageInterface _rocketStorageAddress, IERC20 _rETH) {
        rocketStorage = _rocketStorageAddress;
        rETH = _rETH;
    }

    function deposit() external payable {
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(
            rocketStorage.getAddress(GET_ADDRESS)
        );
        rocketDepositPool.deposit{ value: msg.value }();
        rETH.transfer(address(msg.sender), rETH.balanceOf(address(this)));
    }
}

/**
    @title Prisma Stake and Deposit Zap
    @notice Zap to automate staking and depositing from native ETH or WETH into one
            of the supported Prisma collaterals.
 */
contract StakeNTroveZap is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    struct StakingRecord {
        address stakingContract;
        bytes payload;
    }
    // Events ---------------------------------------------------------------------------------------------------------

    event EtherStakedViaPrisma(address token, uint256 amount);
    event NewTokenRegistered(address token);
    event EmergencyEtherRecovered(uint256 amount);
    event EmergencyERC20Recovered(address tokenAddress, uint256 tokenAmount);

    IBorrowerOperations public immutable borrowerOps;
    IERC20 public immutable debtToken;
    IWETH public immutable weth;

    // State ------------------------------------------------------------------------------------------------------------

    mapping(address token => StakingRecord record) public stakingRecords;

    constructor(IBorrowerOperations _borrowerOps, IERC20 _debtToken, IWETH _weth) {
        borrowerOps = _borrowerOps;
        debtToken = _debtToken;
        weth = _weth;
    }

    // Admin routines ---------------------------------------------------------------------------------------------------

    /**
        @notice Registers a token to be zapped
        @param  token Token to be registered
        @param  stakingContract Contract which stakes and mint the token (can be the token itself)
        @param  payload Call data to invoke on the staking contract
     */
    function registerToken(address token, address stakingContract, bytes calldata payload) external onlyOwner {
        require(stakingRecords[token].stakingContract == address(0), "Token already registered");
        stakingRecords[token] = StakingRecord(stakingContract, payload);
        IERC20(token).approve(address(borrowerOps), type(uint256).max);

        emit NewTokenRegistered(token);
    }

    /// @notice For emergencies if something gets stuck
    function recoverEther(uint256 amount) external onlyOwner {
        (bool success, ) = owner().call{ value: amount }("");
        require(success, "Invalid transfer");

        emit EmergencyEtherRecovered(amount);
    }

    /// @notice For emergencies if someone accidentally sent some ERC20 tokens here
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);

        emit EmergencyERC20Recovered(tokenAddress, tokenAmount);
    }

    // Public functions -------------------------------------------------------------------------------------------------

    /// @notice Stakes and open a trove
    function openTrove(
        ITroveManager troveManager,
        uint256 _maxFeePercentage,
        uint256 ethAmount,
        uint256 _debtAmount,
        address _upperHint,
        address _lowerHint
    ) external payable {
        uint256 staked = _stake(troveManager.collateralToken(), ethAmount);
        borrowerOps.openTrove(
            address(troveManager),
            msg.sender,
            _maxFeePercentage,
            staked,
            _debtAmount,
            _upperHint,
            _lowerHint
        );
        debtToken.transfer(msg.sender, _debtAmount);
    }

    /// @notice Stakes and adds collateral to an existing trove
    function addColl(
        ITroveManager troveManager,
        uint256 ethAmount,
        address _upperHint,
        address _lowerHint
    ) external payable {
        adjustTrove(troveManager, 0, ethAmount, 0, false, _upperHint, _lowerHint);
    }

    /// @notice Stakes and adjusts a trove
    function adjustTrove(
        ITroveManager troveManager,
        uint256 _maxFeePercentage,
        uint256 ethAmount,
        uint256 _debtChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) public payable {
        uint256 staked = _stake(troveManager.collateralToken(), ethAmount);
        borrowerOps.adjustTrove(
            address(troveManager),
            msg.sender,
            _maxFeePercentage,
            staked,
            0,
            _debtChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint
        );
        if (_isDebtIncrease) debtToken.transfer(msg.sender, _debtChange);
    }

    function _stake(address token, uint256 ethAmount) internal returns (uint256 staked) {
        StakingRecord memory record = stakingRecords[token];
        address stakingContract = record.stakingContract;
        require(stakingContract != address(0), "Unsupported Token");
        if (msg.value == 0) {
            weth.transferFrom(msg.sender, address(this), ethAmount);
            weth.withdraw(ethAmount);
        } else {
            require(ethAmount == msg.value, "Wrong amount sent");
        }
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        (bool success, ) = stakingContract.call{ value: ethAmount }(record.payload);
        require(success, "Staking failed");
        emit EtherStakedViaPrisma(token, ethAmount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        staked = balanceAfter - balanceBefore;
        require(staked > 0, "Nothing was minted");
    }

    receive() external payable {}
}
