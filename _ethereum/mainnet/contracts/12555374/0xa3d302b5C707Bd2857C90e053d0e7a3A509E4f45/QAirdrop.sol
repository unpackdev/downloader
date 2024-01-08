// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IQSettings.sol";

/**
 * @author fantasy
 */
contract QAirdrop is ContextUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;

    // events
    event AddWhitelistedContract(address indexed whitelisted);
    event RemoveWhitelistedContract(address indexed whitelisted);
    event SetVerifier(address indexed verifier);
    event ClaimQStk(address indexed user, uint256 amount);

    bool public airdropClaimable; // describes airdrop is claimable
    address public verifier; // airdrop key verifier
    mapping(address => bool) public whitelistedContracts;
    mapping(bytes => bool) public claimed;

    IQSettings public settings;

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(
            settings.getManager() == msg.sender,
            "QAirdrop: caller is not the manager"
        );
        _;
    }

    function initialize(address _settings, address _verifier)
        external
        initializer
    {
        __Context_init();
        __ReentrancyGuard_init();

        settings = IQSettings(_settings);
        verifier = _verifier;
        airdropClaimable = false;
    }

    function addWhitelistedContract(address _contract) external onlyManager {
        _addWhitelistedContract(_contract);

        emit AddWhitelistedContract(_contract);
    }

    function removeWhitelistedContract(address _contract) external onlyManager {
        _removeWhitelistedContract(_contract);

        emit RemoveWhitelistedContract(_contract);
    }

    function setVerifier(address _verifier) external onlyManager {
        verifier = _verifier;

        emit SetVerifier(_verifier);
    }

    function setAirdropClaimable(bool _airdropClaimable) external onlyManager {
        airdropClaimable = _airdropClaimable;
    }

    function verify(
        address _recipient,
        uint256 _qstkAmount,
        bytes memory _signature
    ) external view returns (bool) {
        return _verify(_recipient, _qstkAmount, _signature);
    }

    function claimQStk(
        address _recipient,
        uint256 _qstkAmount,
        bytes memory _signature
    ) external nonReentrant {
        require(
            _verify(_recipient, _qstkAmount, _signature),
            "QAirdrop: invalid signature"
        );

        address qstk = settings.getQStk();

        require(
            IERC20Upgradeable(qstk).balanceOf(address(this)) >= _qstkAmount,
            "QAirdrop: not enough qstk balance"
        );

        require(airdropClaimable, "QAirdrop: not claimable");
        require(!claimed[_signature], "QAirdrop: already claimed");
        IERC20Upgradeable(qstk).safeTransfer(_recipient, _qstkAmount);

        claimed[_signature] = true;
        emit ClaimQStk(_recipient, _qstkAmount);
    }

    // withdraw locked QSTK and use it on other contract
    function withdrawLockedQStk(
        address _recipient,
        uint256 _qstkAmount,
        bytes memory _signature
    ) external nonReentrant returns (uint256) {
        require(
            _verify(_recipient, _qstkAmount, _signature),
            "QAirdrop: invalid signature"
        );

        require(
            whitelistedContracts[msg.sender],
            "QAirdrop: not whitelisted contract"
        );

        if (_qstkAmount > 0 && !claimed[_signature]) {
            address qstk = settings.getQStk();
            require(
                IERC20Upgradeable(qstk).balanceOf(address(this)) >= _qstkAmount,
                "QAirdrop: not enough qstk balance"
            );

            require(
                AddressUpgradeable.isContract(msg.sender),
                "QAirdrop: not contract address"
            );

            claimed[_signature] = true;
            IERC20Upgradeable(qstk).safeTransfer(msg.sender, _qstkAmount);

            emit ClaimQStk(_recipient, _qstkAmount);

            return _qstkAmount;
        }

        return 0;
    }

    function getMessageHash(address _to, uint256 _amount)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _amount));
    }

    function setSettings(address _settings) external onlyManager {
        settings = IQSettings(_settings);
    }

    // internal functions

    function _addWhitelistedContract(address _contract) internal {
        require(
            AddressUpgradeable.isContract(_contract),
            "QAirdrop: not contract address"
        );

        whitelistedContracts[_contract] = true;
    }

    function _removeWhitelistedContract(address _contract) internal {
        require(
            AddressUpgradeable.isContract(_contract),
            "QAirdrop: not contract address"
        );

        whitelistedContracts[_contract] = false;
    }

    function _verify(
        address _recipient,
        uint256 _qstkAmount,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_recipient, _qstkAmount);

        return
            messageHash.toEthSignedMessageHash().recover(signature) == verifier;
    }
}
