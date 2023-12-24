// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IMauvePool.sol";
import "./FixedPoint128.sol";
import "./FullMath.sol";

import "./IMauveFactoryReduced.sol";
import "./INonfungiblePositionManager.sol";
import "./INonfungibleTokenPositionDescriptor.sol";
import "./PositionKey.sol";
import "./PoolAddress.sol";
import "./LiquidityManagement.sol";
import "./EATMulticall.sol";
import "./ERC721Permit.sol";
import "./PeripheryValidation.sol";

/// @title NFT positions
/// @notice Wraps Mauve positions in the ERC721 non-fungible token interface
contract NonfungiblePositionManager is
    INonfungiblePositionManager,
    EATMulticall,
    ERC721Permit,
    LiquidityManagement,
    PeripheryValidation
{
    // details about the mauve position
    struct Position {
        // how many uncollected tokens are owed to the position, as of the last computation
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the ID of the pool with which this token is connected
        uint80 poolId;
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        // the liquidity of the position
        uint128 liquidity;
        // the fee growth of the aggregate position as of the last action on the individual position
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
    }

    /// @dev The ID of the next pool that is used for the first time. Skips 0
    uint80 private _nextPoolId = 1;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint176 private _nextId = 1;

    /// @dev The address of the token descriptor contract, which handles generating token URIs for position tokens
    address private immutable _tokenDescriptor;

    /// @dev Pool keys by pool ID, to save on SSTOREs for position data
    mapping(uint80 => PoolAddress.PoolKey) private _poolIdToPoolKey;

    /// @dev The token ID position data
    mapping(uint256 => Position) private _positions;

    /// @dev IDs of pools assigned by this contract
    mapping(address => uint80) private _poolIds;

    constructor(
        address _factory,
        address _WETH9,
        address _tokenDescriptor_,
        address _eatVerifier,
        address _violetID
    )
        ERC721Permit('Mauve Positions NFT-V1', 'MAUVE-POS', '1')
        PeripheryImmutableState(_factory, _WETH9)
        MauveCompliance(_violetID)
        EATMulticall(_eatVerifier)
    {
        _tokenDescriptor = _tokenDescriptor_;
    }

    // This modifier unlocks the _functionLock mutex, which is triggered
    // when `checkAuthorization` is called and emergency mode is not activated.
    // The same mutex is shared with functions with the `onlySelfMulticall` modifier.
    modifier unlockFunction() {
        _;
        _removeFunctionLock();
    }

    function _removeFunctionLock() internal {
        if (!_isEmergencyModeActivated()) {
            _callState = CallState.IS_MULTICALLING;
        }
    }

    /// Defines rules to let a transaction go through based on the state of `emergencyMode`.
    /// Functions using this modifier can only be called via EATMulticall, unless
    /// emergency mode is activated.
    // 1. If emergency mode is activated, it checks that `addressToCheck` is compliant.
    // 2. If emergency mode is not activated, it checks that the we are within an EATMulticall and
    // not already calling from a function with the same `_functionLock` mutex.
    /// @param addressToCheck The address to verify the compliant status of
    function checkAuthorization(address addressToCheck) private {
        if (_isEmergencyModeActivated()) {
            require(_checkIfAllowedToInteract(addressToCheck), 'NID');
        } else {
            // Prevents non-multicall calls
            if (_callState == CallState.IDLE) revert('NSMC');

            // Prevents cross-function re-entrancy
            // CFL -> Cross Function Lock
            if (_callState != CallState.IS_MULTICALLING) revert('CFL');
            _callState = CallState.IS_CALLING_PROTECTED_FUNCTION;
        }
    }

    /// @inheritdoc INonfungiblePositionManager
    function positions(uint256 tokenId)
        external
        view
        override
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        Position memory position = _positions[tokenId];
        // ITI -> Invalid token ID
        require(position.poolId != 0, 'ITI');
        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];
        return (
            position.nonce,
            position.operator,
            poolKey.token0,
            poolKey.token1,
            poolKey.fee,
            position.tickLower,
            position.tickUpper,
            position.liquidity,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.tokensOwed0,
            position.tokensOwed1
        );
    }

    /// @dev Caches a pool key
    function cachePoolKey(address pool, PoolAddress.PoolKey memory poolKey) private returns (uint80 poolId) {
        poolId = _poolIds[pool];
        if (poolId == 0) {
            _poolIds[pool] = (poolId = _nextPoolId++);
            _poolIdToPoolKey[poolId] = poolKey;
        }
    }

    /// @inheritdoc INonfungiblePositionManager
    function mint(MintParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        unlockFunction
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // Address does not matter here since addLiquidity will revert if emergency mode is activated
        checkAuthorization(address(0));
        IMauvePool pool;
        (liquidity, amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                recipient: address(this),
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min
            })
        );

        _mint(params.recipient, (tokenId = _nextId++));

        bytes32 positionKey = PositionKey.compute(address(this), params.tickLower, params.tickUpper);
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

        // idempotent set
        uint80 poolId =
            cachePoolKey(
                address(pool),
                PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee})
            );

        _positions[tokenId] = Position({
            nonce: 0,
            operator: address(0),
            poolId: poolId,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: feeGrowthInside1LastX128,
            tokensOwed0: 0,
            tokensOwed1: 0
        });

        emit IncreaseLiquidity(tokenId, liquidity, amount0, amount1);
    }

    function _checkAuthorizedForToken(uint256 tokenId) internal view virtual {
        // NA -> Not approved or owner
        require(_isApprovedOrOwner(msg.sender, tokenId), 'NA');
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory) {
        require(_exists(tokenId));
        return INonfungibleTokenPositionDescriptor(_tokenDescriptor).tokenURI(this, tokenId);
    }

    // save bytecode by removing implementation of unused method
    function baseURI() public pure override returns (string memory) {}

    /// @inheritdoc INonfungiblePositionManager
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        unlockFunction
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // Address does not matter here since addLiquidity will revert if emergency mode is activated
        checkAuthorization(address(0));
        Position storage position = _positions[params.tokenId];

        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];

        IMauvePool pool;
        (liquidity, amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: poolKey.token0,
                token1: poolKey.token1,
                fee: poolKey.fee,
                tickLower: position.tickLower,
                tickUpper: position.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                recipient: address(this)
            })
        );

        bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);

        // this is now updated to the current transaction
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

        position.tokensOwed0 += uint128(
            FullMath.mulDiv(
                feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );
        position.tokensOwed1 += uint128(
            FullMath.mulDiv(
                feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );

        position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
        position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        position.liquidity += liquidity;

        emit IncreaseLiquidity(params.tokenId, liquidity, amount0, amount1);
    }

    /// @inheritdoc INonfungiblePositionManager
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        unlockFunction
        returns (uint256 amount0, uint256 amount1)
    {
        _checkAuthorizedForToken(params.tokenId);
        checkAuthorization(ownerOf(params.tokenId));
        require(params.liquidity > 0);
        Position storage position = _positions[params.tokenId];

        uint128 positionLiquidity = position.liquidity;
        // NEL -> not enough liquidity
        require(positionLiquidity >= params.liquidity, 'NEL');

        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];
        IMauvePool pool = IMauvePool(PoolAddress.computeAddress(factory, poolKey));
        (amount0, amount1) = pool.burn(position.tickLower, position.tickUpper, params.liquidity);

        //PSC -> Price slippage check
        require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'PSC');

        bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);
        // this is now updated to the current transaction
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

        position.tokensOwed0 +=
            uint128(amount0) +
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
                    positionLiquidity,
                    FixedPoint128.Q128
                )
            );
        position.tokensOwed1 +=
            uint128(amount1) +
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
                    positionLiquidity,
                    FixedPoint128.Q128
                )
            );

        position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
        position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        // subtraction is safe because we checked positionLiquidity is gte params.liquidity
        position.liquidity = positionLiquidity - params.liquidity;

        emit DecreaseLiquidity(params.tokenId, params.liquidity, amount0, amount1);
    }

    /// @inheritdoc INonfungiblePositionManager
    function collectAmounts(CollectParams calldata params) external override {
        (uint256 amount0, uint256 amount1) = _collect(params);
        bytes memory encodedReturn = abi.encodeWithSignature('CollectAmounts(uint256,uint256)', amount0, amount1);
        // Adds the correct offset to the pointer, with length 0x44 that contains the revert reason
        // Revert reason contains the amounts returned by collect, useful to frontend interface for UX reasons
        assembly {
            revert(add(32, encodedReturn), 0x44)
        }
    }

    /// @inheritdoc INonfungiblePositionManager
    function collect(CollectParams calldata params)
        external
        payable
        override
        unlockFunction
        returns (uint256 amount0, uint256 amount1)
    {
        _checkAuthorizedForToken(params.tokenId);
        checkAuthorization(ownerOf(params.tokenId));
        return _collect(params);
    }

    function _collect(CollectParams calldata params) internal returns (uint256 amount0, uint256 amount1) {
        require(params.amount0Max > 0 || params.amount1Max > 0);
        // allow collecting to the nft position manager address with address 0
        address recipient = params.recipient == address(0) ? address(this) : params.recipient;

        Position storage position = _positions[params.tokenId];

        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];

        IMauvePool pool = IMauvePool(PoolAddress.computeAddress(factory, poolKey));

        (uint128 tokensOwed0, uint128 tokensOwed1) = (position.tokensOwed0, position.tokensOwed1);

        // trigger an update of the position fees owed and fee growth snapshots if it has any liquidity
        if (position.liquidity > 0) {
            pool.burn(position.tickLower, position.tickUpper, 0);
            (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) =
                pool.positions(PositionKey.compute(address(this), position.tickLower, position.tickUpper));

            tokensOwed0 += uint128(
                FullMath.mulDiv(
                    feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
                    position.liquidity,
                    FixedPoint128.Q128
                )
            );
            tokensOwed1 += uint128(
                FullMath.mulDiv(
                    feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
                    position.liquidity,
                    FixedPoint128.Q128
                )
            );

            position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
            position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        }

        // compute the arguments to give to the pool#collect method
        (uint128 amount0Collect, uint128 amount1Collect) =
            (
                params.amount0Max > tokensOwed0 ? tokensOwed0 : params.amount0Max,
                params.amount1Max > tokensOwed1 ? tokensOwed1 : params.amount1Max
            );

        // the actual amounts collected are returned
        (amount0, amount1) = pool.collect(
            recipient,
            position.tickLower,
            position.tickUpper,
            amount0Collect,
            amount1Collect
        );

        // sometimes there will be a few less wei than expected due to rounding down in core, but we just subtract the full amount expected
        // instead of the actual amount so we can burn the token
        (position.tokensOwed0, position.tokensOwed1) = (tokensOwed0 - amount0Collect, tokensOwed1 - amount1Collect);

        emit Collect(params.tokenId, recipient, amount0Collect, amount1Collect);
    }

    /// @inheritdoc INonfungiblePositionManager
    function burn(uint256 tokenId) external payable override unlockFunction {
        _checkAuthorizedForToken(tokenId);
        checkAuthorization(ownerOf(tokenId));
        Position storage position = _positions[tokenId];
        // NC -> Not cleared
        require(position.liquidity == 0 && position.tokensOwed0 == 0 && position.tokensOwed1 == 0, 'NC');
        delete _positions[tokenId];
        _burn(tokenId);
    }

    function _getAndIncrementNonce(uint256 tokenId) internal override returns (uint256) {
        return uint256(_positions[tokenId].nonce++);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        // NET ERC721: approved query for nonexistent token
        require(_exists(tokenId), 'NET');

        return _positions[tokenId].operator;
    }

    /// @dev Overrides _approve to use the operator in the position, which is packed with the position permit nonce
    function _approve(address to, uint256 tokenId) internal override(ERC721) {
        _positions[tokenId].operator = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /// @dev Overrides transferFrom to restrict from and to VioletID holders only
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) onlyAllowedToInteract(from, to) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev Overrides transferFrom with a version that requires an EAT
    function transferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId
    ) public virtual requiresAuth(v, r, s, expiry) onlyWhenNotEmergencyMode {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev Overrides safeTransferFrom to restrict from and to VioletID holders only
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) onlyAllowedToInteract(from, to) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev Overrides safeTransferFrom with a version that requires an EAT
    function safeTransferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId
    ) public virtual requiresAuth(v, r, s, expiry) onlyWhenNotEmergencyMode {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc INonfungiblePositionManager
    function updateVerifier(address newVerifier) external override onlyFactoryOwner {
        super.setVerifier(newVerifier);
    }
}
