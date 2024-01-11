// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Initializable.sol";
import "./Math.sol";
import "./Context.sol";
import "./Multicall.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./IAssetVault.sol";

/// @author Philippe Dumonet
contract AssetVault is Context, Multicall, Initializable, ERC721Holder, ERC1155Holder, IAssetVault {
    using SafeERC20 for IERC20;

    // slot n+0
    address public owner;
    uint64 public lastPing;

    // slot n+1
    bytes32 public guardiansMerkleRoot;

    modifier onlyOwner() {
        _checkOwnerCalling();
        _;
    }

    receive() external payable {
        if (_msgSender() == owner) _ping();
    }

    function initialize(address _firstOwner, bytes32 _guardiansMerkleRoot) external initializer {
        _ping();
        _setGuardiansMerkleRoot(_guardiansMerkleRoot);
        _transferOwner(address(0), _firstOwner);
    }

    function recoverAsGuardianTo(
        address _newOwner,
        uint256 _delay,
        bytes32[] memory _proof
    ) external {
        // read slot together
        address previousOwner = owner;
        uint256 lastStoredPing = lastPing;
        // solhint-disable-next-line not-rely-on-time
        if (lastStoredPing + _delay > block.timestamp) revert DelayNotPassed();
        address guardian = _msgSender();
        if (!isGuardian(guardian, _delay, _proof)) revert InvalidMerkleProof();
        _ping();
        _transferOwner(previousOwner, _newOwner);
        emit GuardianRecovered(guardian, _newOwner, _delay, _proof);
    }

    // -- General Admin Methods --

    // solhint-disable-next-line no-empty-blocks
    function ping() external onlyOwner {}

    function transferOwnership(address _newOwner) external {
        address previousOwner = _checkOwnerCalling();
        _transferOwner(previousOwner, _newOwner);
    }

    function updateGuardianMerkle(bytes32 _newGuardiansMerkleRoot) external onlyOwner {
        _setGuardiansMerkleRoot(_newGuardiansMerkleRoot);
    }

    // -- Asset Managing Methods --

    function transferNative(address payable _recipient, uint256 _value) external onlyOwner {
        if (_value == 0) {
            _value = address(this).balance;
            if (_value == 0) return;
        }
        Address.sendValue(_recipient, _value);
    }

    function transferToken(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (_amount == 0) {
            _amount = _token.balanceOf(address(this));
            if (_amount == 0) return;
        }
        _token.safeTransfer(_to, _amount);
    }

    function transferTokenFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (_amount == 0) {
            _amount = Math.min(_token.balanceOf(_from), _token.allowance(_from, address(this)));
            if (_amount == 0) return;
        }
        _token.safeTransferFrom(_from, _to, _amount);
    }

    function transferNFT(
        IERC721 _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external onlyOwner {
        _token.safeTransferFrom(_from, _to, _tokenId);
    }

    function transferCollectible(
        IERC1155 _collectible,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        _collectible.safeTransferFrom(_from, _to, _tokenId, _amount, "");
    }

    function doCustomCall(
        address _target,
        uint256 _value,
        bytes calldata _calldata,
        bool _requireSuccess
    ) external onlyOwner returns (bool success, bytes memory returndata) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, returndata) = _target.call{value: _value}(_calldata);
        Address.verifyCallResult(
            success || !_requireSuccess,
            returndata,
            "AssetVault: Call reverted"
        );
    }

    // -- Guardian Merkle Proof View Methods --

    function guardianLeaf(address _guardian, uint256 _delay) public pure returns (bytes32 leaf) {
        // equivalent to leaf = keccak256(abi.encode(_guardian, _delay));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(0x00, _guardian)
            mstore(0x20, _delay)
            leaf := keccak256(0x00, 0x40)
        }
    }

    function isGuardian(
        address _guardian,
        uint256 _delay,
        bytes32[] memory _proof
    ) public view returns (bool) {
        return MerkleProof.verify(_proof, guardiansMerkleRoot, guardianLeaf(_guardian, _delay));
    }

    function _checkOwnerCalling() internal returns (address) {
        _ping();
        address currentOwner = owner;
        if (_msgSender() != currentOwner) revert NotOwner();
        return currentOwner;
    }

    function _ping() internal {
        // solhint-disable-next-line not-rely-on-time
        lastPing = uint64(block.timestamp);
        emit Ping();
    }

    function _transferOwner(address _previousOwner, address _newOwner) internal {
        if (_newOwner == address(0)) revert NewOwnerZeroAddress();
        owner = _newOwner;
        emit OwnershipTransferred(_previousOwner, _newOwner);
    }

    function _setGuardiansMerkleRoot(bytes32 _newGuardiansMerkleRoot) internal {
        guardiansMerkleRoot = _newGuardiansMerkleRoot;
        emit GuardiansUpdate(_newGuardiansMerkleRoot);
    }
}
