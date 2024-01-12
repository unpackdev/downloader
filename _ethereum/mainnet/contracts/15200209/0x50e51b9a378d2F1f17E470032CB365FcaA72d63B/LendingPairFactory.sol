// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./Pausable.sol";
import "./Clones.sol";
import "./IPriceOracleAggregator.sol";
import "./IInterestRateModel.sol";
import "./IBSLendingPair.sol";
import "./IBSWrapperToken.sol";
import "./IDebtToken.sol";
import "./IRewardDistributorManager.sol";
import "./JumpRateModelV2.sol";
import "./IERC20Details.sol";
import "./DataTypes.sol";

contract LendingPairFactory is Pausable {
    using Clones for address; 

    address public owner;

    address public lendingPairImplementation;
    address public collateralWrapperImplementation;
    address public debtTokenImplementation;
    address public borrowAssetWrapperImplementation;
    address public rewardDistributionManager;
    address internal newOwner;

    address[] public allPairs;

    mapping(address => bool) public validInterestRateModels;

    event NewLendingPair(address pair, uint256 created);
    event LogicContractUpdated(address pairLogic);
    event NewInterestRateModel(address ir, uint256 timestamp);
    event OwnershipAccepted(address prevOwner, address newOwner, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);

    /// @notice modifier to allow only the owner to call a function
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(
        address _owner,
        address _pairLogic,
        address _collateralWrapperLogic,
        address _debtTokenLogic,
        address _borrowAssetWrapperLogic,
        address _rewardDistributionManager
    ) {
        require(_owner != address(0), "inv_o");
        require(_pairLogic != address(0), "inv_l");
        require(_collateralWrapperLogic != address(0), "inv_c");
        require(_debtTokenLogic != address(0), "inv_d");
        require(_borrowAssetWrapperLogic != address(0), "inv_b");
        require(_rewardDistributionManager != address(0), "inv_r");

        owner = _owner;
        lendingPairImplementation = _pairLogic;
        collateralWrapperImplementation = _collateralWrapperLogic;
        debtTokenImplementation = _debtTokenLogic;
        borrowAssetWrapperImplementation = _borrowAssetWrapperLogic;
        rewardDistributionManager = _rewardDistributionManager;
    }

    /// @notice accept transfer of control
    function acceptOwnership() external {
        require(msg.sender == newOwner, "invalid owner");

        // emit event before state change to do not trigger null address
        emit OwnershipAccepted(owner, newOwner, block.timestamp);

        owner = newOwner;
        newOwner = address(0);
    }

    /// @notice Transfer control from current owner address to another
    /// @param _newOwner The new team
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "INVALID_NEW_OWNER");
        newOwner = _newOwner;
        emit TransferControl(_newOwner, block.timestamp);
    }

    /// @notice pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    function updatePairImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        lendingPairImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }

    function updateCollateralWrapperImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        collateralWrapperImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }

    function updateDebtTokenImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        debtTokenImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }

    function updateBorrowAssetWrapperImpl(address _newLogicContract) external onlyOwner {
        require(_newLogicContract != address(0), "INV_C");
        borrowAssetWrapperImplementation = _newLogicContract;
        emit LogicContractUpdated(_newLogicContract);
    }

    function updateRewardManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "INV_C");
        rewardDistributionManager = _newManager;
        emit LogicContractUpdated(_newManager);
    }

    struct NewLendingVaultIRLocalVars {
        uint256 baseRatePerYear;
        uint256 multiplierPerYear;
        uint256 jumpMultiplierPerYear;
        uint256 optimal;
        uint256 borrowRateMaxMantissa;
        uint256 blocksPerYear;
    }

    /// @dev create interest rate model
    function createIR(NewLendingVaultIRLocalVars calldata _interestRateVars, address _team)
        external
        onlyOwner
        returns (address ir)
    {
        require(address(_team) != address(0), "inv_t");

        ir = address(
            new JumpRateModelV2(
                _interestRateVars.baseRatePerYear,
                _interestRateVars.multiplierPerYear,
                _interestRateVars.jumpMultiplierPerYear,
                _interestRateVars.optimal,
                _team,
                _interestRateVars.borrowRateMaxMantissa,
                _interestRateVars.blocksPerYear
            )
        );

        validInterestRateModels[ir] = true;

        emit NewInterestRateModel(ir, block.timestamp);
    }

    /// @dev disable interest rate model
    function disableIR(address ir) external onlyOwner {
        require(validInterestRateModels[ir] == true, "IR_NOT_EXIST");
        validInterestRateModels[ir] = false;
    }

    struct BorrowLocalVars {
        IERC20 borrowAsset;
        uint256 initialExchangeRateMantissa;
        uint256 reserveFactorMantissa;
        uint256 collateralFactor;
        uint256 liquidationFee;
        IInterestRateModel interestRateModel;
    }

    struct WrappedAssetLocalVars {
        IBSWrapperToken wrappedBorrowAsset;
        IBSWrapperToken wrappedCollateralAsset;
        IDebtToken debtToken;
    }

    /// @dev create lending pair with clones
    function createLendingPairWithProxy(
        string memory _lendingPairName,
        string memory _lendingPairSymbol,
        address _pauseGuardian,
        IERC20 _collateralAsset,
        BorrowLocalVars calldata _borrowVars
    ) external whenNotPaused onlyOwner returns (address newLendingPair) {
        require(_pauseGuardian != address(0), "INV_G");
        require(address(_collateralAsset) != address(0), "INV_C");
        require(address(_borrowVars.borrowAsset) != address(0), "INV_B");
        require(validInterestRateModels[address(_borrowVars.interestRateModel)] == true, "INV_I");

        WrappedAssetLocalVars memory wrappedAssetLocalVars;

        bytes32 salt = keccak256(abi.encode(_lendingPairName, _lendingPairSymbol, allPairs.length));
        newLendingPair = lendingPairImplementation.cloneDeterministic(salt);

        // initialize wrapper borrow asset
        wrappedAssetLocalVars.wrappedBorrowAsset = IBSWrapperToken(
            initWrapperTokensWithProxy(
                borrowAssetWrapperImplementation,
                newLendingPair,
                address(_borrowVars.borrowAsset),
                _lendingPairName,
                "BOR",
                salt
            )
        );

        // initialize wrapper collateral asset
        wrappedAssetLocalVars.wrappedCollateralAsset = IBSWrapperToken(
            initWrapperTokensWithProxy(
                collateralWrapperImplementation,
                newLendingPair,
                address(_collateralAsset),
                _lendingPairName,
                "COL",
                salt
            )
        );

        // initialize debt token
        wrappedAssetLocalVars.debtToken = IDebtToken(
            initWrapperTokensWithProxy(
                debtTokenImplementation,
                newLendingPair,
                address(_borrowVars.borrowAsset),
                _lendingPairName,
                "DEBT",
                salt
            )
        );

        DataTypes.BorrowAssetConfig memory borrowConfig = DataTypes.BorrowAssetConfig(
            _borrowVars.initialExchangeRateMantissa,
            _borrowVars.reserveFactorMantissa,
            _borrowVars.collateralFactor,
            wrappedAssetLocalVars.wrappedBorrowAsset,
            _borrowVars.liquidationFee,
            wrappedAssetLocalVars.debtToken
        );

        // initialize lending pair
        IBSLendingPair(newLendingPair).initialize(
            _lendingPairName,
            _lendingPairSymbol,
            _borrowVars.borrowAsset,
            _collateralAsset,
            borrowConfig,
            wrappedAssetLocalVars.wrappedCollateralAsset,
            _borrowVars.interestRateModel,
            _pauseGuardian
        );

        allPairs.push(newLendingPair);
        emit NewLendingPair(newLendingPair, block.timestamp);
    }

    function initWrapperTokensWithProxy(
        address _implementation,
        address _pair,
        address _underlying,
        string memory _lendingPairName,
        string memory _tokenType,
        bytes32 _salt
    ) internal returns (address wrapper) {
        wrapper = _implementation.cloneDeterministic(_salt);

        initializeWrapperTokens(
            _pair,
            IBSWrapperToken(wrapper),
            IERC20Details(_underlying),
            _lendingPairName,
            _tokenType
        );
    }

    function initializeWrapperTokens(
        address _pair,
        IBSWrapperToken _wrapperToken,
        IERC20Details _underlying,
        string memory _lendingPairName,
        string memory _tokenType
    ) internal {
        bytes memory name = abi.encodePacked(_lendingPairName);
        name = abi.encodePacked(name, "-PAIR-", _tokenType);
        bytes memory symbol = abi.encodePacked(_lendingPairName);
        symbol = abi.encodePacked(name, _tokenType);
        // initialize wrapperToken
        IBSWrapperToken(_wrapperToken).initialize(
            _pair,
            address(_underlying),
            string(name),
            string(symbol),
            IRewardDistributorManager(rewardDistributionManager)
        );
    }
}
