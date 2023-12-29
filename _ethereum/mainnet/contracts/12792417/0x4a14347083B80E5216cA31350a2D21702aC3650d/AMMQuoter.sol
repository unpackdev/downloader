pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IUniswapExchange.sol";
import "./IUniswapFactory.sol";
import "./IUniswapRouterV2.sol";
import "./ICurveFi.sol";
import "./IWeth.sol";
import "./IPermanentStorage.sol";
import "./IUniswapV3Quoter.sol";
import "./LibBytes.sol";

/// This contract is designed to be called off-chain.
/// At T1, 4 requests would be made in order to get quote, which is for Uniswap v2, v3, Sushiswap and others.
/// For those source without path design, we can find best out amount in this contract.
/// For Uniswap and Sushiswap, best path would be calculated off-chain, we only verify out amount in this contract.

contract AMMQuoter {
    using SafeMath for uint256;
    using LibBytes for bytes;

    /* Constants */
    string public constant version = "5.2.0";
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    address public constant UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant UNISWAP_V3_QUOTER_ADDRESS = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public immutable weth;
    IPermanentStorage public immutable permStorage;

    struct GroupedVars {
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address[] path;
    }

    event CurveTokenAdded(
        address indexed makerAddress,
        address indexed assetAddress,
        int128 index
    );

    constructor (IPermanentStorage _permStorage, address _weth) public {
        permStorage = _permStorage;
        weth = _weth;
    }

    function isETH(address assetAddress) public pure returns (bool) {
        return (assetAddress == ZERO_ADDRESS || assetAddress == ETH_ADDRESS);
    }

    function getMakerOutAmountWithPath(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        address[] calldata _path,
        bytes memory _makerSpecificData
    )
        public
        returns (uint256 makerAssetAmount)
    {
        GroupedVars memory vars;
        vars.makerAddr = _makerAddr;
        vars.takerAssetAddr = _takerAssetAddr;
        vars.makerAssetAddr = _makerAssetAddr;
        vars.takerAssetAmount = _takerAssetAmount;
        vars.path = _path;
        if (vars.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            vars.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(vars.makerAddr);
            uint256[] memory amounts = router.getAmountsOut(vars.takerAssetAmount, vars.path);
            makerAssetAmount = amounts[amounts.length-1];
        } else if (vars.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            IUniswapV3Quoter quoter = IUniswapV3Quoter(UNISWAP_V3_QUOTER_ADDRESS);
            // swapType:
            // 1: exactInputSingle, 2: exactInput, 3: exactOuputSingle, 4: exactOutput
            uint8 swapType = uint8(uint256(_makerSpecificData.readBytes32(0)));
            if (swapType == 1) {
                address v3TakerInternalAsset = isETH(vars.takerAssetAddr) ? weth : vars.takerAssetAddr;
                address v3MakerInternalAsset = isETH(vars.makerAssetAddr) ? weth : vars.makerAssetAddr;
                (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
                makerAssetAmount = quoter.quoteExactInputSingle(v3TakerInternalAsset, v3MakerInternalAsset, poolFee, vars.takerAssetAmount, 0);
            } else if (swapType == 2) {
                (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
                makerAssetAmount = quoter.quoteExactInput(path, vars.takerAssetAmount);
            } else {
                revert("AMMQuoter: Invalid UniswapV3 swap type");
            }
        } else {
            address curveTakerIntenalAsset = isETH(vars.takerAssetAddr) ? ETH_ADDRESS : vars.takerAssetAddr;
            address curveMakerIntenalAsset = isETH(vars.makerAssetAddr) ? ETH_ADDRESS : vars.makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod,) = permStorage.getCurvePoolInfo(vars.makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(vars.makerAddr);
                if (swapMethod == 1) {
                    makerAssetAmount = curve.get_dy(fromTokenCurveIndex, toTokenCurveIndex, vars.takerAssetAmount).sub(1);
                } else if (swapMethod == 2) {
                    makerAssetAmount = curve.get_dy_underlying(fromTokenCurveIndex, toTokenCurveIndex, vars.takerAssetAmount).sub(1);
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return makerAssetAmount;
    }

    function getMakerOutAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    )
        public
        view
        returns (uint256)
    {
        uint256 makerAssetAmount;
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
            address[] memory path = new address[](2);
            if (isETH(_takerAssetAddr)) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (isETH(_makerAssetAddr)) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsOut(_takerAssetAmount, path);
            makerAssetAmount = amounts[1];
        } else {
            address curveTakerIntenalAsset = isETH(_takerAssetAddr) ? ETH_ADDRESS : _takerAssetAddr;
            address curveMakerIntenalAsset = isETH(_makerAssetAddr) ? ETH_ADDRESS : _makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod,) = permStorage.getCurvePoolInfo(_makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(_makerAddr);
                if (swapMethod == 1) {
                    makerAssetAmount = curve.get_dy(fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount).sub(1);
                } else if (swapMethod == 2) {
                    makerAssetAmount = curve.get_dy_underlying(fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount).sub(1);
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return makerAssetAmount;
    }

    /// @dev This function is designed for finding best out amount among AMM makers other than Uniswap and Sushiswap
    function getBestOutAmount(
        address[] calldata _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    )
        external
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 0;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 makerAssetAmount = getMakerOutAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _takerAssetAmount);
            if (makerAssetAmount > bestAmount) {
                bestAmount = makerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }

    function getTakerInAmountWithPath(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount,
        address[] calldata _path,
        bytes memory _makerSpecificData
    )
        public
        returns (uint256 takerAssetAmount)
    {
        GroupedVars memory vars;
        vars.makerAddr = _makerAddr;
        vars.takerAssetAddr = _takerAssetAddr;
        vars.makerAssetAddr = _makerAssetAddr;
        vars.makerAssetAmount = _makerAssetAmount;
        vars.path = _path;
        if (vars.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            vars.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(vars.makerAddr);
            uint256[] memory amounts = router.getAmountsIn(vars.makerAssetAmount, _path);
            takerAssetAmount = amounts[0];
        } else if (vars.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            IUniswapV3Quoter quoter = IUniswapV3Quoter(UNISWAP_V3_QUOTER_ADDRESS);
            // swapType:
            // 1: exactInputSingle, 2: exactInput, 3: exactOuputSingle, 4: exactOutput
            uint8 swapType = uint8(uint256(_makerSpecificData.readBytes32(0)));
            if (swapType == 3) {
                address v3TakerInternalAsset = isETH(vars.takerAssetAddr) ? weth : vars.takerAssetAddr;
                address v3MakerInternalAsset = isETH(vars.makerAssetAddr) ? weth : vars.makerAssetAddr;
                (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
                takerAssetAmount = quoter.quoteExactOutputSingle(v3TakerInternalAsset, v3MakerInternalAsset, poolFee, vars.makerAssetAmount, 0);
            } else if (swapType == 4) {
                (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
                takerAssetAmount = quoter.quoteExactOutput(path, vars.makerAssetAmount);
            } else {
                revert("AMMQuoter: Invalid UniswapV3 swap type");
            }
        } else {
            address curveTakerIntenalAsset = isETH(vars.takerAssetAddr) ? ETH_ADDRESS : vars.takerAssetAddr;
            address curveMakerIntenalAsset = isETH(vars.makerAssetAddr) ? ETH_ADDRESS : vars.makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, bool supportGetDx) = permStorage.getCurvePoolInfo(vars.makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(vars.makerAddr);
                if (supportGetDx) {
                    if (swapMethod == 1) {
                        takerAssetAmount = curve.get_dx(fromTokenCurveIndex, toTokenCurveIndex, vars.makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dx_underlying(fromTokenCurveIndex, toTokenCurveIndex, vars.makerAssetAmount);
                    }
                } else {
                    if (swapMethod == 1) {
                        // does not support get_dx_underlying, try to get an estimated rate here
                        takerAssetAmount = curve.get_dy(toTokenCurveIndex, fromTokenCurveIndex, vars.makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dy_underlying(toTokenCurveIndex, fromTokenCurveIndex, vars.makerAssetAmount);
                    }
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return takerAssetAmount;
    }

    function getTakerInAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    )
        public
        view
        returns (uint256)
    {
        uint256 takerAssetAmount;
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
            address[] memory path = new address[](2);
            if (isETH(_takerAssetAddr)) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (isETH(_makerAssetAddr)) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsIn(_makerAssetAmount, path);
            takerAssetAmount = amounts[0];
        } else {
            address curveTakerIntenalAsset = isETH(_takerAssetAddr) ? ETH_ADDRESS : _takerAssetAddr;
            address curveMakerIntenalAsset = isETH(_makerAssetAddr) ? ETH_ADDRESS : _makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, bool supportGetDx) = permStorage.getCurvePoolInfo(_makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(_makerAddr);
                if (supportGetDx) {
                    if (swapMethod == 1) {
                        takerAssetAmount = curve.get_dx(fromTokenCurveIndex, toTokenCurveIndex, _makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dx_underlying(fromTokenCurveIndex, toTokenCurveIndex, _makerAssetAmount);
                    }
                } else {
                    if (swapMethod == 1) {
                        // does not support get_dx_underlying, try to get an estimated rate here
                        takerAssetAmount = curve.get_dy(toTokenCurveIndex, fromTokenCurveIndex, _makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dy_underlying(toTokenCurveIndex, fromTokenCurveIndex, _makerAssetAmount);
                    }
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return takerAssetAmount;
    }

    /// @dev This function is designed for finding best in amount among AMM makers other than Uniswap and Sushiswap
    function getBestInAmount(
        address[] calldata _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    )
        external
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 2**256 - 1;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 takerAssetAmount = getTakerInAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _makerAssetAmount);
            if (takerAssetAmount < bestAmount) {
                bestAmount = takerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }
}
