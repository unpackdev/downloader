// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./SafeERC20.sol";
import "./IPool.sol";
import "./FlashLoanSimpleReceiverBase.sol";
import "./Interfaces.sol";

contract ConnectorV2Flashloan is FlashLoanSimpleReceiverBase {
    using SafeERC20 for IERC20;

    struct FlashloanVars {
        address sender;
        uint256 funcId;
        bool isShield;
        uint256 feeAmount;
    }

    /* ========== Layout ========== */
    address public owner;
    address public doughV2Index = address(0);

    bytes32 internal dataHash = bytes32(0);
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status = 1;

    /* ========== Constant ========== */
    uint256 private constant _PRECISION = 10000; // x * 2% -> x * 200 /100 /100 = x * 200 / 10000
    address private constant _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IAaveV3DataProvider private constant _I_AAVE_V3_DATA_PROVIDER = IAaveV3DataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);

    /* ========== Events ========== */
    event Log(string message, uint256 val);

    /* ========== Modifier ========== */
    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        if (dataHash_ != dataHash || dataHash_ == bytes32(0)) revert CustomError("invalid-data-hash");
        if (status != 2) revert CustomError("already-entered3");
        dataHash = bytes32(0);
        _;
        status = 1;
    }
    modifier reentrancy() {
        if (status != 1) revert CustomError("already-entered1");
        status = 2;
        _;
        if (status != 1) revert CustomError("already-entered2");
    }

    /* ========== CONSTRUCTOR ========== */
    constructor(IPoolAddressesProvider provider, address _doughV2Index) FlashLoanSimpleReceiverBase(provider) {
        if (_doughV2Index == address(0)) revert CustomError("invalid _doughV2Index");
        doughV2Index = _doughV2Index;
    }

    /* ========== FUNCTIONS ========== */
    function getOwner() public view returns (address) {
        return IDoughV2Index(doughV2Index).owner();
    }

    function withdrawToken(address _asset, uint256 _amount) external {
        if (msg.sender != getOwner()) revert CustomError("ConnectorV2Flashloan: not owner of doughV2Index");
        if (_amount == 0) revert CustomError("must be greater than zero");
        uint256 balanceOfToken = IERC20(_asset).balanceOf(address(this));
        uint256 transAmount = _amount;
        if (_amount > balanceOfToken) {
            transAmount = balanceOfToken;
        }
        IERC20(_asset).safeTransfer(getOwner(), transAmount);
    }

    // delegate Call
    function delegateDoughCall(uint256 _actionId, address _token1, address _token2, uint256 _amount, bool _opt) external {
        //  Loop: _actionId = 0 , DeLoop: _actionId = 1;
        if (_actionId > 1) revert CustomError("ConnectorV2Flashloan : invalid id");
        if (_token1 != _WETH) revert CustomError("ConnectorV2Flashloan : invalid token.");
        if (_token1 != _token2) revert CustomError("ConnectorV2Flashloan: invalid token2");
        if (_amount == 0) revert CustomError("ConnectorV2Flashloan : invalid amount.");

        // get connectorV2Flashloan address
        address _connectorV2Flashloan = IDoughV2Index(doughV2Index).getDoughV2Connector(2);
        if (_connectorV2Flashloan == address(0)) revert CustomError("doughV2Dsa: doughLoopAndDeloop : unregistered connectorV2Flashloan");

        // get Position
        (uint256 currentATokenBalance, , uint256 currentVariableDebt, , , , , , ) = _I_AAVE_V3_DATA_PROVIDER.getUserReserveData(_token1, address(this));

        uint256 flashloanAmount = _amount;
        bool isShield = false;
        if (_actionId == 0) {
            if (currentATokenBalance == 0) revert CustomError("doughV2Dsa : supply first to AaveV3");
        } else if (_actionId == 1) {
            if (currentVariableDebt == 0) revert CustomError("doughV2Dsa : Loop first");
            if (flashloanAmount > currentVariableDebt) revert CustomError("doughV2Dsa : flashloanAmount must be less than Debt");
            if (_opt) {
                flashloanAmount = currentVariableDebt;
            }
            address shieldExecutor = IDoughV2Index(doughV2Index).shieldExecutor();
            if (msg.sender == shieldExecutor) {
                isShield = true;
            }
        }
        IConnectorV2Flashloan(_connectorV2Flashloan).flashloanReq(_token1, flashloanAmount, _actionId, isShield);
    }

    function flashloanReq(address _loanToken, uint256 _loanAmount, uint256 _funcId, bool _isShield) external reentrancy {
        //  Loop: funcId = 0 , DeLoop: funcId = 1;
        if (_funcId > 1) revert CustomError("flashloanReq : invalid-id");
        bytes memory data = abi.encode(msg.sender, _loanToken, _loanAmount, _funcId, _isShield);
        dataHash = keccak256(data);
        IPool(address(POOL)).flashLoanSimple(address(this), _loanToken, _loanAmount, data, 0);
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes memory data) public verifyDataHash(data) returns (bool) {
        if (initiator != address(this)) revert CustomError("not-same-sender");
        if (msg.sender != address(POOL)) revert CustomError("not-aave-sender");

        FlashloanVars memory flashloanVars;

        (flashloanVars.sender, , , flashloanVars.funcId, flashloanVars.isShield) = abi.decode(data, (address, address, uint256, uint256, bool));
        //  Loop: funcId = 0 , DeLoop: funcId = 1;
        if (flashloanVars.funcId > 1) revert CustomError("invalid-id");

        //------- get feeAmount for shield executor -------
        if (flashloanVars.isShield) {
            // calc fee amount to treasury for shield executor
            flashloanVars.feeAmount = (amount * IDoughV2Index(doughV2Index).shieldFee()) / _PRECISION;
        } else {
            // calc fee amount to treasury for user
            flashloanVars.feeAmount = (amount * IDoughV2Index(doughV2Index).flashloanFee()) / _PRECISION;
        }
        //------- Custom Logic Start ---------
        IERC20(asset).approve(flashloanVars.sender, amount);
        IDoughV2Dsa(flashloanVars.sender).executeAction(asset, amount, amount + flashloanVars.feeAmount + premium, flashloanVars.funcId);
        IERC20(asset).safeTransferFrom(flashloanVars.sender, address(this), amount + flashloanVars.feeAmount + premium);
        //------- Custom Logic End   ---------

        // pay back the loan amount and the premium (flashloan fee)
        IERC20(asset).approve(address(POOL), amount + premium);

        emit Log("dough borrowed amount", amount);
        emit Log("dough flashloan fee", premium);
        emit Log("dough fee", flashloanVars.feeAmount);
        emit Log("dough amountToReturn", amount + premium);
        return true;
    }
}
