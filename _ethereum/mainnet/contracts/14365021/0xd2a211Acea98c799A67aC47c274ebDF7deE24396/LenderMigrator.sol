// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Strings.sol";

import "./ICore.sol";
import "./IStrategy.sol";
import "./Utils.sol";

import "./TransparentUpgradeableProxy.sol";

/// @title LenderMigrator
/// @author Angle Core Team
contract LenderMigrator is ERC20 {
    using SafeERC20 for IERC20;
    address public owner;

    event Migrated(address, address);

    ICore private _core = ICore(0x61ed74de9Ca5796cF2F8fD60D54160D47E30B7c3);
    address private constant _governor = 0xdC4e6DFe07EFCa50a197DF15D9200883eF4Eb1c8;
    address private constant _guardian = 0x0C2553e4B9dFA9f83b1A6D3EAB96c4bAaB42d430;
    address private constant _proxyAdmin = 0x1D941EF0D3Bba4ad67DBfBCeE5262F4CEE53A32b;
    IERC20 private constant _comp = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    IComptroller private constant _comptroller = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IUniswapPositionManager private constant _uni = IUniswapPositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address private immutable _logic;
    IUniswapPool public immutable pool;
    uint24 private constant _poolFee = 100;

    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");

    constructor(address logic_) ERC20("SV", "SV") {
        _logic = logic_;
        owner = msg.sender;
        _mint(address(this), 1000 ether);
        _approve(address(this), address(_uni), type(uint256).max);
        _comp.approve(address(_uni), type(uint256).max);

        require(msg.sender == owner, "wrong caller");

        // Create Uni V3 Pool
        address token0;
        address token1;
        (token0, token1) = address(this) < address(_comp)
            ? (address(this), address(_comp))
            : (address(_comp), address(this));

        pool = IUniswapPool(_uni.createAndInitializePoolIfNecessary(token0, token1, _poolFee, 2**96));
    }

    /// @notice Changes the minter address
    /// @param owner_ Address of the new owner
    function setOwner(address owner_) external {
        require(msg.sender == owner, "wrong caller");
        require(owner_ != address(0), "0 address");
        owner = owner_;
    }

    function migrate() external {
        require(msg.sender == owner, "wrong caller");

        address newLender;
        IGenericLender lender = IGenericLender(0xC011882d0f7672D8942e7fE2248C174eeD640c8f);
        address cToken = IGenericCompound(address(lender)).cToken();
        IStrategy strategy = IStrategy(IGenericCompound(address(lender)).strategy());

        IcToken(cToken).exchangeRateCurrent();

        // Deploy New GenericCompound First
        {
            address[] memory governorList = new address[](1);
            governorList[0] = address(_governor);

            address[] memory keeperList = new address[](2);
            keeperList[0] = 0xcC617C6f9725eACC993ac626C7efC6B96476916E;
            keeperList[1] = 0xfdA462548Ce04282f4B6D6619823a7C64Fdc0185;

            newLender = address(
                new TransparentUpgradeableProxy(
                    _logic,
                    _proxyAdmin,
                    abi.encodeWithSignature(
                        "initialize(address,string,address,address[],address[],address)",
                        address(strategy),
                        "Compound Lender",
                        cToken,
                        governorList,
                        keeperList,
                        _guardian
                    )
                )
            );

            strategy.addLender(address(newLender));
        }

        uint256 tokenId;
        uint128 liquidity;
        // Withdraw all COMP from old contract
        address token0;
        address token1;
        (token0, token1) = address(this) < address(_comp)
            ? (address(this), address(_comp))
            : (address(_comp), address(this));

        (, int24 tick, , , , , ) = pool.slot0();
        int24 tickLower = token0 == address(_comp) ? int24(-887160) : int24(tick + 1);
        int24 tickUpper = token0 == address(_comp) ? int24(tick - 1) : int24(887160);

        (tokenId, liquidity, , ) = _uni.mint(
            MintParams({
                token0: token0,
                token1: token1,
                fee: _poolFee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: 1 ether,
                amount1Desired: 1 ether,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        {
            address[] memory holders = new address[](1);
            address[] memory cTokens = new address[](1);
            holders[0] = address(lender);
            cTokens[0] = IGenericCompound(address(lender)).cToken();
            _comptroller.claimComp(holders, cTokens, true, true);
        }

        IGenericCompound(address(lender)).setPath(abi.encodePacked(address(_comp), uint24(_poolFee), address(this)));

        // Will eventually swap the comps
        // Withdraw all funds
        strategy.safeRemoveLender(address(lender));

        _burn(address(lender), balanceOf(address(lender)));
        _comp.transfer(newLender, _comp.balanceOf(address(this))); // Send directly to multisg

        // Withdraw all COMP from old contract
        strategy.harvest();

        // Now DAI
        lender = IGenericLender(0xf89fa5D0f1A85c2bAda78dBCc1d6CDC09a7c8e12);
        cToken = IGenericCompound(address(lender)).cToken();
        strategy = IStrategy(IGenericCompound(address(lender)).strategy());

        IcToken(cToken).exchangeRateCurrent();

        // Deploy New GenericCompound First
        {
            address[] memory governorList = new address[](1);
            governorList[0] = address(_governor);

            address[] memory keeperList = new address[](2);
            keeperList[0] = 0xcC617C6f9725eACC993ac626C7efC6B96476916E;
            keeperList[1] = 0xfdA462548Ce04282f4B6D6619823a7C64Fdc0185;

            address newLenderDAI = address(
                new TransparentUpgradeableProxy(
                    _logic,
                    _proxyAdmin,
                    abi.encodeWithSignature(
                        "initialize(address,string,address,address[],address[],address)",
                        address(strategy),
                        "Compound Lender",
                        cToken,
                        governorList,
                        keeperList,
                        _guardian
                    )
                )
            );
            emit Migrated(newLender, newLenderDAI);
            newLender = newLenderDAI;

            strategy.addLender(address(newLender));
        }

        {
            address[] memory holders = new address[](1);
            address[] memory cTokens = new address[](1);
            holders[0] = address(lender);
            cTokens[0] = IGenericCompound(address(lender)).cToken();
            _comptroller.claimComp(holders, cTokens, true, true);
        }

        IGenericCompound(address(lender)).setPath(abi.encodePacked(address(_comp), uint24(_poolFee), address(this)));

        // Will eventually swap the comps
        // Withdraw all funds
        strategy.safeRemoveLender(address(lender));

        (, , , , , , , liquidity, , , , ) = _uni.positions(tokenId);
        _uni.decreaseLiquidity(
            DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        _uni.collect(CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max));
        _uni.burn(tokenId);

        _burn(address(lender), balanceOf(address(lender)));
        _comp.transfer(newLender, _comp.balanceOf(address(this))); // Send directly to multisg

        // Withdraw all COMP from old contract
        strategy.harvest();

        _core.removeGovernor(address(this));
    }

    // ERC721 Management
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
