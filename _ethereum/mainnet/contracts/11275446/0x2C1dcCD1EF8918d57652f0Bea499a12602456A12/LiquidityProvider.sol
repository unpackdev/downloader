pragma solidity ^0.6.0;

import "./IUniswapV2Router02.sol";
import "./SafeERC20.sol";
import "./ERC1155.sol";
import "./Counters.sol";

import "./ISyntheticRebaseToken.sol";
import "./IUniswapV2Oracle.sol";
import "./UniswapV2Library.sol";

import "./console.sol";

// interface IERC20Mintable is IERC20 {
//     function mint(address to, uint value) external returns (bool);
// }

contract LiquidityProvider is ERC1155 {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    uint256 public constant PERP_CONTRACTS = 0;

    uint256 immutable genesisBlock;
    IERC20 immutable upDownToken;

    IUniswapV2Router02 immutable router;
    IUniswapV2Oracle immutable oracle;

    struct LockedLPToken {
        address uniswapPool;
        uint256 amount;
        uint256 depositedAt;
    }
    Counters.Counter private _tokenIds;
    mapping(uint256 => LockedLPToken) public tokens;

    constructor(
        address router_,
        address updownToken_,
        address oracle_
    ) public ERC1155("") {
        genesisBlock = block.number;
        router = IUniswapV2Router02(router_);
        upDownToken = IERC20(updownToken_);
        oracle = IUniswapV2Oracle(oracle_);
        // use everything *after* 0 for the LockedLPTokens
        // but keep 0 as an erc20-like perpetual contract token
        _tokenIds.increment();
    }

    function addLiquidity(
        uint256 amount,
        address token_,
        address rebasingToken_,
        uint256 deadline
    ) public returns (uint256 tokenId) {
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount);

        // we will take and burn the UpDown token
        upDownToken.safeTransferFrom(msg.sender, address(this), 10**18);

        uint256 rebaseTokenAmount = oracle.current(
            token_,
            amount,
            rebasingToken_
        );

        IERC20(rebasingToken_).approve(address(router), rebaseTokenAmount);
        IERC20(token_).approve(address(router), amount);

        // let's say this already has access to the pool's remaining tokens
        // provide liquidity to the router
        (uint256 _poolAdded, uint256 tokenAdded, uint256 liquidity) = router
            .addLiquidity(
            rebasingToken_,
            token_,
            rebaseTokenAmount,
            amount,
            rebaseTokenAmount,
            amount,
            address(this),
            deadline
        );
        // give the user back their cash that didn't get used.
        if (amount < tokenAdded) {
            IERC20(token_).safeTransfer(address(this), amount - tokenAdded);
        }

        address pair = UniswapV2Library.pairFor(
            router.factory(),
            token_,
            rebasingToken_
        );
        // console.log("pair: ", pair);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId, 1, "");
        LockedLPToken storage lpToken = tokens[newItemId];
        lpToken.uniswapPool = pair;
        lpToken.amount = liquidity;
        lpToken.depositedAt = block.number;
        return newItemId;
    }

    function canRemove(uint256 depositedAt)
        internal
        view
        returns (bool)
    {
        uint lockupPeriod = (depositedAt - genesisBlock) * 2;
        console.log("lockup period: ", lockupPeriod, "genesis: ", genesisBlock);

        if (block.number > (genesisBlock + lockupPeriod)) {
            return true;
        }
        return false;
    }

    function removeLiquidity(uint256 tokenId) public {
        LockedLPToken memory lpToken = tokens[tokenId];
        require(canRemove(lpToken.depositedAt), "LP:Locked");
        _burn(msg.sender, tokenId, 1);

        IERC20(lpToken.uniswapPool).safeTransfer(msg.sender, lpToken.amount);
        delete tokens[tokenId];
    }

    // function getPerps(address rebasingToken_, address perpToken_, uint256 amount) public {
    //     // burn rebasingToken_
    //     // mint perpToken_
    // }

    function convertPerps(address perpToken_, uint256 amount) public {
        // burn perp
    }
}
