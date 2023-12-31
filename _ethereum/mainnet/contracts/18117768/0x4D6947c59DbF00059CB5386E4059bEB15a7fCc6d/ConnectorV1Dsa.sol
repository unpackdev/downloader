// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Interfaces.sol";

// ConnectorId : 0
contract ConnectorV1Dsa {
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
    constructor(address _DoughV1Index) {
        DoughV1Index = _DoughV1Index;
    }

    /* ========== FUNCTIONS ========== */
    function getOwner() public view returns (address) {
        return IDoughV1Index(DoughV1Index).owner();
    }

    function withdrawToken(address _tokenAddr, uint256 _amount) external {
        require(msg.sender == getOwner(), "ConnectorV1Dsa: not owner of DoughV1Index");
        require(_amount > 0 && _amount <= IERC20(_tokenAddr).balanceOf(address(this)), "ConnectorV1Dsa:withdrawTokenFromDsa: invalid amount");
        IERC20(_tokenAddr).transfer(getOwner(), _amount);
    }

    // delegate Call
    function delegateDoughCall(uint256 _actionId, address _token1, address _token2, uint256 _amount, bool _opt) external payable {
        require(_amount > 0, "ConnectorV1Dsa: invalid amount");
        require(_actionId < 4, "ConnectorV1Dsa: invalid actionId");
        require(_token1 != address(0), "ConnectorV1Dsa: invalid token1");
        require(_token1 == _token2, "ConnectorV1Dsa: invalid token2");
        require(!_opt, "ConnectorV1Dsa: invalid option");

        if (_actionId == 0) {
            // depositEthToDsa
            require(_token1 == ETH, "ConnectorV1Dsa: depositEthToDsa: invalid token");
            require(msg.value > 0, "ConnectorV1Dsa: invalid msg.value");
            IWETH(WETH).deposit{value: msg.value}();
        } else if (_actionId == 1) {
            // depositTokenToDsa
            IERC20(_token1).transferFrom(owner, address(this), _amount);
        } else if (_actionId == 2) {
            // withdrawEthFromDsa
            require(_token1 == ETH, "ConnectorV1Dsa: withdrawEthFromDsa: invalid token");
            require(_amount <= address(this).balance, "ConnectorV1Dsa: withdrawEthFromDsa: invalid amount");
            payable(owner).transfer(_amount);
        } else if (_actionId == 3) {
            // withdrawTokenFromDsa
            require(_amount <= IERC20(_token1).balanceOf(address(this)), "ConnectorV1Dsa: withdrawTokenFromDsa: invalid amount");
            if (_token1 == WETH) {
                IWETH(WETH).withdraw(_amount);
                payable(owner).transfer(_amount);
            } else {
                IERC20(_token1).transfer(owner, _amount);
            }
        }
    }
}
