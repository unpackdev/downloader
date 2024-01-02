// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "./UUPSUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IRouterClient.sol";
import "./Client.sol";
import "./CCIPReceiver.sol";
import "./UsdPlus.sol";
import "./StakedUsdPlus.sol";

/// @notice USD+ mint/burn bridge using CCIP
/// Send and receive USD+ from other chains using CCIP
/// Mint/burn happens on a separate CCIP token pool contract
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/bridge/CCIPWaypoint.sol)
contract CCIPWaypoint is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable, PausableUpgradeable, CCIPReceiver {
    // TODO: Generalize to include payment tokens: USDC, etc.
    // TODO: Migrate ccip dependency to official release. Needs fix to forge install (https://github.com/foundry-rs/foundry/issues/5996)
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeERC20 for UsdPlus;

    /// ------------------ Types ------------------

    struct BridgeParams {
        address to;
        bool stake;
    }

    error InvalidTransfer();
    error InvalidSender(uint64 sourceChainSelector, address sender);
    error InvalidReceiver(uint64 destinationChainSelector);
    error InsufficientFunds(uint256 value, uint256 fee);
    error AmountZero();
    error AddressZero();
    error StakingDisabled();

    event ApprovedSenderSet(uint64 indexed sourceChainSelector, address indexed sourceChainWaypoint);
    event ApprovedReceiverSet(uint64 indexed destinationChainSelector, address indexed destinationChainWaypoint);
    event Sent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed destinationChainWaypoint,
        address to,
        uint256 amount,
        bool stake,
        uint256 fee
    );
    event Received(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address indexed sourceChainWaypoint,
        address to,
        uint256 amount,
        bool stake
    );

    /// ------------------ Storage ------------------

    struct CCIPWaypointStorage {
        // sourceChainSelector => sourceChainWaypoint
        mapping(uint64 => address) _approvedSender;
        // destinationChainSelector => destinationChainWaypoint
        mapping(uint64 => address) _approvedReceiver;
        UsdPlus _usdplus;
        StakedUsdPlus _stakedUsdPlus;
        mapping(uint64 => bool) _stakingEnabled;
    }

    // keccak256(abi.encode(uint256(keccak256("dinaricrypto.storage.CCIPWaypoint")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CCIPWAYPOINT_STORAGE_LOCATION =
        0x78c64de9b9dc0dfc8eacf934bc1fbd9289d8bc5c08666d7fa486b9fc8241ca00;

    function _getCCIPWaypointStorage() private pure returns (CCIPWaypointStorage storage $) {
        assembly {
            $.slot := CCIPWAYPOINT_STORAGE_LOCATION
        }
    }

    /// ------------------ Initialization ------------------

    function initialize(UsdPlus usdPlus, StakedUsdPlus stakedUsdPlus, address router, address initialOwner)
        public
        initializer
    {
        __CCIPReceiver_init(router);
        __Ownable_init(initialOwner);
        __Pausable_init();

        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        $._usdplus = usdPlus;
        $._stakedUsdPlus = stakedUsdPlus;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// ------------------ Getters ------------------

    function getApprovedSender(uint64 sourceChainSelector) external view returns (address) {
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        return $._approvedSender[sourceChainSelector];
    }

    function getApprovedReceiver(uint64 destinationChainSelector) external view returns (address) {
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        return $._approvedReceiver[destinationChainSelector];
    }

    function isStakingEnabled(uint64 destinationChainSelector) external view returns (bool) {
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        return $._stakingEnabled[destinationChainSelector];
    }

    function getFee(
        uint64 destinationChainSelector,
        address destinationChainWaypoint,
        address to,
        uint256 amount,
        bool stake
    ) public view returns (uint256) {
        return IRouterClient(getRouter()).getFee(
            destinationChainSelector, _createCCIPMessage(destinationChainWaypoint, to, amount, stake)
        );
    }

    /// ------------------ Admin ------------------

    function setRouter(address router) external onlyOwner {
        _setRouter(router);
    }

    function setApprovedSender(uint64 sourceChainSelector, address sourceChainWaypoint) external onlyOwner {
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        $._approvedSender[sourceChainSelector] = sourceChainWaypoint;
        emit ApprovedSenderSet(sourceChainSelector, sourceChainWaypoint);
    }

    function setApprovedReceiver(uint64 destinationChainSelector, address destinationChainWaypoint)
        external
        onlyOwner
    {
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        $._approvedReceiver[destinationChainSelector] = destinationChainWaypoint;
        emit ApprovedReceiverSet(destinationChainSelector, destinationChainWaypoint);
    }

    function setStakingEnabled(uint64 destinationChainSelector, bool enabled) external onlyOwner {
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        $._stakingEnabled[destinationChainSelector] = enabled;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// ------------------ CCIP ------------------

    function _ccipReceive(Client.Any2EVMMessage calldata message) internal override {
        if (message.destTokenAmounts.length != 1) revert InvalidTransfer();
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        UsdPlus usdPlus = $._usdplus;
        if (message.destTokenAmounts[0].token != address(usdPlus)) revert InvalidTransfer();
        address sender = abi.decode(message.sender, (address));
        if (sender != $._approvedSender[message.sourceChainSelector]) {
            revert InvalidSender(message.sourceChainSelector, sender);
        }

        BridgeParams memory params = abi.decode(message.data, (BridgeParams));
        uint256 amount = message.destTokenAmounts[0].amount;
        emit Received(message.messageId, message.sourceChainSelector, sender, params.to, amount, params.stake);
        if (params.stake) {
            StakedUsdPlus stakedUsdPlus = $._stakedUsdPlus;
            usdPlus.safeIncreaseAllowance(address(stakedUsdPlus), amount);
            // slither-disable-next-line unused-return
            stakedUsdPlus.deposit(amount, params.to);
        } else {
            usdPlus.safeTransfer(params.to, amount);
        }
    }

    function _createCCIPMessage(address destinationChainWaypoint, address to, uint256 amount, bool stake)
        internal
        view
        returns (Client.EVM2AnyMessage memory)
    {
        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address($._usdplus), amount: amount});

        return Client.EVM2AnyMessage({
            receiver: abi.encode(destinationChainWaypoint),
            data: abi.encode(BridgeParams({to: to, stake: stake})),
            tokenAmounts: tokenAmounts,
            feeToken: address(0), // ETH will be used for fees
            extraArgs: bytes("")
        });
    }

    function sendUsdPlus(uint64 destinationChainSelector, address to, uint256 amount, bool stake)
        external
        payable
        whenNotPaused
        returns (bytes32 messageId)
    {
        if (amount == 0) revert AmountZero();

        CCIPWaypointStorage storage $ = _getCCIPWaypointStorage();
        address destinationChainWaypoint = $._approvedReceiver[destinationChainSelector];
        if (destinationChainWaypoint == address(0)) revert InvalidReceiver(destinationChainSelector);
        if (stake && !$._stakingEnabled[destinationChainSelector]) revert StakingDisabled();

        // compile ccip message
        Client.EVM2AnyMessage memory message = _createCCIPMessage(destinationChainWaypoint, to, amount, stake);

        // calculate and check fee
        address router = getRouter();
        uint256 fee = IRouterClient(router).getFee(destinationChainSelector, message);
        if (fee > msg.value) revert InsufficientFunds(msg.value, fee);

        // pull usdplus
        IERC20(message.tokenAmounts[0].token).safeTransferFrom(msg.sender, address(this), amount);

        // approve router to spend token
        IERC20(message.tokenAmounts[0].token).safeIncreaseAllowance(router, amount);

        // send ccip message
        messageId = IRouterClient(getRouter()).ccipSend{value: msg.value}(destinationChainSelector, message);

        // slither-disable-next-line reentrancy-events
        emit Sent(messageId, destinationChainSelector, destinationChainWaypoint, to, amount, stake, fee);
    }

    /// ------------------ Rescue ------------------

    function rescue(address to, address token, uint256 amount) external onlyOwner {
        if (to == address(0)) revert AddressZero();

        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}
