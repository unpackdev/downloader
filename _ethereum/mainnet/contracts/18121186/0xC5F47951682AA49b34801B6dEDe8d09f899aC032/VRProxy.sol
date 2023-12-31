// SPDX-License-Identifier: MIT

import "./ERC1967Proxy.sol";

struct MessageWithAttestation {
    bytes message;
    bytes attestation;
}

struct SellArgs {
    address sellToken;
    uint256 sellAmount;
    uint256 guaranteedBuyAmount;
    uint256 sellcallgas;
    bytes sellcalldata;
}

struct BuyArgs {
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
}

interface IValueRouterAdmin {
    function admin() external view returns (address);

    function pendingAdmin() external view returns (address);

    function changeAdmin(address _admin) external;

    function applyAdmin() external;

    function initialize(
        address _usdc,
        address _messageTransmtter,
        address _tokenMessenger,
        address _zeroEx,
        address admin
    ) external;

    function setFee(uint32 domain, uint256 price) external;

    function takeFee(address to, uint256 amount) external;
}

interface IValueRouter {
    event TakeFee(address to, uint256 amount);

    event SwapAndBridge(
        address sellToken,
        address buyToken,
        uint256 bridgeUSDCAmount,
        uint32 destDomain,
        address recipient,
        uint64 bridgeNonce,
        uint64 swapMessageNonce,
        bytes32 bridgeHash
    );

    event ReplaceSwapMessage(
        address buyToken,
        uint32 destDomain,
        address recipient,
        uint64 swapMessageNonce
    );

    event LocalSwap(
        address msgsender,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 boughtAmount
    );

    event BridgeArrive(bytes32 bridgeNonceHash, uint256 amount);

    event DestSwapFailed(bytes32 bridgeNonceHash);

    event DestSwapSuccess(bytes32 bridgeNonceHash);

    function version() external view returns (uint16);

    function fee(uint32 domain) external view returns (uint256);

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) external payable;

    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) external payable returns (uint64, uint64);

    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) external;
}

contract ValueRouter is ERC1967Proxy {
    constructor(address implementation) ERC1967Proxy(implementation, "") {}

    function _version() external view returns (uint16) {
        return IValueRouter(address(this)).version();
    }

    function _fee(uint32 domain) external view returns (uint256) {
        return IValueRouter(address(this)).fee(domain);
    }

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) external payable {
        super._fallback();
    }

    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) external payable returns (uint64, uint64) {
        super._fallback();
    }

    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) external {
        super._fallback();
    }

    function _admin() external view returns (address) {
        return IValueRouterAdmin(address(this)).admin();
    }

    function _pendingAdmin() external view returns (address) {
        return IValueRouterAdmin(address(this)).pendingAdmin();
    }

    function changeAdmin(address _admin) external {
        super._fallback();
    }

    function applyAdmin() external {
        super._fallback();
    }

    function initialize(
        address _usdc,
        address _messageTransmtter,
        address _tokenMessenger,
        address _zeroEx,
        address admin
    ) external {
        super._fallback();
    }

    function setFee(uint32 domain, uint256 price) external {
        super._fallback();
    }

    function takeFee(address to, uint256 amount) external {
        super._fallback();
    }
}