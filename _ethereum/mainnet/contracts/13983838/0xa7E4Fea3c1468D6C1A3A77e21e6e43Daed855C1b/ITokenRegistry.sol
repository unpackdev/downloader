// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import "./IBridgeToken.sol";
import "./BridgeMessage.sol";

// ============ External Imports ============
import "./IERC20.sol";

interface ITokenRegistry {
    function isLocalOrigin(address _token) external view returns (bool);

    function ensureLocalToken(uint32 _domain, bytes32 _id) external returns (address _local);

    function mustHaveLocalToken(uint32 _domain, bytes32 _id) external view returns (IERC20);

    function getLocalAddress(uint32 _domain, bytes32 _id)
    external
    view
    returns (address _local);

    function getTokenId(address _token)
        external
        view
        returns (uint32, bytes32);

    function enrollCustom(
        uint32 _domain,
        bytes32 _id,
        address _custom
    ) external;

    function oldReprToCurrentRepr(address _oldRepr) external view returns (address _currentRepr);
}
