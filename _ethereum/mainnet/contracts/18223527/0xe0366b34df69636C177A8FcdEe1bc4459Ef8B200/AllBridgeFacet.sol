// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IBridge.sol";
import "./IAllBridge.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./LibData.sol";
import "./LibPlexusUtil.sol";
import "./console.sol";

contract AllBridgeFacet is IBridge, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 internal constant NAMESPACE = keccak256("com.plexus.facets.allbridge");

    struct AllStruct {
        mapping(uint64 => uint) allChainIdmatch;
    }

    IAllBridge private immutable allbridge;

    constructor(IAllBridge _allbridge) {
        allbridge = _allbridge;
    }

    // _originId 1, 56, 137, 42161
    // _allChainId 1, 2, 5, 6
    function setChainId(uint64[] memory _originId, uint[] memory _allChainId) external {
        require(msg.sender == LibDiamond.contractOwner());
        AllStruct storage s = getStorage();
        for (uint i; i < _originId.length; i++) {
            s.allChainIdmatch[_originId[i]] = _allChainId[i];
        }
    }

    // _originId 1, 56, 137, 42161
    function viewChainId(uint64 _originId) public view returns (uint) {
        AllStruct storage s = getStorage();
        return s.allChainIdmatch[_originId];
    }

    function bridgeToAllbridge(BridgeData memory _bridgeData, AllBridgeData memory _allBridgeData) external payable nonReentrant {
        LibPlexusUtil._isTokenDeposit(_bridgeData.srcToken, _bridgeData.amount);
        _allBridgeStart(_bridgeData, _allBridgeData);
    }

    function swapAndBridgeToAllbridge(
        SwapData calldata _swap,
        BridgeData memory _bridgeData,
        AllBridgeData memory _allBridgeData
    ) external payable nonReentrant {
        _bridgeData.amount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        _allBridgeStart(_bridgeData, _allBridgeData);
    }

    function _toBytes32(address _address) internal pure returns (bytes32) {
        bytes memory byteArray = new bytes(32);
        assembly {
            mstore(add(byteArray, 32), _address)
        }
        return bytes32(byteArray);
    }

    function _allBridgeStart(BridgeData memory _bridgeData, AllBridgeData memory _allBridgeData) internal {
        IERC20(_bridgeData.srcToken).safeApprove(address(allbridge), _bridgeData.amount);
        allbridge.swapAndBridge{value: msg.value}(
            _toBytes32(_bridgeData.srcToken),
            uint(_bridgeData.amount),
            _toBytes32(_bridgeData.recipient),
            viewChainId(_bridgeData.dstChainId),
            _toBytes32(_allBridgeData.receiveToken),
            _allBridgeData.nonce,
            MessengerProtocol.Allbridge,
            _allBridgeData.feeTokenAmount
        );
        IERC20(_bridgeData.srcToken).safeApprove(address(allbridge), 0);

        emit LibData.Bridge(msg.sender, _bridgeData.dstChainId, _bridgeData.srcToken, _bridgeData.amount, _bridgeData.plexusData);
    }

    /// @dev fetch local storage
    function getStorage() private pure returns (AllStruct storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}
