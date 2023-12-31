// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Interfaces.sol";

contract DoughV1Dsa {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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
    constructor(address _owner, address _DoughV1Index) {
        owner = _owner;
        DoughV1Index = _DoughV1Index;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /* ========== DelegateCall ========== */
    function doughCall(uint256 _connectorId, uint256 _actionId, address _token1, address _token2, uint256 _amount, bool _opt) external payable {
        if (_connectorId == 3) {
            (, , , , , uint256 healthFactor) = aave_v3_pool.getUserAccountData(address(this));
            (, uint256 shield_dsa_hf_trigger, , ) = IDoughV1Index(DoughV1Index).getShieldInfo(address(this));
            if (healthFactor < shield_dsa_hf_trigger && _actionId == 1) {
                address SHIELD_EXECUTOR = IDoughV1Index(DoughV1Index).SHIELD_EXECUTOR();
                require(owner == msg.sender || SHIELD_EXECUTOR == msg.sender, "Ownable: caller is not the owner or Shield executor");
            } else {
                require(owner == msg.sender, "Ownable: caller is not the owner");
            }
        } else {
            require(owner == msg.sender, "Ownable: caller is not the owner");
        }
        address _contract = IDoughV1Index(DoughV1Index).getDoughV1Connector(_connectorId);
        require(_contract != address(0), "doughCall: unregistered connector");
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("delegateDoughCall(uint256,address,address,uint256,bool)", _actionId, _token1, _token2, _amount, _opt));
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    function executeAction(address loanToken, uint256 inAmount, uint256 outAmount, uint256 funcId, bool isShield) external {
        // get connectorV1Flashloan address
        address _connectorV1Flashloan = IDoughV1Index(DoughV1Index).getDoughV1Connector(3);
        require(_connectorV1Flashloan != address(0), "doughV1Dsa: executeAction : unregistered connectorV1Flashloan");

        require(msg.sender == _connectorV1Flashloan, "wrong doughFlashloan");
        IERC20(loanToken).transferFrom(_connectorV1Flashloan, address(this), inAmount);
        IERC20(loanToken).approve(AAVE_V3_POOL, inAmount);
        if (funcId == 0) {
            // Loop
            aave_v3_pool.supply(loanToken, inAmount, address(this), 0);
            aave_v3_pool.borrow(loanToken, outAmount, 2, 0, address(this));
        } else {
            // Deloop
            aave_v3_pool.repay(loanToken, inAmount, 2, address(this));
            aave_v3_pool.withdraw(loanToken, outAmount, address(this));
            if (isShield) {
                // send executor
                address SHIELD_EXECUTOR = IDoughV1Index(DoughV1Index).SHIELD_EXECUTOR();
                uint256 SHIELD_EXECUTE_FEE = IDoughV1Index(DoughV1Index).SHIELD_EXECUTE_FEE();
                IWETH(WETH).withdraw(SHIELD_EXECUTE_FEE);
                payable(SHIELD_EXECUTOR).transfer(SHIELD_EXECUTE_FEE);
            }
        }
        IERC20(loanToken).approve(_connectorV1Flashloan, outAmount);
    }
}
