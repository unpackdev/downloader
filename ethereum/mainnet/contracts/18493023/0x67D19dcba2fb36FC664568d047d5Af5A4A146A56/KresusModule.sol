// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Utils.sol";
import "./BaseModule.sol";
import "./KresusRelayer.sol";
import "./SecurityManager.sol";
import "./TransactionManager.sol";
import "./IKresusRegistry.sol";

/**
 * @title KresusModule
 * @notice Single module for Kresus vault.
 */
contract KresusModule is BaseModule, KresusRelayer, SecurityManager, TransactionManager {

    address public immutable kresusGuardian;

    /**
     * @param _storageAddr deployed instance of storage contract
     * @param _kresusRegistry deployed instance of Kresus registry
     * @param _kresusGuardian default guardian of kresus for recovery and unblocking
     */
    constructor (
        IStorage _storageAddr,
        IKresusRegistry _kresusRegistry,
        address _kresusGuardian
    )
        BaseModule(_storageAddr, _kresusRegistry)
    {
        require(_kresusGuardian != ZERO_ADDRESS, "KM: Invalid address");
        kresusGuardian = _kresusGuardian;
    }

    /**
     * @inheritdoc IModule
     */
    function init(
        address _vault,
        bytes calldata _initData
    )
        external
        override
        onlyVault(_vault)
    {
        (address newKbg, uint256 newTimeDelay) = abi.decode(_initData, (address, uint256));
        require(IVault(_vault).owner() != newKbg, "KM: Invalid KBG");
        IVault(_vault).enableStaticCall(address(this));
        _storage.setTimeDelay(_vault, newTimeDelay);
        _storage.setKbg(_vault, newKbg);
    }

    /**
     * @inheritdoc IModule
     */
    function addModule(
        address _vault,
        address _module,
        bytes memory _initData
    )
        external
        onlySelf()
    {
        require(kresusRegistry.isRegisteredModule(_module), "KM: module is not registered");
        IVault(_vault).authoriseModule(_module, true, _initData);
    }
    
    /**
     * @inheritdoc KresusRelayer
     */
    function getRequiredSignatures(
        address _vault,
        bytes calldata _data
    )
        public
        view
        override
        returns (uint256, Signature)
    {
        bytes4 methodId = Utils.functionPrefix(_data);

        if(_storage.isLocked(_vault)) {
            require(
                methodId == SecurityManager.unlock.selector ||
                methodId == SecurityManager.executeBequeathal.selector ||
                methodId == SecurityManager.disable.selector,
                "KM: method not allowed"
            );
            if(methodId == SecurityManager.unlock.selector) {
                return (kresusRegistry.getUnlockTd(), Signature.KBGAndKWG);
            }
        }

        if(_storage.isDisabled(_vault)) {
            require(
                methodId == SecurityManager.executeBequeathal.selector ||
                methodId == TransactionManager.multiCall.selector ||
                methodId == TransactionManager.multiCallToWhitelistedAddresses.selector ||
                methodId == SecurityManager.enable.selector,
                "KM: method not allowed"
            );
        }

        if (methodId == TransactionManager.multiCall.selector) {
            bool hasHumanGuardian = _storage.hasHumanGuardian(_vault);
            return hasHumanGuardian ? 
                (_storage.getTimeDelay(_vault), Signature.HG) :
                (_storage.getTimeDelay(_vault), Signature.KBG);
        }
        if(methodId == TransactionManager.multiCallToWhitelistedAddresses.selector) {
            bool hasHumanGuardian = _storage.hasHumanGuardian(_vault);
            return hasHumanGuardian ? (0, Signature.HG) : (0, Signature.KBG);
        }
        if(methodId == SecurityManager.lock.selector) {
            return (0, Signature.KWG);
        }
        if(
            methodId == SecurityManager.setHumanGuardian.selector ||
            methodId == SecurityManager.transferOwnership.selector ||
            methodId == SecurityManager.setTimeDelay.selector
        ) {
            return (_storage.getTimeDelay(_vault), Signature.KBG);
        }
        if(
            methodId == SecurityManager.removeHumanGuardian.selector ||
            methodId == SecurityManager.removeTrustee.selector
        ) {
            return (kresusRegistry.getRemoveGuardianTd(), Signature.KBG);
        }
        if(
            methodId == SecurityManager.addHumanGuardian.selector ||
            methodId == SecurityManager.addTrustee.selector ||
            methodId == KresusModule.addModule.selector
        ) {
            return (0, Signature.KBG);
        }
        if(
            methodId == SecurityManager.enable.selector ||
            methodId == SecurityManager.disable.selector ||
            methodId == SecurityManager.executeBequeathal.selector
        ) {
            return (0, Signature.KWG);
        }
        revert("KM: unknown method");
    }

    /**
     * @param _data _data The calldata for the required transaction.
     * @return Signature The required signature from {Signature} enum.
     */
    function getCancelRequiredSignatures(
        bytes calldata _data
    )
        public
        pure
        override
        returns(Signature)
    {
        bytes4 methodId = Utils.functionPrefix(_data);
        if(
            methodId == SecurityManager.setHumanGuardian.selector ||
            methodId == SecurityManager.removeHumanGuardian.selector ||
            methodId == SecurityManager.setTimeDelay.selector ||
            methodId == SecurityManager.transferOwnership.selector ||
            methodId == SecurityManager.removeTrustee.selector ||
            methodId == TransactionManager.multiCall.selector ||
            methodId == SecurityManager.unlock.selector
        ) {
            return Signature.Owner;
        }
        revert("KM: unknown method");
    }

    /**
    * @notice Validates the signatures provided with a relayed transaction.
    * @param _vault The target vault.
    * @param _signHash The signed hash representing the relayed transaction.
    * @param _signatures The signatures as a concatenated bytes array.
    * @param _option An Signature enum indicating whether the owner is required, optional or disallowed.
    * @return A boolean indicating whether the signatures are valid.
    */
    function validateSignatures(
        address _vault,
        bytes32 _signHash,
        bytes memory _signatures,
        Signature _option
    ) 
        public 
        view
        override
        returns (bool)
    {
        if(_signatures.length < 65) {
            return false;
        }

        address signer0 = Utils.recoverSigner(_signHash, _signatures, 0);

        if(_option == Signature.Owner) {
            return signer0 == IVault(_vault).owner();
        }
        if(_option == Signature.HG) {
            return _storage.isHumanGuardian(_vault, signer0);
        }
        if(_option == Signature.KBG || _option == Signature.KBGAndKWG) {
            if(_signatures.length > 65) {
                address signer1 = Utils.recoverSigner(_signHash, _signatures, 1);
                return _storage.isKbg(_vault, signer0) && signer1 == kresusGuardian;
            }
            return _storage.isKbg(_vault, signer0);
        }
        return signer0 == kresusGuardian;
    }
}