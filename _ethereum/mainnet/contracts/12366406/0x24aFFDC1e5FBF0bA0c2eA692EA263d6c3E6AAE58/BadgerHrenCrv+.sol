// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./SinglePlus.sol";
import "./IConverter.sol";
import "./ICurveFi.sol";
import "./IBadgerSett.sol";
import "./IBadgerTree.sol";
import "./IUniswapRouter.sol";

/**
 * @dev Single plus for Badger hrenCrv.
 */
contract BadgerHrenCrvPlus is SinglePlus {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    address public constant BADGER_HRENCRV = address(0xAf5A1DECfa95BAF63E0084a35c62592B774A2A87);
    address public constant BADGER_TREE = address(0x660802Fc641b154aBA66a62137e71f331B6d787A);
    address public constant WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant BADGER = address(0x3472A5A71965499acd81997a54BBA8D852C6E53d);
    address public constant DIGG = address(0x798D1bE841a82a273720CE31c822C61a67a601C3);
    address public constant FARM = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
    address public constant RENCRV = address(0x49849C98ae39Fff122806C06791Fa73784FB3675);
    address public constant UNISWAP = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // Uniswap RouterV2
    address public constant REN_SWAP = address(0x93054188d876f558f4a66B2EF1d97d16eDf0895B); // REN swap

    /**
     * We use a converter to convert renCrv --> bhrenCrv because bhrenCrv has a whitelist.
     * Therefore, we use a converter to facilitate testing bhrenCrv+.
     * Once bhrenCrv+ is whitelisted, we will upgrade the contract to replace the converter.
     */
    address public converter;

    /**
     * @dev Initializes bhrenCrv+.
     */
    function initialize(address _converter) public initializer {
        SinglePlus.initialize(BADGER_HRENCRV, "", "");

        converter = _converter;
    }

    /**
     * @dev Harvest additional yield from the investment.
     * Only governance or strategist can call this function.
     */
    function harvest(address[] calldata _tokens, uint256[] calldata _cumulativeAmounts, uint256 _index, uint256 _cycle,
        bytes32[] calldata _merkleProof, uint256[] calldata _amountsToClaim) public virtual onlyStrategist {
        // 1. Harvest from Badger Tree
        IBadgerTree(BADGER_TREE).claim(_tokens, _cumulativeAmounts, _index, _cycle, _merkleProof, _amountsToClaim);

        // 2. Badger --> WETH --> WBTC
        uint256 _badger = IERC20Upgradeable(BADGER).balanceOf(address(this));
        if (_badger > 0) {
            IERC20Upgradeable(BADGER).safeApprove(UNISWAP, 0);
            IERC20Upgradeable(BADGER).safeApprove(UNISWAP, _badger);

            address[] memory _path = new address[](3);
            _path[0] = BADGER;
            _path[1] = WETH;
            _path[2] = WBTC;

            IUniswapRouter(UNISWAP).swapExactTokensForTokens(_badger, uint256(0), _path, address(this), block.timestamp.add(1800));
        }

        // 3: Digg --> WBTC
        uint256 _digg = IERC20Upgradeable(DIGG).balanceOf(address(this));
        if (_digg > 0) {
            IERC20Upgradeable(DIGG).safeApprove(UNISWAP, 0);
            IERC20Upgradeable(DIGG).safeApprove(UNISWAP, _digg);

            address[] memory _path = new address[](2);
            _path[0] = DIGG;
            _path[1] = WBTC;

            IUniswapRouter(UNISWAP).swapExactTokensForTokens(_digg, uint256(0), _path, address(this), block.timestamp.add(1800));
        }

        // 4. Farm --> WETH --> WBTC
        uint256 _farm = IERC20Upgradeable(FARM).balanceOf(address(this));
        if (_farm > 0) {
            IERC20Upgradeable(FARM).safeApprove(UNISWAP, 0);
            IERC20Upgradeable(FARM).safeApprove(UNISWAP, _farm);

            address[] memory _path = new address[](3);
            _path[0] = FARM;
            _path[1] = WETH;
            _path[2] = WBTC;

            IUniswapRouter(UNISWAP).swapExactTokensForTokens(_farm, uint256(0), _path, address(this), block.timestamp.add(1800));
        }

        // 5: WBTC --> renCrv
        uint256 _wbtc = IERC20Upgradeable(WBTC).balanceOf(address(this));
        if (_wbtc == 0) return;

        // If there is performance fee, charged in WBTC
        uint256 _fee = 0;
        if (performanceFee > 0) {
            _fee = _wbtc.mul(performanceFee).div(PERCENT_MAX);
            IERC20Upgradeable(WBTC).safeTransfer(treasury, _fee);
            _wbtc = _wbtc.sub(_fee);
        }

        IERC20Upgradeable(WBTC).safeApprove(REN_SWAP, 0);
        IERC20Upgradeable(WBTC).safeApprove(REN_SWAP, _wbtc);
        ICurveFi(REN_SWAP).add_liquidity([0, _wbtc], 0);

        // 5: renCrv --> bhrenCrv
        address _converter = converter;
        uint256 _hrenCrv = IERC20Upgradeable(RENCRV).balanceOf(address(this));
        IERC20Upgradeable(RENCRV).safeApprove(_converter, 0);
        IERC20Upgradeable(RENCRV).safeApprove(_converter, _hrenCrv);

        uint256 _before = IERC20Upgradeable(BADGER_HRENCRV).balanceOf(address(this));
        uint256 _target = _hrenCrv.mul(WAD).div(IBadgerSett(BADGER_HRENCRV).getPricePerFullShare());
        IConverter(_converter).convert(RENCRV, BADGER_HRENCRV, _hrenCrv, _target);
        uint256 _after = IERC20Upgradeable(BADGER_HRENCRV).balanceOf(address(this));
        require(_after >= _before.add(_target), "convert fail");

        // Also it's a good time to rebase!
        rebase();

        emit Harvested(BADGER_HRENCRV, _wbtc, _fee);
    }

    /**
     * @dev Returns the amount of single plus token is worth for one underlying token, expressed in WAD.
     */
    function _conversionRate() internal view virtual override returns (uint256) {
        // Both Badger's share price and Curve's virtual price are in WAD
        return IBadgerSett(BADGER_HRENCRV).getPricePerFullShare().mul(ICurveFi(REN_SWAP).get_virtual_price()).div(WAD);
    }
}