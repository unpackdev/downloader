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
    address private constant _USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IAaveV3DataProvider private constant _I_AAVE_V3_DATA_PROVIDER = IAaveV3DataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);
    address private constant _UNISWAP_V2_ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router private constant _I_UNISWAP_V2_ROUTER = IUniswapV2Router(_UNISWAP_V2_ROUTER);
    IAaveV3Pool private constant _I_AAVE_V3_POOL = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

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

    function _getPathWethUsdc() private pure returns (address[] memory) {
        address[] memory path;
        path = new address[](2);
        path[0] = _WETH;
        path[1] = _USDC;
        return path;
    }

    function _getPathUsdcWeth() private pure returns (address[] memory) {
        address[] memory path;
        path = new address[](2);
        path[0] = _USDC;
        path[1] = _WETH;
        return path;
    }

    // delegate Call
    function delegateDoughCall(uint256 _actionId, address _token, uint256 _amount, bool _opt) external {
        //  Loop: _actionId = 0 , DeLoop: _actionId = 1, Switch: _actionId = 2
        if (_actionId > 2) revert CustomError("ConnectorV2Flashloan : invalid id");
        if (_token != _WETH && _token != _USDC) revert CustomError("ConnectorV2Flashloan : invalid token.");
        if (_amount == 0) revert CustomError("ConnectorV2Flashloan : invalid amount.");

        // get connectorV2Flashloan address
        address _connectorV2Flashloan = IDoughV2Index(doughV2Index).getDoughV2Connector(2);
        if (_connectorV2Flashloan == address(0)) revert CustomError("doughV2Dsa: doughLoopAndDeloop : unregistered connectorV2Flashloan");

        // get Position
        (uint256 currentATokenBalance, , uint256 currentVariableDebt, , , , , , ) = _I_AAVE_V3_DATA_PROVIDER.getUserReserveData(_token, address(this));

        uint256 flashloanAmount = _amount;
        bool isShield = false;
        if (_actionId == 0) {
            if (currentATokenBalance == 0) revert CustomError("doughV2Dsa : supply first to AaveV3");
        } else if (_actionId == 1) {
            if (_token != _USDC) revert CustomError("doughV2Dsa : invalid token for deloop");
            if (currentVariableDebt == 0) revert CustomError("doughV2Dsa : Loop first");
            if (_opt) {
                flashloanAmount = currentVariableDebt;
            } else {
                if (flashloanAmount > currentVariableDebt) revert CustomError("doughV2Dsa : flashloanAmount must be less than Debt");
            }
            if (msg.sender == IDoughV2Index(doughV2Index).shieldExecutor()) {
                isShield = true;
            }
        } else {
            if (currentATokenBalance == 0) revert CustomError("doughV2Dsa : supply first to AaveV3");
            // get Aave Flashloan Fee
            uint256 _flashloanPremiumTotal = _I_AAVE_V3_POOL.FLASHLOAN_PREMIUM_TOTAL();
            // get Dough Flashloan Fee
            uint256 _doughFlashloanfee = IDoughV2Index(doughV2Index).flashloanFee();
            // get flashloan amount
            if (_amount > currentATokenBalance) {
                flashloanAmount = (currentATokenBalance * _PRECISION) / (_doughFlashloanfee + _flashloanPremiumTotal + _PRECISION);
            } else {
                flashloanAmount = (_amount * _PRECISION) / (_doughFlashloanfee + _flashloanPremiumTotal + _PRECISION);
            }
        }
        IConnectorV2Flashloan(_connectorV2Flashloan).flashloanReq(_token, flashloanAmount, _actionId, isShield);
    }

    function flashloanReq(address _loanToken, uint256 _loanAmount, uint256 _funcId, bool _isShield) external reentrancy {
        //  Loop: funcId = 0 , DeLoop: funcId = 1; Switch: funcId = 2;
        if (_funcId > 2) revert CustomError("flashloanReq : invalid-id");
        bytes memory data = abi.encode(msg.sender, _loanToken, _loanAmount, _funcId, _isShield);
        dataHash = keccak256(data);
        IPool(address(POOL)).flashLoanSimple(address(this), _loanToken, _loanAmount, data, 0);
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes memory data) public verifyDataHash(data) returns (bool) {
        if (initiator != address(this)) revert CustomError("not-same-sender");
        if (msg.sender != address(POOL)) revert CustomError("not-aave-sender");
        if (asset != _WETH && asset != _USDC) revert CustomError("invalid token");

        FlashloanVars memory flashloanVars;

        (flashloanVars.sender, , , flashloanVars.funcId, flashloanVars.isShield) = abi.decode(data, (address, address, uint256, uint256, bool));
        //  Loop: funcId = 0 , DeLoop: funcId = 1; Switch: funcId = 2;
        if (flashloanVars.funcId > 2) revert CustomError("invalid-id");

        //------- get feeAmount for shield executor -------
        if (flashloanVars.isShield) {
            // calc fee amount to treasury for shield executor
            flashloanVars.feeAmount = (amount * IDoughV2Index(doughV2Index).shieldFee()) / _PRECISION;
        } else {
            // calc fee amount to treasury for user
            flashloanVars.feeAmount = (amount * IDoughV2Index(doughV2Index).flashloanFee()) / _PRECISION;
        }

        //------- Custom Logic Start ---------
        if (flashloanVars.funcId == 0) {
            IERC20(asset).approve(flashloanVars.sender, amount);
            if (asset == _WETH) {
                uint256[] memory _amountsIn = _I_UNISWAP_V2_ROUTER.getAmountsIn(amount + flashloanVars.feeAmount + premium, _getPathUsdcWeth());
                IDoughV2Dsa(flashloanVars.sender).executeAction(_WETH, amount, _USDC, _amountsIn[0], flashloanVars.funcId);
                IERC20(_USDC).safeTransferFrom(flashloanVars.sender, address(this), _amountsIn[0]);
                IERC20(_USDC).approve(_UNISWAP_V2_ROUTER, _amountsIn[0]);
                _I_UNISWAP_V2_ROUTER.swapExactTokensForTokens(_amountsIn[0], 0, _getPathUsdcWeth(), address(this), block.timestamp);
            } else {
                IDoughV2Dsa(flashloanVars.sender).executeAction(_USDC, amount, _USDC, amount + flashloanVars.feeAmount + premium, flashloanVars.funcId);
                IERC20(_USDC).safeTransferFrom(flashloanVars.sender, address(this), amount + flashloanVars.feeAmount + premium);
            }
        } else if (flashloanVars.funcId == 1) {
            if (asset != _USDC) revert CustomError("invalid token");
            IERC20(_USDC).approve(flashloanVars.sender, amount);
            // get Position
            (uint256 currentATokenBalance, , , , , , , , ) = _I_AAVE_V3_DATA_PROVIDER.getUserReserveData(_USDC, flashloanVars.sender);
            if (currentATokenBalance >= amount + flashloanVars.feeAmount + premium) {
                IDoughV2Dsa(flashloanVars.sender).executeAction(_USDC, amount, _USDC, amount + flashloanVars.feeAmount + premium, flashloanVars.funcId);
                IERC20(_USDC).safeTransferFrom(flashloanVars.sender, address(this), amount + flashloanVars.feeAmount + premium);
            } else {
                uint256[] memory _amountsIn = _I_UNISWAP_V2_ROUTER.getAmountsIn(amount + flashloanVars.feeAmount + premium - currentATokenBalance, _getPathWethUsdc());
                IDoughV2Dsa(flashloanVars.sender).executeAction(_USDC, amount, _WETH, _amountsIn[0], flashloanVars.funcId);
                IERC20(_WETH).safeTransferFrom(flashloanVars.sender, address(this), _amountsIn[0]);
                if (currentATokenBalance > 0) {
                    IERC20(_USDC).safeTransferFrom(flashloanVars.sender, address(this), currentATokenBalance);
                }
                IERC20(_WETH).approve(_UNISWAP_V2_ROUTER, _amountsIn[0]);
                _I_UNISWAP_V2_ROUTER.swapExactTokensForTokens(_amountsIn[0], 0, _getPathWethUsdc(), address(this), block.timestamp);
            }
        } else {
            if (asset == _WETH) {
                IERC20(_WETH).approve(_UNISWAP_V2_ROUTER, amount);
                uint256[] memory _amountsOut = _I_UNISWAP_V2_ROUTER.swapExactTokensForTokens(amount, 0, _getPathWethUsdc(), address(this), block.timestamp);
                IERC20(_USDC).approve(flashloanVars.sender, _amountsOut[1]);
                IDoughV2Dsa(flashloanVars.sender).executeAction(_USDC, _amountsOut[1], _WETH, amount + flashloanVars.feeAmount + premium, flashloanVars.funcId);
                IERC20(_WETH).safeTransferFrom(flashloanVars.sender, address(this), amount + flashloanVars.feeAmount + premium);
            } else {
                IERC20(_USDC).approve(_UNISWAP_V2_ROUTER, amount);
                uint256[] memory _amountsOut = _I_UNISWAP_V2_ROUTER.swapExactTokensForTokens(amount, 0, _getPathUsdcWeth(), address(this), block.timestamp);
                IERC20(_WETH).approve(flashloanVars.sender, _amountsOut[1]);
                IDoughV2Dsa(flashloanVars.sender).executeAction(_WETH, _amountsOut[1], _USDC, amount + flashloanVars.feeAmount + premium, flashloanVars.funcId);
                IERC20(_USDC).safeTransferFrom(flashloanVars.sender, address(this), amount + flashloanVars.feeAmount + premium);
            }
        }
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
