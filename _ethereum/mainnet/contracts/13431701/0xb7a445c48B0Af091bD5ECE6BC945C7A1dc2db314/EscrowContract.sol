// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./IRegistry.sol";
import "./ContractContext.sol";

abstract contract EscrowContract is ContractContext {
    string private constant ERROR_CONTRACT_EXITS = "Contract exists";
    string private constant ERROR_EMPTY_DELEGATE = "Invalid delegate";

    address private constant EMPTY_ADDRESS = address(0);

    IRegistry public immutable TRUSTED_REGISTRY;

    event NewContractPayer(
        bytes32 indexed cid,
        address indexed payer,
        address indexed delegate
    );

    event NewContractPayee(
        bytes32 indexed cid,
        address indexed payee,
        address indexed delegate
    );

    /**
     * @dev Single registry is used to store contract data from different versions of escrow contracts.
     *
     * @param _registry Address of universal registry of all contracts.
     */
    constructor(address _registry) {
        TRUSTED_REGISTRY = IRegistry(_registry);
    }

    /**
     * @dev Prepare contract between parties.
     *
     * @param _cid Contract's IPFS cid.
     * @param _payer Party which pays for the contract or on behalf of which the funding was done.
     * @param _payerDelegate Delegate who can release or dispute contract on behalf of payer.
     * @param _payee Party which recieves the payment.
     * @param _payeeDelegate Delegate who can refund or dispute contract on behalf of payee.
     */
    function _registerContract(
        bytes32 _cid,
        address _payer,
        address _payerDelegate,
        address _payee,
        address _payeeDelegate
    ) internal {
        require(contracts[_cid].payer == EMPTY_ADDRESS, ERROR_CONTRACT_EXITS);

        if (_payerDelegate == EMPTY_ADDRESS) _payerDelegate = _payer;
        if (_payerDelegate == EMPTY_ADDRESS) _payeeDelegate = _payee;
        contracts[_cid] = EscrowUtilsLib.Contract({
            payer: _payer,
            payerDelegate: _payerDelegate,
            payee: _payee,
            payeeDelegate: _payeeDelegate
        });
        emit NewContractPayer(_cid, _payer, _payerDelegate);
        emit NewContractPayee(_cid, _payee, _payeeDelegate);

        TRUSTED_REGISTRY.registerNewContract(_cid, _payer, _payee);
    }

    /**
     * @dev Change delegate for one party of a deal.
     * Caller should be either payer or payee.
     *
     * @param _cid Contract's IPFS cid.
     * @param _newDelegate Address for a new delegate.
     */
    function changeDelegate(bytes32 _cid, address _newDelegate) external {
        require(_newDelegate != EMPTY_ADDRESS, ERROR_EMPTY_DELEGATE);
        if (contracts[_cid].payer == msg.sender) {
            contracts[_cid].payerDelegate = _newDelegate;
        } else if (contracts[_cid].payee == msg.sender) {
            contracts[_cid].payeeDelegate = _newDelegate;
        } else {
            revert();
        }
    }
}