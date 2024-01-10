// SPDX-License-Identifier: MIT
import "./ERC20.sol";
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./AbstractDependant.sol";
import "./IBMICoverStaking.sol";
import "./IBMIStaking.sol";
import "./IContractsRegistry.sol";
import "./ILiquidityBridge.sol";
import "./IPolicyBook.sol";
import "./IPolicyRegistry.sol";
import "./IV2BMIStaking.sol";
import "./IV2ContractsRegistry.sol";
import "./IV2PolicyBook.sol";
import "./IV2PolicyBookFacade.sol";
import "./ISTKBMIToken.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./IPolicyBookRegistry.sol";

import "./DecimalsConverter.sol";

contract LiquidityBridge is ILiquidityBridge, OwnableUpgradeable, AbstractDependant {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using Math for uint256;

    address public v1bmiStakingAddress;
    address public v2bmiStakingAddress;
    address public v1bmiCoverStakingAddress;
    address public v2bmiCoverStakingAddress;
    address public v1policyBookFabricAddress;
    address public v2contractsRegistryAddress;
    address public v1contractsRegistryAddress;
    address public v1policyRegistryAddress;
    address public v1policyBookRegistryAddress;
    address public v2policyBookRegistryAddress;

    address public admin;

    uint256 public counter;
    uint256 public stblDecimals;

    IERC20 public bmiToken;
    ERC20 public stblToken;

    // Policybook => user
    mapping(address => mapping(address => bool)) public migrateAddLiquidity;
    mapping(address => mapping(address => bool)) public migratedCoverStaking;
    mapping(address => mapping(address => bool)) public migratedPolicies;

    mapping(address => address) public upgradedPolicies;
    mapping(address => uint256) public extractedLiquidity;
    mapping(address => uint256) public migratedLiquidity;

    event TokensRecovered(address to, uint256 amount);

    event MigratedPolicy(
        address indexed v1PolicyBook,
        address indexed v2PolicyBook,
        address indexed sender,
        uint256 price
    );

    event MigrationAllowanceSetUp(
        address indexed pool,
        uint256 newStblAllowance,
        uint256 newBMIXAllowance
    );

    event NftProcessed(
        uint256 indexed nftId,
        address indexed policyBookAddress,
        address indexed userAddress,
        uint256 stakedBMIXAmount
    );

    event LiquidityCollected(
        address indexed v1PolicyBook,
        address indexed v2PolicyBook,
        uint256 amount
    );
    event LiquidityMigrated(
        uint256 migratedCount,
        address indexed poolAddress,
        address indexed userAddress
    );
    event SkippedRequest(uint256 reason, address indexed poolAddress, address indexed userAddress);
    event MigratedAddedLiquidity(
        address indexed pool,
        address indexed user,
        uint256 tetherAmount,
        uint8 withdrawalStatus
    );

    function __LiquidityBridge_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry) external override {
        v1contractsRegistryAddress = 0x8050c5a46FC224E3BCfa5D7B7cBacB1e4010118d;
        v2contractsRegistryAddress = 0x45269F7e69EE636067835e0DfDd597214A1de6ea;

        require(
            msg.sender == v1contractsRegistryAddress || msg.sender == v2contractsRegistryAddress,
            "Dependant: Not an injector"
        );

        IContractsRegistry _v1contractsRegistry = IContractsRegistry(v1contractsRegistryAddress);
        IV2ContractsRegistry _v2contractsRegistry =
            IV2ContractsRegistry(v2contractsRegistryAddress);

        v1bmiStakingAddress = _v1contractsRegistry.getBMIStakingContract();
        v2bmiStakingAddress = _v2contractsRegistry.getBMIStakingContract();

        v1bmiCoverStakingAddress = _v1contractsRegistry.getBMICoverStakingContract();
        v2bmiCoverStakingAddress = _v2contractsRegistry.getBMICoverStakingContract();

        v1policyBookFabricAddress = _v1contractsRegistry.getPolicyBookFabricContract();

        v1policyRegistryAddress = _v1contractsRegistry.getPolicyRegistryContract();

        v1policyBookRegistryAddress = _v1contractsRegistry.getPolicyBookRegistryContract();
        v2policyBookRegistryAddress = _v2contractsRegistry.getPolicyBookRegistryContract();

        bmiToken = IERC20(_v1contractsRegistry.getBMIContract());
        stblToken = ERC20(_contractsRegistry.getUSDTContract());

        stblDecimals = stblToken.decimals();
    }

    modifier onlyAdmins() {
        require(_msgSender() == admin || _msgSender() == owner(), "not in admins");
        _;
    }

    modifier guardEmptyPolicies(address v1Policy) {
        require(hasRecievingPolicy(upgradedPolicies[v1Policy]), "No recieving policy set");
        _;
    }

    function hasRecievingPolicy(address v1Policy) public view returns (bool) {
        if (upgradedPolicies[v1Policy] == address(0)) {
            return false;
        }
        return true;
    }

    function checkBalances()
        external
        view
        returns (
            address[] memory policyBooksV1,
            uint256[] memory balanceV1,
            address[] memory policyBooksV2,
            uint256[] memory balanceV2,
            uint256[] memory takenLiquidity,
            uint256[] memory bridgedLiquidity
        )
    {
        address[] memory policyBooks =
            IPolicyBookRegistry(v1policyBookRegistryAddress).list(0, 33);

        policyBooksV1 = new address[](policyBooks.length);
        policyBooksV2 = new address[](policyBooks.length);
        balanceV1 = new uint256[](policyBooks.length);
        balanceV2 = new uint256[](policyBooks.length);
        takenLiquidity = new uint256[](policyBooks.length);
        bridgedLiquidity = new uint256[](policyBooks.length);

        for (uint256 i = 0; i < policyBooks.length; i++) {
            if (policyBooks[i] == address(0)) {
                break;
            }

            policyBooksV1[i] = policyBooks[i];
            balanceV1[i] = stblToken.balanceOf(policyBooksV1[i]);
            policyBooksV2[i] = upgradedPolicies[policyBooks[i]];
            takenLiquidity[i] = extractedLiquidity[policyBooks[i]];

            if (policyBooksV2[i] != address(0)) {
                balanceV2[i] = stblToken.balanceOf(policyBooksV2[i]);
            }
            bridgedLiquidity[i] = migratedLiquidity[policyBooks[i]];
        }
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    // function _unlockAllowances() internal {
    //     if (bmiToken.allowance(address(this), v2bmiStakingAddress) == 0) {
    //         bmiToken.approve(v2bmiStakingAddress, uint256(-1));
    //     }

    //     if (bmiToken.allowance(address(this), v2bmiCoverStakingAddress) == 0) {
    //         bmiToken.approve(v2bmiStakingAddress, uint256(-1));
    //     }
    // }

    function unlockStblAllowanceFor(address _spender, uint256 _amount) external onlyAdmins {
        _unlockStblAllowanceFor(_spender, _amount);
    }

    function _unlockStblAllowanceFor(address _spender, uint256 _amount) internal {
        uint256 _allowance = stblToken.allowance(address(this), _spender);

        if (_allowance < _amount) {
            if (_allowance > 0) {
                stblToken.safeApprove(_spender, 0);
            }

            stblToken.safeIncreaseAllowance(_spender, _amount);
        }
    }

    function purchasePolicyFor(address _v1Policy, address _sender)
        external
        onlyAdmins
        guardEmptyPolicies(_v1Policy)
        returns (bool)
    {
        IPolicyBook.PolicyHolder memory data = IPolicyBook(_v1Policy).userStats(_sender);

        if (data.startEpochNumber != 0) {
            uint256 _currentEpoch = IPolicyBook(_v1Policy).getEpoch(block.timestamp);

            if (data.endEpochNumber > _currentEpoch) {
                uint256 _epochNumbers = data.endEpochNumber.sub(_currentEpoch);

                address facade = IV2PolicyBook(upgradedPolicies[_v1Policy]).policyBookFacade();

                (, uint256 _price, ) =
                    IV2PolicyBook(_v1Policy).getPolicyPrice(
                        _epochNumbers,
                        data.coverTokens,
                        _sender
                    );

                // TODO fund the premiums?
                IV2PolicyBookFacade(facade).buyPolicyFor(_sender, _epochNumbers, data.coverTokens);

                emit MigratedPolicy(_v1Policy, upgradedPolicies[_v1Policy], _sender, _price);
                migratedPolicies[_v1Policy][_sender] = true;

                return true;
            }
        }

        return false;
    }

    function migrateAddedLiquidity(
        address[] calldata _poolAddress,
        address[] calldata _userAddress
    ) external onlyAdmins {
        require(_poolAddress.length == _userAddress.length, "Missmatch inputs lenght");
        uint256 maxGasSpent = 0;
        uint256 i;

        for (i = 0; i < _poolAddress.length; i++) {
            uint256 gasStart = gasleft();

            if (upgradedPolicies[_poolAddress[i]] == address(0)) {
                // No linked v2 policyBook
                emit SkippedRequest(0, _poolAddress[i], _userAddress[i]);
                continue;
            }

            migrateStblLiquidity(_poolAddress[i], _userAddress[i]);
            counter++;

            emit LiquidityMigrated(counter, _poolAddress[i], _userAddress[i]);

            uint256 gasEnd = gasleft();
            maxGasSpent = (gasStart - gasEnd) > maxGasSpent ? (gasStart - gasEnd) : maxGasSpent;

            if (gasEnd < maxGasSpent) {
                break;
            }
        }
    }

    function migrateStblLiquidity(address _pool, address _sender)
        public
        onlyAdmins
        returns (bool)
    {
        // (uint256 userBalance, uint256 withdrawalsInfo, uint256 _burnedBMIX)

        IPolicyBook.WithdrawalStatus withdrawalStatus =
            IPolicyBook(_pool).getWithdrawalStatus(_sender);

        (uint256 _tokensToBurn, uint256 _stblAmountStnd) =
            IPolicyBook(_pool).getUserBMIXStakeInfo(_sender);

        // IPolicyBook(_pool).migrateRequestWithdrawal(_sender, _tokensToBurn);

        if (_stblAmountStnd > 0) {
            address _v2Policy = upgradedPolicies[_pool];
            address facade = IV2PolicyBook(_v2Policy).policyBookFacade();

            // IV2PolicyBookFacade(facade).addLiquidityAndStakeFor(
            //     _sender,
            //     _stblAmountStnd,
            //     _stblAmountStnd
            // );

            uint256 _stblAmountStndTether =
                DecimalsConverter.convertFrom18(_stblAmountStnd, stblDecimals);
            migratedLiquidity[_pool] = migratedLiquidity[_pool].add(_stblAmountStndTether);
            // extractedLiquidity[_pool].sub(_stblAmountStndTether);
            migrateAddLiquidity[_pool][_sender] = true;

            emit MigratedAddedLiquidity(_pool, _sender, _stblAmountStnd, uint8(withdrawalStatus));
        }
    }

    function migrateUserBMIStake(address _sender, uint256 _bmiAmount) external override {
        require(_msgSender() == v1bmiStakingAddress, "LB: no migration role");

        if (_bmiAmount > 0) {
            IV2BMIStaking(v2bmiStakingAddress).stakeFor(_sender, _bmiAmount);
        }
    }

    /// @notice migrates a stake from BMIStaking
    /// @param _sender address of the user to migrate description
    /// @param _bmiRewards uint256 unstaked bmi rewards for restaking
    function migrateBMIStake(address _sender, uint256 _bmiRewards) internal returns (bool) {
        (uint256 _amountBMI, uint256 _burnedStkBMI) =
            IBMIStaking(v1bmiStakingAddress).migrateStakeToV2(_sender);

        if (_amountBMI > 0) {
            IV2BMIStaking(v2bmiStakingAddress).stakeFor(_sender, _amountBMI + _bmiRewards);
        }

        emit BMIMigratedToV2(_sender, _amountBMI, _bmiRewards, _burnedStkBMI);
    }

    function recoverBMITokens() external onlyOwner {
        uint256 balance = bmiToken.balanceOf(address(this));

        bmiToken.transfer(_msgSender(), balance);

        emit TokensRecovered(_msgSender(), balance);
    }
}
