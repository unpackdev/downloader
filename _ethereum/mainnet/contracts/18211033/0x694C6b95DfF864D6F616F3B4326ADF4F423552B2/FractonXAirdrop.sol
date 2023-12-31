// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./IFractonXAirdrop.sol";

contract FractonXAirdrop is IFractonXAirdrop , AccessControlUpgradeable {
    using ECDSAUpgradeable for bytes32;

    uint256 public sinatureLifetime; // 60 seconds = 1 minutes

    mapping(bytes32 => bool) private _usedSignatures;
    mapping(address => bool) private _validSigners;

    receive() external payable {}

    function initialize() public initializer {
        __fractonx_airdrop_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function __fractonx_airdrop_init() internal onlyInitializing {
        __AccessControl_init();
    }

    function claim(
        uint256 snapshotTime,
        address tokenAddr,
        uint256 amount,
        uint256 timestamp,
        bytes memory signature
    ) external {
        bytes32 hash = keccak256(abi.encodePacked(snapshotTime, tokenAddr, msg.sender));
        require(!_usedSignatures[hash], "Signature Used");
        _usedSignatures[hash] = true;

        uint256 timestamp2 = timestamp / 1000;

        require(
            timestamp2 + sinatureLifetime > block.timestamp,
            "Signature Expired"
        );

        require(snapshotTime < timestamp, "Invalid Param");

        require(
            _validSignature(
                snapshotTime,
                tokenAddr,
                amount,
                timestamp,
                signature
            ),
            "Invalid Signature"
        );

        if (tokenAddr == address(0)) {
            bool isSuccess = payable(msg.sender).send(amount);
            require(isSuccess, "Failed to send Platform Token");
        } else {
            uint8 tokenDecimals = IERC20MetadataUpgradeable(tokenAddr).decimals();
            amount = _convertDecimals(amount, 18, tokenDecimals);
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddr), msg.sender, amount);
        }

        emit Claim(msg.sender, snapshotTime, tokenAddr, amount);
    }

    function isClaim(uint256 snapshotTime, address tokenAddr, address caller) external view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(snapshotTime, tokenAddr, caller));
        return _usedSignatures[hash];
    }

    function withdraw(
        address tokenAddr,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddr == address(0)) {
            bool isSuccess = payable(to).send(amount);
            require(isSuccess, "Failed to send Platform Token");
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(tokenAddr), to, amount);
        }
    }

    function _convertDecimals(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        } else if (fromDecimals < toDecimals) {
            return amount * (10 ** (toDecimals - fromDecimals));
        } else {
            return amount / (10 ** (fromDecimals - toDecimals));
        }
    }

    function _validSignature(
        uint256 signatureId,
        address tokenAddr,
        uint256 amount,
        uint256 timestamp,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "FRACTONX_AIRDROP",
                msg.sender,
                signatureId,
                tokenAddr,
                amount,
                timestamp
            )
        );
        address signer = hash.toEthSignedMessageHash().recover(signature);

        return _validSigners[signer];
    }

    function setValidSigner(address signer, bool isValid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(signer != address(0), "Invalid signer address");
        _validSigners[signer] = isValid;

        emit SetValidSigner(signer, isValid);
    }

    function setSignatureLifetime(uint256 lifetime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sinatureLifetime = lifetime;
    }

    function isSignatureBeenUsed(
        bytes32 sinatureId
    ) public view returns (bool) {
        return _usedSignatures[sinatureId];
    }

    function isValidSigner(address signer) public view returns (bool) {
        return _validSigners[signer];
    }
}
