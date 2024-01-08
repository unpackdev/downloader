// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

import "./Ownable.sol";
import "./IInsurance.sol";

contract Registry is Ownable {
    string private constant ERROR_NOT_REGISTERED = "Not registered";

    IInsurance public insuranceManager;

    mapping(address => bool) public escrowContracts;

    event NewContract(
        address indexed escrowSmartContract,
        bytes32 cid,
        address indexed payer,
        address indexed payee
    );

    /** 
     * @dev Used to keep single event repository for different versions of escrow contracts.
     */
    constructor() Ownable() {
    }

    /** 
     * @dev Register smart-contract for insurance coverage.
     *
     * @param _insuranceManager Address of IInsurance contract.
     */
    function setInsuranceManager(address _insuranceManager) external onlyOwner {
        insuranceManager = IInsurance(_insuranceManager);
    }

    /** 
     * @dev Register escrow smart-contract with a universal minimal interface (no milestones, amendments etc).
     *
     * @param _cid Contract's IPFS cid.
     * @param _payer Party which pays for the contract or on behalf of which the funding was done.
     * @param _payee Party which recieves the payment.
     */
    function registerNewContract(bytes32 _cid, address _payer, address _payee) public {
        require(escrowContracts[msg.sender], ERROR_NOT_REGISTERED);
        emit NewContract(msg.sender, _cid, _payer, _payee);
    }

    /** 
     * @dev Register escrow smart-contract.
     *
     * @param _escrowContract Enable / disable escrow smart-contract.
     * @param _status true to enable, false to disable.
     */
    function toggleContractRegistration(address _escrowContract, bool _status) external onlyOwner {
        escrowContracts[_escrowContract] = _status;
    }
}
