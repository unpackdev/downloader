//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract MSLServiceAgreement2 {

    string public constant explanation = "This smart contract is an agreement made between Client and Contractor.";
    string public constant agreementLink = "ipfs://Qmar4ryJDGEwGfQPsMDbdcXoPU1DfKd73VAbZLkJdeesuj";
    string public constant gatewayedAgreementLink = "https://moonsama.mypinata.cloud/ipfs/Qmar4ryJDGEwGfQPsMDbdcXoPU1DfKd73VAbZLkJdeesuj";

    address public constant client = 0x853180d35ad72768118597f77Db4D7ac73099028;
    address public constant contractor = 0x22C35C3373511433A85e7BdDae0a93AFe6F9143a;

    bool public clientSigned;
    bool public contractorSigned;
    bool public isSignedByAllAndBinding;

    function signClient() external {
        require(client == msg.sender, "Only client can sign");
        clientSigned = true;
        isSignedByAllAndBinding = contractorSigned && clientSigned;
    }

    function signContractor() external {
        require(contractor == msg.sender, "Only contractor can sign");
        contractorSigned = true;
        isSignedByAllAndBinding = contractorSigned && clientSigned;
    }
}