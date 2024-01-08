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
 * @dev Single plus for Badger renCrv.
 */
contract BadgerRenCrvPlus is SinglePlus {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    address public constant BADGER_RENCRV = address(0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545);
    address public constant BADGER_TREE = address(0x660802Fc641b154aBA66a62137e71f331B6d787A);
    address public constant WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant BADGER = address(0x3472A5A71965499acd81997a54BBA8D852C6E53d);
    address public constant DIGG = address(0x798D1bE841a82a273720CE31c822C61a67a601C3);
    address public constant RENCRV = address(0x49849C98ae39Fff122806C06791Fa73784FB3675);
    address public constant UNISWAP = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // Uniswap RouterV2
    address public constant SUSHISWAP = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);    // Sushiswap RouterV2
    address public constant REN_SWAP = address(0x93054188d876f558f4a66B2EF1d97d16eDf0895B); // REN swap

    /**
     * We use a converter to convert renCrv --> brenCrv because brenCrv has a whitelist.
     * Therefore, we use a converter to facilitate testing brenCrv+.
     * Once brenCrv+ is whitelisted, we will upgrade the contract to replace the converter.
     */
    address public converter;

    /**
     * @dev Initializes brenCrv+.
     */
    function initialize(address _converter) public initializer {
        SinglePlus.initialize(BADGER_RENCRV, "", "");

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

        // 2. Sushi: Badger --> WBTC
        uint256 _badger = IERC20Upgradeable(BADGER).balanceOf(address(this));
        if (_badger > 0) {
            IERC20Upgradeable(BADGER).safeApprove(SUSHISWAP, 0);
            IERC20Upgradeable(BADGER).safeApprove(SUSHISWAP, _badger);

            address[] memory _path = new address[](2);
            _path[0] = BADGER;
            _path[1] = WBTC;

            IUniswapRouter(SUSHISWAP).swapExactTokensForTokens(_badger, uint256(0), _path, address(this), block.timestamp.add(1800));
        }

        // 3: Uniswap: Digg --> WBTC
        uint256 _digg = IERC20Upgradeable(DIGG).balanceOf(address(this));
        if (_digg > 0) {
            IERC20Upgradeable(DIGG).safeApprove(UNISWAP, 0);
            IERC20Upgradeable(DIGG).safeApprove(UNISWAP, _digg);

            address[] memory _path = new address[](2);
            _path[0] = DIGG;
            _path[1] = WBTC;

            IUniswapRouter(UNISWAP).swapExactTokensForTokens(_digg, uint256(0), _path, address(this), block.timestamp.add(1800));
        }

        // 4: WBTC --> renCrv
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

        // 5: renCrv --> brenCrv
        address _converter = converter;
        uint256 _renCrv = IERC20Upgradeable(RENCRV).balanceOf(address(this));
        IERC20Upgradeable(RENCRV).safeApprove(_converter, 0);
        IERC20Upgradeable(RENCRV).safeApprove(_converter, _renCrv);

        uint256 _before = IERC20Upgradeable(BADGER_RENCRV).balanceOf(address(this));
        uint256 _target = _renCrv.mul(WAD).div(IBadgerSett(BADGER_RENCRV).getPricePerFullShare());
        IConverter(_converter).convert(RENCRV, BADGER_RENCRV, _renCrv, _target);
        uint256 _after = IERC20Upgradeable(BADGER_RENCRV).balanceOf(address(this));
        require(_after >= _before.add(_target), "convert fail");

        // Also it's a good time to rebase!
        rebase();

        emit Harvested(BADGER_RENCRV, _wbtc, _fee);
    }

    /**
     * @dev Returns the amount of single plus token is worth for one underlying token, expressed in WAD.
     */
    function _conversionRate() internal view virtual override returns (uint256) {
        // Both Badger's share price and Curve's virtual price are in WAD
        return IBadgerSett(BADGER_RENCRV).getPricePerFullShare().mul(ICurveFi(REN_SWAP).get_virtual_price()).div(WAD);
    }
}