//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "./SafeERC20.sol";
import "./AbstractAdapter.sol";

interface ISetToken {
    function getComponents() external view returns (address[] memory);
    function isInitializedModule(address _module) external view returns (bool);
}

interface IBasicIssuanceModule {
    function redeem(address _setToken, uint256 _quantity, address _to) external;
}

/// @title Token Sets Vampire Attack Contract
/// @author Enso.finance (github.com/EnsoFinance)
/// @notice Adapter for redeeming the underlying assets from Token Sets

contract TokenSetAdapter is AbstractAdapter {
    using SafeERC20 for IERC20;

    address public genericRouter;
    address public leverageAdapter;
    IBasicIssuanceModule public basicModule;
    mapping (address => bool) private _leveraged;

    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant ETH2X = 0xAa6E8127831c9DE45ae56bB1b0d4D4Da6e5665BD;
    address private constant BTC2X = 0x0B498ff89709d3838a063f1dFA463091F9801c2b;
    address private constant AWETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address private constant AWBTC = 0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656;

    constructor(
        IBasicIssuanceModule basicModule_,
        address leverageAdapter_,
        address genericRouter_,
        address owner_
    ) AbstractAdapter(owner_)
    {
        basicModule = basicModule_;
        leverageAdapter = leverageAdapter_;
        genericRouter = genericRouter_;
        _leveraged[ETH2X] = true;
        _leveraged[BTC2X] = true;
    }

    function updateGenericRouter(address _genericRouter) external onlyOwner {
        require(_genericRouter != genericRouter, "Already exists");
        genericRouter = _genericRouter;
    }

    function updateLeverageAdapter(address _leverageAdapter) external onlyOwner {
        require(_leverageAdapter != leverageAdapter, "Already exists");
        leverageAdapter = _leverageAdapter;
    }

    function outputTokens(address _lp)
        public
        view
        override
        returns (address[] memory)
    {
        /*
        if (_leveraged[_lp]) {
            address[] memory outputs = new address[](1);
            if (_lp == ETH2X) outputs[0] = WETH;
            if (_lp == BTC2X) outputs[0] = WBTC;
            return outputs;
        }
        */
        return ISetToken(_lp).getComponents();
    }

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        public
        override
        view
        onlyWhitelisted(_lp)
        returns (Call[] memory calls)
    {
        if (_leveraged[_lp]) {
          calls = new Call[](3);
          Call[] memory withdrawCalls = encodeWithdraw(_lp, _amount);
          calls[0] = withdrawCalls[0];
          calls[1] = withdrawCalls[1];
          if (_lp == ETH2X) {
              calls[2] = Call(
                  _genericRouter,
                  abi.encodeWithSelector(
                      IGenericRouter(_genericRouter).settleSwap.selector,
                      leverageAdapter,
                      WETH,
                      AWETH,
                      _genericRouter,
                      _strategy
                  )
              );
          }
          if (_lp == BTC2X) {
              calls[2] = Call(
                  _genericRouter,
                  abi.encodeWithSelector(
                      IGenericRouter(_genericRouter).settleSwap.selector,
                      leverageAdapter,
                      WBTC,
                      AWBTC,
                      _genericRouter,
                      _strategy
                  )
              );
          }
        } else {
          address[] memory tokens = outputTokens(_lp);
          calls = new Call[](tokens.length + 1);
          calls[0] = encodeWithdraw(_lp, _amount)[0];
          for (uint256 i = 0; i < tokens.length; i++) {
              calls[i + 1] = Call(
                  _genericRouter,
                  abi.encodeWithSelector(
                      IGenericRouter(_genericRouter).settleTransfer.selector,
                      tokens[i],
                      _strategy
                  )
              );
          }
        }

        return calls;
    }

    function encodeWithdraw(address _lp, uint256 _amount)
        public
        override
        view
        onlyWhitelisted(_lp)
        returns (Call[] memory calls)
    {
        if (_leveraged[_lp]) {
            // Redeem debt is too complicated. Just sell the token
            calls = new Call[](2);
            calls[0] = Call(
                _lp,
                abi.encodeWithSelector(
                    IERC20(_lp).approve.selector,
                    UNI_V3,
                    _amount
                )
            );
            if (_lp == ETH2X) {
                calls[1] = Call(
                    UNI_V3,
                    abi.encodeWithSelector(
                        IUniswapV3Router(UNI_V3).exactInputSingle.selector,
                        IUniswapV3Router.ExactInputSingleParams(
                            ETH2X,
                            WETH,
                            3000,
                            genericRouter,
                            block.timestamp + 1,
                            _amount,
                            1,
                            0
                        )
                    )
                );
            }
            if (_lp == BTC2X) {
                calls[1] = Call(
                    UNI_V3,
                    abi.encodeWithSelector(
                        IUniswapV3Router(UNI_V3).exactInputSingle.selector,
                        IUniswapV3Router.ExactInputSingleParams(
                            BTC2X,
                            WBTC,
                            10000,
                            genericRouter,
                            block.timestamp + 1,
                            _amount,
                            1,
                            0
                        )
                    )
                );
            }
        } else {
            calls = new Call[](1);
            calls[0] = Call(
                address(basicModule),
                abi.encodeWithSelector(
                    basicModule.redeem.selector,
                    _lp,
                    _amount,
                    genericRouter
                )
            );
        }
    }
}
