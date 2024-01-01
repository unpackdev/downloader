// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./INineInchFactory.sol";
import "./INineInchPair.sol";
import "./ERC20Burnable.sol";

// NineInchBuyAndBurn is a contract that converts received LP tokens from platform fees for NineInch and then burns it.
// The caller of convertLps, the function responsible for converting fees to NineInch earns a 0.1% reward for calling.
contract NineInchBuyAndBurnUpgradeable is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    INineInchFactory public factory;
    ERC20Burnable public BBC;
    ERC20Burnable public NineInch;

    address public WETH;
    uint public BOUNTY_FEE;
    uint public slippage;
    uint256 constant TAX_DIVISOR = 10000;
    uint public NineInchBuyBurnPercentage;
    uint public BBCBuyBurnPercentage;
    uint public burnedNineInch;
    uint public burnedBBC;

    // set of addresses that can perform certain functions
    mapping(address => bool) public isAuth;
    address[] public authorized;
    bool public anyAuth;

    modifier onlyAuth() {
        require(isAuth[_msgSender()], "NineInchBuyAndBurn: FORBIDDEN");
        _;
    }

    // C6: It"s not a fool proof solution, but it prevents flash loans, so here it"s ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "NineInchBuyAndBurn: must use EOA");
        _;
    }

    mapping(address => address) internal _bridges;
    mapping(address => uint) internal converted;
    mapping(address => bool) public overridePreventSwap;
    mapping(address => bool) public slippageOverrode;

    event LogBridgeSet(address indexed token, address indexed bridge);
    event LogBurn(
        address indexed server,
        address indexed token,
        uint256 paidBounty,
        uint256 amountBurned
    );
    event ToggleAnyAuth();
    event LogOverridePreventSwap(address _adr);
    event LogSlippageOverrode(address _adr);

    function initialize(
        address _factory,
        ERC20Burnable _NineInch,
        ERC20Burnable _BBC,
        address _WETH
    ) public initializer {
        factory = INineInchFactory(_factory);
        NineInch = _NineInch;
        BBC = _BBC;
        WETH = _WETH;
        isAuth[msg.sender] = true;
        authorized.push(msg.sender);
        BOUNTY_FEE = 10;
        slippage = 9;
        anyAuth = false;
        NineInchBuyBurnPercentage = 8571;
        BBCBuyBurnPercentage = 1429;
        burnedNineInch = 0;
        burnedBBC = 0;
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setBuyBurnPercentages(
        uint _NineInchBuyBurnPercentage,
        uint _BBCBuyBurnPercentage
    ) external onlyOwner {
        require(
            _NineInchBuyBurnPercentage + _BBCBuyBurnPercentage <= TAX_DIVISOR,
            "BuyBurn percentage must be lower than or equal to 100%"
        );
        NineInchBuyBurnPercentage = _NineInchBuyBurnPercentage;
        BBCBuyBurnPercentage = _BBCBuyBurnPercentage;
    }

    // Begin Owner functions
    function addAuth(address _auth) external onlyOwner {
        isAuth[_auth] = true;
        authorized.push(_auth);
    }

    function revokeAuth(address _auth) external onlyOwner {
        isAuth[_auth] = false;
    }

    // setting anyAuth to true allows anyone to call convertMultiple permanently
    function setAnyAuth() external onlyOwner {
        anyAuth = !anyAuth;
        emit ToggleAnyAuth();
    }

    function setBounty(uint _amount) external onlyOwner {
        require(_amount <= 5000, "setBounty: bounty too high");
        BOUNTY_FEE = _amount;
    }

    // End owner functions

    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = WETH;
        }
    }

    // onlyAuth type functions

    function overrideSlippage(address _token) external onlyAuth {
        slippageOverrode[_token] = !slippageOverrode[_token];
        emit LogSlippageOverrode(_token);
    }

    function toggleOverridePreventSwap(address _token) external onlyAuth {
        overridePreventSwap[_token] = !overridePreventSwap[_token];
        emit LogOverridePreventSwap(_token);
    }

    function setSlippage(uint _amt) external onlyAuth {
        require(_amt < 20, "slippage setting too high"); // the higher this setting, the lower the slippage tolerance, too high and buybacks would never work
        slippage = _amt;
    }

    function setBridge(address token, address bridge) external onlyAuth {
        // Checks
        require(
            token != address(NineInch) && token != WETH && token != bridge,
            "NineInchBuyAndBurn: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    function isLpToken(address possibleLP) internal view returns (bool valid) {
        (bool success0, bytes memory result0) = possibleLP.staticcall(
            abi.encodeWithSelector(INineInchPair.token0.selector)
        );
        if (success0 && result0.length != 0) {
            (bool success1, bytes memory result1) = possibleLP.staticcall(
                abi.encodeWithSelector(INineInchPair.token1.selector)
            );
            if (success1 && result1.length != 0) {
                address token0 = abi.decode(result0, (address));
                address token1 = abi.decode(result1, (address));
                address validPair;
                (validPair, valid) = _getValidPair(token0, token1);
                return valid && validPair == possibleLP;
            }
            return false;
        } else {
            return false;
        }
    }

    function _getValidPair(
        address token0,
        address token1
    ) internal view returns (address, bool) {
        (address t0, address t1) = token0 < token1
            ? (token0, token1)
            : (token1, token0);
        address realPair = factory.getPair(t0, t1);
        // check if newly derived pair is the same as the address passed in
        return (realPair, realPair != address(0));
    }

    function convertLps(
        address[] calldata tokens0,
        address[] calldata tokens1
    ) external onlyEOA nonReentrant {
        require(
            anyAuth || isAuth[_msgSender()],
            "NineInchBuyAndBurn: FORBIDDEN"
        );
        uint len = tokens0.length;
        uint i;
        require(len == tokens1.length, "NineInchBuyAndBurn: list mismatch");
        for (i = 0; i < len; i++) {
            (address token0, address token1) = (tokens0[i], tokens1[i]);
            require(token0 != token1, "NineInchBuyAndBurn: tokens match");
            (address lp, bool valid) = _getValidPair(token0, token1);
            require(valid, "NineInchBuyAndBurn: Invalid pair");
            INineInchPair pair = INineInchPair(lp);
            uint bal = pair.balanceOf(address(this));
            if (bal > 0) {
                pair.transfer(lp, bal);
                pair.burn(address(this));
            }
        }
        // recursively swap originating tokens toward WETH/NineInch
        // without swapping to WETH directly. This line skips all WETH attempts
        converted[WETH] = block.number;
        for (i = 0; i < len; i++) {
            (address token0, address token1) = (tokens0[i], tokens1[i]);
            if (block.number > converted[token0]) {
                _convertStep(
                    token0,
                    IERC20Upgradeable(token0).balanceOf(address(this))
                );
                converted[token0] = block.number;
            }
            if (block.number > converted[token1]) {
                _convertStep(
                    token1,
                    IERC20Upgradeable(token1).balanceOf(address(this))
                );
                converted[token1] = block.number;
            }
        }

        // final step is to swap all WETH to 9Inch and BBC and burn it
        uint wethBal = IERC20(WETH).balanceOf(address(this));
        if (wethBal > 0) {
            uint256 NineInchAmount = (wethBal * NineInchBuyBurnPercentage) /
                TAX_DIVISOR;
            uint256 BBCAmount = (wethBal * BBCBuyBurnPercentage) / TAX_DIVISOR;
            _swapFromTo(WETH, address(NineInch), NineInchAmount);
            _swapFromTo(WETH, address(BBC), BBCAmount);
        }
        _burnTokens(address(NineInch));
        _burnTokens(address(BBC));
    }

    // internal functions
    function _convertStep(address token, uint256 amount0) internal {
        uint256 amount = amount0;
        if (amount0 > 0 && token != address(NineInch) && token != WETH) {
            bool isLP = isLpToken(token);
            if (!isLP && !overridePreventSwap[token]) {
                address bridge = bridgeFor(token);
                amount = _swap(token, bridge, amount0, address(this));
                _convertStep(bridge, amount);
            }
        }
    }

    function _burnTokens(address token) internal returns (uint amount) {
        uint _amt = IERC20Upgradeable(token).balanceOf(address(this));
        uint bounty;
        if (BOUNTY_FEE > 0) {
            bounty = _amt.mul(BOUNTY_FEE).div(10000);
            amount = _amt.sub(bounty);
            IERC20Upgradeable(token).safeTransfer(_msgSender(), bounty); // send message sender their share of 0.1%
        }

        if (token == address(BBC)) {
            BBC.burn(amount);
            burnedBBC += amount;
        } else {
            NineInch.burn(amount);
            burnedNineInch += amount;
        }

        emit LogBurn(_msgSender(), token, bounty, amount);
    }

    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {
        INineInchPair pair = INineInchPair(factory.getPair(fromToken, toToken));
        require(
            address(pair) != address(0),
            "NineInchBuyAndBurn: Cannot convert"
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = fromToken == pair.token0()
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        IERC20Upgradeable(fromToken).safeTransfer(address(pair), amountIn);
        uint amountInput = IERC20Upgradeable(fromToken)
            .balanceOf(address(pair))
            .sub(reserveInput); // calculate amount that was transferred, this accounts for transfer taxes
        require(
            slippageOverrode[fromToken] ||
                reserveInput.div(amountInput) > slippage,
            "NineInchBuyAndBurn: high slippage"
        );

        amountOut = _getAmountOut(amountInput, reserveInput, reserveOutput);
        (uint amount0Out, uint amount1Out) = fromToken == pair.token0()
            ? (uint(0), amountOut)
            : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function _swapFromTo(
        address fromToken,
        address toToken,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        amountOut = _swap(fromToken, toToken, amountIn, address(this));
    }

    function _getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "NineInchBuyAndBurn: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "NineInchBuyAndBurn: INSUFFICIENT_LIQUIDITY"
        );
        uint amountInWithFee = amountIn.mul(9971);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
