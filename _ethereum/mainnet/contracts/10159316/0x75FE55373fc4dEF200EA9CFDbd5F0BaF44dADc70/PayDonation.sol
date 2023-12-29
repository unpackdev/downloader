pragma solidity >=0.4.22 <0.7.0;

contract PayDonation {
    
    address public owner;
    address public donateAdress = 0x0368f97B2e9536Ed4e58e9f0e05984EA77F438f4;
    string public nameOrCompany;
    string public email;
    string public adress;
    string public postalCode;
    string public nifOrDni;
    string public project;
    uint public numberDonations;
    uint public totalReceived = 0;

    function PayDonation(string _project) payable {
        project = _project;
        owner = msg.sender;
    }
    
    function DonateInEth(string _nameOrCompany, string _email, string _adress, string _postalCode, string _nifOrDni) payable {
        if(msg.value > 0) {
            nameOrCompany = _nameOrCompany;
            email = _email;
            adress = _adress;
            postalCode = _postalCode;
            nifOrDni = _nifOrDni;
            donateAdress.transfer(this.balance);
            updateTotal();
            numberDonations++;
        } else {
            revert();
        }
    }
    
    function updateTotal() internal {
        totalReceived += msg.value;
    }
    
}