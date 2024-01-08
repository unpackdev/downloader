// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";

import "./IYangNFTVault.sol";
import "./ICHIManager.sol";
import "./ICHIVault.sol";
import "./YANGPosition.sol";
import "./PriceHelper.sol";
import "./LockLiquidity.sol";

contract YangNFTVault is
    IYangNFTVault,
    LockLiquidity,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC721Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // chiManager
    address private chiManager;

    // chainlink feed registry
    address public registry;

    // nft and Yang tokenId
    uint256 private _nextId;
    address private _tempAccount;
    mapping(address => uint256) private _usersMap;

    modifier isAuthorizedForToken(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved");
        _;
    }

    modifier subscripting(address account) {
        _tempAccount = account;
        _;
        _tempAccount = address(0);
    }

    // initialize
    function initialize(address _registry) public initializer {
        registry = _registry;

        _nextId = 1;
        __LockLiquidity__init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("YIN Asset Manager Vault", "YANG");
    }

    function setCHIManager(address _chiManager) external override onlyOwner {
        chiManager = _chiManager;
    }

    function updateLockSeconds(uint256 lockInSeconds) external onlyOwner {
        _updateLockSeconds(lockInSeconds);
    }

    function updateLockState(uint256 chiId, bool state) external onlyOwner {
        _updateLockState(chiId, state);
    }

    function mint(address recipient)
        external
        override
        returns (uint256 tokenId)
    {
        require(_usersMap[recipient] == 0, "only mint once");
        // _mint function check tokenId existence
        _mint(recipient, (tokenId = _nextId++));

        emit MintYangNFT(recipient, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from != address(0)) {
            require(_usersMap[from] == tokenId, "invalid tokenId");
            _usersMap[from] = 0;
        }
        if (to != address(0)) {
            require(_usersMap[to] == 0, "only accept one");
            _usersMap[to] = tokenId;
        }
    }

    function _withdraw(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1
    ) internal {
        if (amount0 > 0) {
            IERC20(token0).safeTransfer(msg.sender, amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).safeTransfer(msg.sender, amount1);
        }
    }

    function subscribeSingle(SubscribeSingleParam memory params)
        external
        override
        subscripting(msg.sender)
        isAuthorizedForToken(params.yangId)
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 shares
        )
    {
        require(!checkMaxUSDLimit(params.chiId), "MUL");

        (shares, amount0, amount1) = ICHIManager(chiManager).subscribeSingle(
            params.yangId,
            params.chiId,
            params.zeroForOne,
            params.exactAmount,
            params.maxTokenAmount,
            params.minShares
        );
        _updateAccountLockDurations(
            params.yangId,
            params.chiId,
            block.timestamp
        );
        emit Subscribe(params.yangId, params.chiId, shares);
    }

    function subscribe(SubscribeParam memory params)
        external
        override
        subscripting(msg.sender)
        isAuthorizedForToken(params.yangId)
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 shares
        )
    {
        require(chiManager != address(0), "CHI");
        require(!checkMaxUSDLimit(params.chiId), "MUL");
        (shares, amount0, amount1) = ICHIManager(chiManager).subscribe(
            params.yangId,
            params.chiId,
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min
        );
        _updateAccountLockDurations(
            params.yangId,
            params.chiId,
            block.timestamp
        );

        emit Subscribe(params.yangId, params.chiId, shares);
    }

    function unsubscribe(UnSubscribeParam memory params)
        external
        override
        nonReentrant
        isAuthorizedForToken(params.yangId)
        afterLockUnsubscribe(params.yangId, params.chiId)
    {
        require(chiManager != address(0), "CHI");

        (uint256 amount0, uint256 amount1) = ICHIManager(chiManager)
            .unsubscribe(
                params.yangId,
                params.chiId,
                params.shares,
                params.amount0Min,
                params.amount1Min
            );

        (, , address _pool, , , , , ) = ICHIManager(chiManager).chi(
            params.chiId
        );
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        _withdraw(pool.token0(), amount0, pool.token1(), amount1);

        emit UnSubscribe(params.yangId, params.chiId, amount0, amount1);
    }

    function unsubscribeSingle(UnSubscribeSingleParam memory params)
        external
        override
        nonReentrant
        isAuthorizedForToken(params.yangId)
        afterLockUnsubscribe(params.yangId, params.chiId)
    {
        require(chiManager != address(0), "CHI");
        (, , address _pool, , , , , ) = ICHIManager(chiManager).chi(
            params.chiId
        );
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        uint256 amount = ICHIManager(chiManager).unsubscribeSingle(
            params.yangId,
            params.chiId,
            params.zeroForOne,
            params.shares,
            params.amountOutMin
        );
        require(amount >= params.amountOutMin);
        address tokenOut = params.zeroForOne ? pool.token1() : pool.token0();
        _withdraw(tokenOut, amount, address(0), 0);

        emit UnSubscribe(params.yangId, params.chiId, amount, 0);
    }

    // views function

    function checkMaxUSDLimit(uint256 chiId)
        public
        view
        override
        returns (bool)
    {
        (, , address pool, address vault, , , , ) = ICHIManager(chiManager).chi(
            chiId
        );
        (, , uint256 maxUSDLimit) = ICHIManager(chiManager).config(chiId);
        (uint256 amount0, uint256 amount1) = ICHIVault(vault).getTotalAmounts();
        return
            PriceHelper.isReachMaxUSDLimit(
                registry,
                IUniswapV3Pool(pool).token0(),
                amount0,
                IUniswapV3Pool(pool).token1(),
                amount1,
                maxUSDLimit
            );
    }

    function positions(uint256 yangId, uint256 chiId)
        external
        view
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 shares
        )
    {
        shares = ICHIManager(chiManager).yang(yangId, chiId);
        (uint256 _amount0, uint256 _amount1) = getAmounts(chiId, shares);
        amount0 = _amount0;
        amount1 = _amount1;
    }

    function getTokenId(address recipient)
        public
        view
        override
        returns (uint256)
    {
        return _usersMap[recipient];
    }

    function getShares(
        uint256 chiId,
        uint256 amount0Desired,
        uint256 amount1Desired
    )
        external
        view
        override
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(chiManager != address(0), "CHI");
        (, , , address _vault, , , , uint256 _totalShares) = ICHIManager(
            chiManager
        ).chi(chiId);
        (uint256 total0, uint256 total1) = ICHIVault(_vault).getTotalAmounts();

        if (_totalShares == 0) {
            // For first deposit, just use the amounts desired
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            shares = Math.max(amount0, amount1);
        } else if (total0 == 0) {
            amount1 = amount1Desired;
            shares = amount1.mul(_totalShares).div(total1);
        } else if (total1 == 0) {
            amount0 = amount0Desired;
            shares = amount0.mul(_totalShares).div(total0);
        } else {
            uint256 cross = Math.min(
                amount0Desired.mul(total1),
                amount1Desired.mul(total0)
            );
            if (cross != 0) {
                // Round up amounts
                amount0 = cross.sub(1).div(total1).add(1);
                amount1 = cross.sub(1).div(total0).add(1);
                shares = cross.mul(_totalShares).div(total0).div(total1);
            }
        }
    }

    function getAmounts(uint256 chiId, uint256 shares)
        public
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        require(chiManager != address(0), "CHI");
        (, , , address _vault, , , , uint256 _totalShares) = ICHIManager(
            chiManager
        ).chi(chiId);
        if (_totalShares > 0) {
            (uint256 total0, uint256 total1) = ICHIVault(_vault)
                .getTotalAmounts();
            amount0 = total0.mul(shares).div(_totalShares);
            amount1 = total1.mul(shares).div(_totalShares);
        }
    }

    function YANGDepositCallback(
        IERC20 token0,
        uint256 amount0,
        IERC20 token1,
        uint256 amount1,
        address recipient
    ) external override {
        require(chiManager != address(0), "CHI");
        require(msg.sender == chiManager, "manager");
        if (amount0 > 0)
            token0.safeTransferFrom(_tempAccount, recipient, amount0);
        if (amount1 > 0)
            token1.safeTransferFrom(_tempAccount, recipient, amount1);
    }
}
