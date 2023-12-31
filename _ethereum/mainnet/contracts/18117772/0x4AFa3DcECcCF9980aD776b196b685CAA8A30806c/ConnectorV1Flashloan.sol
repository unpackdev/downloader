// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IPool.sol";
import "./FlashLoanSimpleReceiverBase.sol";

import "./Interfaces.sol";

contract ConnectorV1Flashloan is FlashLoanSimpleReceiverBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event Log(string message, uint256 val);

    /* ========== Layout ========== */
    address public owner;
    address public DoughV1Index = address(0);

    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address private constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    IAaveV3Pool private aave_v3_pool = IAaveV3Pool(AAVE_V3_POOL);

    address private constant AAVE_V3_DATA_PROVIDER = 0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3;
    IAaveV3DataProvider private aave_v3_data_provider = IAaveV3DataProvider(AAVE_V3_DATA_PROVIDER);

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router private uniswap_v2_router = IUniswapV2Router(UNISWAP_V2_ROUTER);

    /* ========== CONSTRUCTOR ========== */
    constructor(IPoolAddressesProvider provider, address _doughV1Index) FlashLoanSimpleReceiverBase(provider) {
        DoughV1Index = _doughV1Index;
    }

    function getOwner() public view returns (address) {
        return IDoughV1Index(DoughV1Index).owner();
    }

    bytes32 internal dataHash = bytes32(0);
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status = 1;

    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(dataHash_ == dataHash && dataHash_ != bytes32(0), "invalid-data-hash");
        require(status == 2, "already-entered3");
        dataHash = bytes32(0);
        _;
        status = 1;
    }
    modifier reentrancy() {
        require(status == 1, "already-entered1");
        status = 2;
        _;
        require(status == 1, "already-entered2");
    }

    //  tokenAmount = _tokenAmount[user][tokenAddress]
    // mapping(address => mapping(address => uint256)) private _tokenAmount;

    // delegate Call
    function delegateDoughCall(uint256 _actionId, address _token1, address _token2, uint256 _amount, bool _opt) external {
        //  Loop: _actionId = 0 , DeLoop: _actionId = 1;
        require(_actionId < 2, "ConnectorV1Flashloan : invalid id");
        require(_token1 == WETH || _token1 == WBTC, "ConnectorV1Flashloan : invalid token.");
        require(_token1 == _token2, "ConnectorV1Flashloan: invalid token2");
        require(_amount > 0, "ConnectorV1Flashloan : invalid amount.");

        // get connectorV1Flashloan address
        address _connectorV1Flashloan = IDoughV1Index(DoughV1Index).getDoughV1Connector(3);
        require(_connectorV1Flashloan != address(0), "doughV1Dsa: doughLoopAndDeloop : unregistered connectorV1Flashloan");

        // get Position
        (uint256 currentATokenBalance, , uint256 currentVariableDebt, , , , , , ) = aave_v3_data_provider.getUserReserveData(_token1, address(this));

        uint256 flashloanAmount = _amount;
        bool isShield = false;
        if (_actionId == 0) {
            require(currentATokenBalance > 0, "doughV1Dsa : supply first to AaveV3");
        } else if (_actionId == 1) {
            require(currentVariableDebt > 0, "doughV1Dsa : Loop first");
            require(flashloanAmount <= currentVariableDebt, "doughV1Dsa : flashloanAmount must be less than Debt");
            if (_opt) {
                flashloanAmount = currentVariableDebt;
            }
            address SHIELD_EXECUTOR = IDoughV1Index(DoughV1Index).SHIELD_EXECUTOR();
            if (msg.sender == SHIELD_EXECUTOR) {
                isShield = true;
            }
        }
        IConnectorV1Flashloan(_connectorV1Flashloan).flashloanReq(_token1, flashloanAmount, _actionId, isShield);
    }

    function flashloanReq(address _loanToken, uint256 _loanAmount, uint256 _funcId, bool _isShield) external reentrancy {
        //  Loop: funcId = 0 , DeLoop: funcId = 1;
        require(_funcId == 0 || _funcId == 1, "flashloanReq : invalid-id");
        bytes memory data = abi.encode(msg.sender, _loanToken, _loanAmount, _funcId, _isShield);
        dataHash = bytes32(keccak256(data));
        IPool(address(POOL)).flashLoanSimple(address(this), _loanToken, _loanAmount, data, 0);
    }

    struct FlashloanVars {
        address sender;
        uint256 funcId;
        bool isShield;
        uint256 flashLoanFeeAmount;
        uint256 shield_executor_asset_amount;
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes memory data) public verifyDataHash(data) returns (bool) {
        require(initiator == address(this), "not-same-sender");
        require(msg.sender == address(POOL), "not-aave-sender");

        FlashloanVars memory flashloanVars;

        (flashloanVars.sender, , , flashloanVars.funcId, flashloanVars.isShield) = abi.decode(data, (address, address, uint256, uint256, bool));
        //  Loop: funcId = 0 , DeLoop: funcId = 1;
        require(flashloanVars.funcId == 0 || flashloanVars.funcId == 1, "invalid-id");

        // calc fee amount to treasury
        flashloanVars.flashLoanFeeAmount = (amount * IDoughV1Index(DoughV1Index).FLASHLOAN_FEE()) / 10000;

        //------- swap asset to eth by uniswapv2 and send to shield executor -------
        flashloanVars.shield_executor_asset_amount = 0;
        if (flashloanVars.isShield) {
            uint256 SHIELD_EXECUTE_FEE = IDoughV1Index(DoughV1Index).SHIELD_EXECUTE_FEE();
            if (asset == WETH) {
                flashloanVars.shield_executor_asset_amount = SHIELD_EXECUTE_FEE;
            } else {
                IERC20(asset).approve(address(uniswap_v2_router), amount);
                address[] memory path;
                path = new address[](2);
                path[0] = asset;
                path[1] = WETH;
                uint256[] memory amounts = uniswap_v2_router.swapTokensForExactTokens(SHIELD_EXECUTE_FEE, amount, path, address(this), block.timestamp);
                flashloanVars.shield_executor_asset_amount = amounts[0];
            }
            IERC20(WETH).transfer(flashloanVars.sender, SHIELD_EXECUTE_FEE);
        }
        //------- Custom Logic Start ---------
        IERC20(asset).approve(flashloanVars.sender, amount - flashloanVars.shield_executor_asset_amount);
        IDoughV1Dsa(flashloanVars.sender).executeAction(asset, amount - flashloanVars.shield_executor_asset_amount, amount + flashloanVars.flashLoanFeeAmount + premium, flashloanVars.funcId, flashloanVars.isShield);
        IERC20(asset).transferFrom(flashloanVars.sender, address(this), amount + flashloanVars.flashLoanFeeAmount + premium);
        //------- Custom Logic End   ---------

        // pay back the loan amount and the premium (flashloan fee)
        IERC20(asset).approve(address(POOL), amount.add(premium));

        IERC20(asset).transfer(IDoughV1Index(DoughV1Index).TREASURY(), flashloanVars.flashLoanFeeAmount);

        emit Log("borrowed amount", amount);
        emit Log("flashloan fee", premium);
        emit Log("dough fee", flashloanVars.flashLoanFeeAmount);
        emit Log("amountToReturn", amount.add(premium));
        return true;
    }
}
