// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./ICallProxy.sol";
import "./ICallExecutor.sol";
import "./IGatewayClient.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./BalanceManagement.sol";
import "./Errors.sol";


contract AnyCallGateway is Pausable, ReentrancyGuard, BalanceManagement {

    error OnlyCallExecutorError();
    error OnlySelfError();
    error OnlyClientError();

    error PeerAddressMismatchError();
    error ZeroChainIdError();

    error PeerNotSetError();
    error ClientNotSetError();

    error CallFromAddressError();
    error FallbackContextFromError();
    error FallbackDataSelectorError();
    error FallbackCallToAddressError();

    ICallProxy public callProxy;
    ICallExecutor public callExecutor;

    IGatewayClient public client;

    mapping(uint256 => address) public peerMap;
    uint256[] public peerChainIdList;
    mapping(uint256 => OptionalValue) public peerChainIdIndexMap;

    uint256 private constant PAY_FEE_ON_SOURCE_CHAIN = 0x1 << 1;
    uint256 private constant SELECTOR_DATA_SIZE = 4;

    event SetCallProxy(address indexed callProxyAddress, address indexed callExecutorAddress);

    event SetClient(address indexed clientAddress);

    event SetPeer(uint256 indexed chainId, address indexed peerAddress);
    event RemovePeer(uint256 indexed chainId);

    event CallProxyDeposit(uint256 amount);
    event CallProxyWithdraw(uint256 amount);

    constructor(
        address _callProxyAddress,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
    {
        _setCallProxy(_callProxyAddress);

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyCallExecutor {
        if (msg.sender != address(callExecutor)) {
            revert OnlyCallExecutorError();
        }

        _;
    }

    modifier onlySelf {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
        }

        _;
    }

    modifier onlyClient {
        if (msg.sender != address(client)) {
            revert OnlyClientError();
        }

        _;
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setCallProxy(address _callProxyAddress) external onlyManager {
        _setCallProxy(_callProxyAddress);
    }

    function setClient(address _clientAddress) external onlyManager {
        if (_clientAddress == address(0)) {
            revert ZeroAddressError();
        }

        client = IGatewayClient(_clientAddress);

        emit SetClient(_clientAddress);
    }

    function setPeers(KeyToAddressValue[] calldata _peers) external onlyManager {
        for (uint256 index; index < _peers.length; index++) {
            KeyToAddressValue calldata item = _peers[index];

            uint256 chainId = item.key;
            address peerAddress = item.value;

            // Allow same configuration on multiple chains
            if (chainId == block.chainid) {
                if (peerAddress != address(this)) {
                    revert PeerAddressMismatchError();
                }
            } else {
                _setPeer(chainId, peerAddress);
            }
        }
    }

    function removePeers(uint256[] calldata _chainIds) external onlyManager {
        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];

            // Allow same configuration on multiple chains
            if (chainId != block.chainid) {
                _removePeer(chainId);
            }
        }
    }

    function callProxyDeposit() external payable onlyManager {
        uint256 amount = msg.value;

        callProxy.deposit{value: amount}(address(this));

        emit CallProxyDeposit(amount);
    }

    function callProxyWithdraw(uint256 _amount) external onlyManager {
        callProxy.withdraw(_amount);

        safeTransferNative(msg.sender, _amount);

        emit CallProxyWithdraw(_amount);
    }

    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bool _useFallback
    )
        external
        payable
        onlyClient
        whenNotPaused
    {
        address peerAddress = peerMap[_targetChainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        callProxy.anyCall{value: msg.value}(
            peerAddress,
            abi.encodePacked(this.anyExecute.selector, _message),
            _useFallback ?
                address(this) :
                address(0),
            _targetChainId,
            PAY_FEE_ON_SOURCE_CHAIN
        );
    }

    function peerCount() external view returns (uint256) {
        return peerChainIdList.length;
    }

    function callProxyExecutionBudget() external view returns (uint256 amount) {
        return callProxy.executionBudget(address(this));
    }

    function messageFee(
        uint256 _targetChainId,
        uint256 _messageSizeInBytes
    )
        public
        view
        returns (uint256)
    {
        return callProxy.calcSrcFees(
            address(this),
            _targetChainId,
            _messageSizeInBytes + SELECTOR_DATA_SIZE
        );
    }

    function _setPeer(uint256 _chainId, address _peerAddress) private {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        if (_peerAddress == address(0)) {
            revert ZeroAddressError();
        }

        combinedMapSet(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId, _peerAddress);

        emit SetPeer(_chainId, _peerAddress);
    }

    function _removePeer(uint256 _chainId) private {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        combinedMapRemove(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId);

        emit RemovePeer(_chainId);
    }

    function anyExecute(bytes calldata _data)
        external
        nonReentrant
        onlyCallExecutor
        whenNotPaused
        returns (bool success, bytes memory result)
    {
        bytes4 selector = bytes4(_data[:SELECTOR_DATA_SIZE]);

        if (selector == this.anyExecute.selector) {
            if (address(client) == address(0)) {
                revert ClientNotSetError();
            }

            (address from, uint256 fromChainID, ) = callExecutor.context();

            bool condition =
                fromChainID != 0 &&
                from != address(0) &&
                from == peerMap[fromChainID];

            if (!condition) {
                revert CallFromAddressError();
            }

            return client.handleExecutionPayload(fromChainID, _data[SELECTOR_DATA_SIZE:]);
        } else if (selector == this.anyFallback.selector) {
            (address fallbackTo, bytes memory fallbackData) = abi.decode(_data[SELECTOR_DATA_SIZE:], (address, bytes));

            this.anyFallback(fallbackTo, fallbackData);

            return (true, "");
        } else {
            return (false, "call-selector");
        }
    }

    function anyFallback(address _to, bytes calldata _data) external onlySelf {
        if (address(client) == address(0)) {
            revert ClientNotSetError();
        }

        (address from, uint256 fromChainID, ) = callExecutor.context();

        if (from != address(this)) {
            revert FallbackContextFromError();
        }

        if (bytes4(_data[:SELECTOR_DATA_SIZE]) != this.anyExecute.selector) {
            revert FallbackDataSelectorError();
        }

        bool condition =
            fromChainID != 0 &&
            _to != address(0) &&
            _to == peerMap[fromChainID];

        if (!condition) {
            revert FallbackCallToAddressError();
        }

        client.handleFallbackPayload(fromChainID, _data[SELECTOR_DATA_SIZE:]);
    }

    function _setCallProxy(address _callProxyAddress) private {
        if (_callProxyAddress == address(0)) {
            revert ZeroAddressError();
        }

        callProxy = ICallProxy(_callProxyAddress);
        callExecutor = callProxy.executor();

        emit SetCallProxy(_callProxyAddress, address(callExecutor));
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}