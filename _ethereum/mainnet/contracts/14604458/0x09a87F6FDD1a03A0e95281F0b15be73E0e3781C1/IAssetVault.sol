// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

interface IAssetVault is IERC721Receiver, IERC1155Receiver {
    error NotOwner();
    error NewOwnerZeroAddress();
    error DelayNotPassed();
    error InvalidMerkleProof();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GuardiansUpdate(bytes32 indexed newMerkleRoot);
    event Ping();
    event GuardianRecovered(
        address indexed guardian,
        address indexed newOwner,
        uint256 delay,
        bytes32[] proof
    );

    function initialize(address _firstOwner, bytes32 _guardiansMerkleRoot) external;

    function ping() external;

    function recoverAsGuardianTo(
        address _newOwner,
        uint256 _delay,
        bytes32[] memory _proof
    ) external;

    function transferOwnership(address _newOwner) external;

    function updateGuardianMerkle(bytes32 _newGuardiansMerkleRoot) external;

    function transferNative(address payable _recipient, uint256 _value) external;

    function transferToken(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function transferTokenFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function transferNFT(
        IERC721 _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function transferCollectible(
        IERC1155 _collectible,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    struct CustomCall {
        bool requireSuccess;
        address target;
        uint256 value;
        bytes data;
    }

    function doCustomCall(
        address _target,
        uint256 _value,
        bytes calldata _calldata,
        bool _requireSuccess
    ) external returns (bool, bytes memory);

    function owner() external view returns (address);

    function lastPing() external view returns (uint64);

    function guardiansMerkleRoot() external view returns (bytes32);

    function guardianLeaf(address _guardian, uint256 _delay) external pure returns (bytes32);

    function isGuardian(
        address _guardian,
        uint256 _delay,
        bytes32[] memory _proof
    ) external view returns (bool);
}
