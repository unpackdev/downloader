// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./IPokeMe.sol";
import "./IEjectResolver.sol";
import "./IEjectLP.sol";
import "./SafeERC20.sol";
import "./INonfungiblePositionManager.sol";
import "./Initializable.sol";
import "./Proxied.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SEject.sol";
import "./CEjectLP.sol";
import "./FEjectLp.sol";

// BE CAREFUL: DOT NOT CHANGE THE ORDER OF INHERITED CONTRACT
// solhint-disable-next-line max-states-count
contract EjectLP is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IEjectLP
{
    using SafeERC20 for IERC20;

    // solhint-disable-next-line max-line-length
    ////////////////////////////////////////// CONSTANTS AND IMMUTABLES ///////////////////////////////////

    INonfungiblePositionManager public immutable override nftPositionManager;
    IPokeMe public immutable override pokeMe;
    address public immutable override factory;
    address internal immutable _gelato;

    // !!!!!!!!!!!!!!!!!!!!!!!! DO NOT CHANGE ORDER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    mapping(uint256 => bytes32) public override hashById;
    mapping(uint256 => bytes32) public taskById;

    uint256 public duration;
    uint256 public minimumFee;
    // HERE YOU CAN ADD PROPERTIES!!!

    // !!!!!!!!!!!!!!!!!!!!!!!! EVENTS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    event LogSetEject(
        uint256 indexed tokenId,
        OrderParams orderParams,
        uint256 startTime,
        address sender
    );
    event LogEject(
        uint256 indexed tokenId,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 feeAmount,
        address receiver
    );
    event LogSettle(
        uint256 indexed tokenId,
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 feeAmount,
        address receiver
    );
    event LogCancelEject(uint256 indexed tokenId);
    event LogSetDuration(uint256 duration);
    event LogSetMinimumFee(uint256 minimumFee);
    event LogRetrieveDust(address indexed token, uint256 amount);

    // !!!!!!!!!!!!!!!!!!!!!!!! MODIFIERS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    modifier onlyPokeMe() {
        require(
            msg.sender == address(pokeMe),
            "EjectLP::onlyPokeMe: only pokeMe"
        );
        _;
    }

    modifier isApproved(uint256 tokenId_) {
        require(
            nftPositionManager.getApproved(tokenId_) == address(this),
            "EjectLP::isApproved: EjectLP should be a operator"
        );
        _;
    }

    modifier onlyPositionOwner(uint256 tokenId_, address owner_) {
        require(
            nftPositionManager.ownerOf(tokenId_) == owner_,
            "EjectLP:schedule:: only owner"
        );
        _;
    }

    modifier isTaskOwner(address owner_) {
        require(owner_ == msg.sender, "EjectLP:schedule:: only task owner");
        _;
    }

    constructor(
        INonfungiblePositionManager nftPositionManager_,
        IPokeMe pokeMe_,
        address factory_,
        address gelato_
    ) {
        nftPositionManager = nftPositionManager_;
        factory = factory_;
        pokeMe = pokeMe_;
        _gelato = gelato_;
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        duration = 7776000; /// @custom:duration period when the range order will be actif.
        minimumFee = 1000000000; /// @custom:minimumFee minimum equal to 1 Gwei.
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! ADMIN FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    function pause() external onlyProxyAdmin {
        _pause();
    }

    function unpause() external onlyProxyAdmin {
        _unpause();
    }

    function setDuration(uint256 duration_) external onlyProxyAdmin {
        require(duration_ > duration, "EjectLP::setDuration: only increase.");
        duration = duration_;
        emit LogSetDuration(duration_);
    }

    function setMinimumFee(uint256 minimumFee_) external onlyProxyAdmin {
        minimumFee = minimumFee_;
        emit LogSetMinimumFee(minimumFee_);
    }

    function mulipleRetrieveDust(IERC20[] calldata tokens_, address recipient_)
        external
        onlyProxyAdmin
    {
        uint256 length = tokens_.length;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                IERC20 token = tokens_[i];
                uint256 balance = token.balanceOf(address(this));
                if (balance > 0) {
                    token.safeTransfer(recipient_, balance);
                    emit LogRetrieveDust(address(token), balance);
                }
            }
        }
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! EXTERNAL FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    // solhint-disable-next-line function-max-lines
    function schedule(OrderParams memory orderParams_)
        external
        payable
        override
        whenNotPaused
        nonReentrant
        isApproved(orderParams_.tokenId)
        onlyPositionOwner(orderParams_.tokenId, msg.sender)
    {
        require(
            orderParams_.maxFeeAmount > minimumFee,
            "EjectLP::schedule: maxFeeAmount < minimumFee"
        );
        require(
            orderParams_.maxFeeAmount == msg.value,
            "EjectLP::schedule: maxFeeAmount !== msg.value"
        );
        require(
            orderParams_.feeToken == ETH,
            "EjectLP::schedule: only native token"
        ); // For now only native token can be used.
        require(
            hashById[orderParams_.tokenId] == bytes32(0) &&
                taskById[orderParams_.tokenId] == bytes32(0),
            "EjectLP::schedule: task exist"
        );
        require(
            orderParams_.receiver != address(0),
            "EjectLP::schedule: invalid receiver"
        );

        Order memory order = Order({
            tickThreshold: orderParams_.tickThreshold,
            ejectAbove: orderParams_.ejectAbove,
            receiver: orderParams_.receiver,
            owner: msg.sender,
            maxFeeAmount: orderParams_.maxFeeAmount,
            startTime: block.timestamp, // solhint-disable-line not-rely-on-time
            ejectAtExpiry: orderParams_.ejectAtExpiry
        });

        hashById[orderParams_.tokenId] = keccak256(abi.encode(order));
        taskById[orderParams_.tokenId] = pokeMe.createTaskNoPrepayment(
            address(this),
            this.ejectOrSettle.selector,
            orderParams_.resolver,
            abi.encodeWithSelector(
                IEjectResolver.checker.selector,
                orderParams_.tokenId,
                order,
                orderParams_.feeToken
            ),
            orderParams_.feeToken
        );

        emit LogSetEject(
            orderParams_.tokenId,
            orderParams_,
            block.timestamp, // solhint-disable-line not-rely-on-time
            msg.sender
        );
    }

    function ejectOrSettle(
        uint256 tokenId_,
        Order memory order_,
        bool isEjection_
    ) external override whenNotPaused nonReentrant onlyPokeMe {
        require(
            hashById[tokenId_] == keccak256(abi.encode(order_)),
            "EjectLP::ejectOrSettle: incorrect task hash"
        );
        if (isEjection_) _eject(tokenId_, order_);
        else _settle(tokenId_, order_);
    }

    // solhint-disable-next-line function-max-lines
    function cancel(uint256 tokenId_, Order memory order_)
        external
        override
        whenNotPaused
        nonReentrant
        isTaskOwner(order_.owner)
    {
        require(
            hashById[tokenId_] == keccak256(abi.encode(order_)),
            "EjectLP::cancel: invalid hash"
        );

        pokeMe.cancelTask(taskById[tokenId_]);

        delete hashById[tokenId_];
        delete taskById[tokenId_];

        AddressUpgradeable.sendValue(
            payable(order_.receiver),
            order_.maxFeeAmount
        );

        emit LogCancelEject(tokenId_);
    }

    // solhint-disable-next-line function-max-lines
    function canEject(uint256 tokenId_, Order memory order_)
        public
        view
        returns (uint128)
    {
        uint128 liquidity;
        IUniswapV3Pool pool;
        {
            address token0;
            address token1;
            uint24 feeTier;
            (
                ,
                ,
                token0,
                token1,
                feeTier,
                ,
                ,
                liquidity,
                ,
                ,
                ,

            ) = nftPositionManager.positions(tokenId_);
            pool = _pool(factory, token0, token1, feeTier);
        }
        (bool isOk, string memory reason) = isEjectable(tokenId_, order_, pool);

        require(isOk, reason);

        return liquidity;
    }

    // solhint-disable-next-line code-complexity
    function isEjectable(
        uint256 tokenId_,
        Order memory order_,
        IUniswapV3Pool pool_
    ) public view override returns (bool, string memory) {
        // solhint-disable-next-line not-rely-on-time
        if (order_.startTime + duration <= block.timestamp)
            return (false, "EjectLP::isEjectable: range order expired");

        (, int24 tick, , , , , ) = pool_.slot0();
        int24 tickSpacing = pool_.tickSpacing();

        if (order_.ejectAbove && tick <= order_.tickThreshold + tickSpacing)
            return (false, "EjectLP::isEjectable: price not met");

        if (!order_.ejectAbove && tick >= order_.tickThreshold - tickSpacing)
            return (false, "EjectLP::isEjectable: price not met");

        (bool notApproved, ) = isNotApproved(tokenId_);
        if (notApproved) return (false, "EjectLP::isEjectable: not approved");

        return (true, OK);
    }

    function isExpired(Order memory order_)
        public
        view
        override
        returns (bool, string memory)
    {
        // solhint-disable-next-line not-rely-on-time
        if (order_.startTime + duration > block.timestamp)
            return (false, "EjectLP::isExpired: not expired");
        return (true, OK);
    }

    function isBurnt(uint256 tokenId_)
        public
        view
        override
        returns (bool, string memory)
    {
        try nftPositionManager.ownerOf(tokenId_) returns (address owner) {
            if (owner == address(0)) return (true, OK);
            return (false, "EjectLP::isBurnt: not burnt");
        } catch {
            return (true, OK);
        }
    }

    function isNotApproved(uint256 tokenId_)
        public
        view
        override
        returns (bool, string memory)
    {
        if (nftPositionManager.getApproved(tokenId_) != address(this)) {
            return (true, OK);
        }
        return (false, "EjectLP::isNotApproved: EjectLP is approved");
    }

    function ownerHasChanged(uint256 tokenId_, address owner_)
        public
        view
        override
        returns (bool, string memory)
    {
        if (nftPositionManager.ownerOf(tokenId_) != owner_) {
            return (true, OK);
        }
        return (false, "EjectLP::hasOwnerChanged: owner didn't changed");
    }

    // solhint-disable-next-line function-max-lines
    function _eject(uint256 tokenId_, Order memory order_)
        internal
        onlyPositionOwner(tokenId_, order_.owner)
        isApproved(tokenId_)
    {
        uint256 feeAmount = _getFeeDetails();

        require(
            feeAmount <= order_.maxFeeAmount,
            "EjectLP::eject: fee > maxFeeAmount"
        );

        uint128 liquidity = canEject(tokenId_, order_);

        (uint256 amount0, uint256 amount1) = _collectAndSend(
            tokenId_,
            order_,
            liquidity,
            feeAmount
        );

        emit LogEject(tokenId_, amount0, amount1, feeAmount, order_.receiver);
    }

    function _settle(uint256 tokenId_, Order memory order_) internal {
        uint256 feeAmount = _getFeeDetails();

        (bool burnt, ) = isBurnt(tokenId_);

        if (burnt) return _sendFund(tokenId_, order_, feeAmount);

        (bool hasChanged, ) = ownerHasChanged(tokenId_, order_.owner);
        if (hasChanged) return _sendFund(tokenId_, order_, feeAmount);

        (bool notApproved, ) = isNotApproved(tokenId_);
        if (notApproved) return _sendFund(tokenId_, order_, feeAmount);

        (bool expired, string memory reason) = isExpired(order_);
        require(expired, reason);

        if (!order_.ejectAtExpiry)
            return _sendFund(tokenId_, order_, feeAmount);

        (, , , , , , , uint128 liquidity, , , , ) = nftPositionManager
            .positions(tokenId_);

        (uint256 amount0, uint256 amount1) = _collectAndSend(
            tokenId_,
            order_,
            liquidity,
            feeAmount
        );

        emit LogSettle(tokenId_, amount0, amount1, feeAmount, order_.receiver);
    }

    function _collectAndSend(
        uint256 tokenId_,
        Order memory order_,
        uint128 liquidity_,
        uint256 feeAmount_
    ) internal returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _collect(
            nftPositionManager,
            tokenId_,
            liquidity_,
            order_.receiver
        );

        _send(tokenId_, order_, feeAmount_);
    }

    function _sendFund(
        uint256 tokenId_,
        Order memory order_,
        uint256 feeAmount_
    ) internal {
        _send(tokenId_, order_, feeAmount_);

        emit LogSettle(tokenId_, 0, 0, feeAmount_, order_.receiver);
    }

    function _send(
        uint256 tokenId_,
        Order memory order_,
        uint256 feeAmount_
    ) internal {
        pokeMe.cancelTask(taskById[tokenId_]); // Cancel to desactivate the task.

        delete hashById[tokenId_];
        delete taskById[tokenId_];

        // !!!!!!!!! Settlement can be done even if it's costlier than maxFeeAmount !!!!!!!!!!

        // gelato fee in native token
        AddressUpgradeable.sendValue(
            payable(_gelato),
            feeAmount_ < order_.maxFeeAmount ? feeAmount_ : order_.maxFeeAmount
        );
        if (feeAmount_ < order_.maxFeeAmount) {
            unchecked {
                AddressUpgradeable.sendValue(
                    order_.receiver,
                    order_.maxFeeAmount - feeAmount_
                );
            }
        }
    }

    function _getFeeDetails() internal view returns (uint256) {
        (uint256 feeAmount, address feeToken) = pokeMe.getFeeDetails();
        require(feeToken == ETH, "EjectLP: only native token");
        return feeAmount;
    }
}
