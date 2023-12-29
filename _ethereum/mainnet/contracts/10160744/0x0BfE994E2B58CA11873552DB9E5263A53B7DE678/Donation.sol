pragma solidity >=0.4.22 <0.7.0;

contract Donation {
    
    address public owner;
    string public donor;
    string public donationDestination;
    bool public isDonated = false;
    uint256 public donationValueGwei;
	uint256 public totalDonationValueGwei;
	uint256 public donationValueEuro;
	uint256 public totalDonationValueEuro;
    uint public numberDonations;
    
    function Donation(string _donor) {
        donor = _donor;
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function DonateInEth(uint256 _realDonationValueGwei, uint256 _realDonationValueEuro,  string _donationDestination) onlyOwner {
        if(_realDonationValueGwei > 0) {
			donationDestination = _donationDestination;
			donationValueEuro = _realDonationValueEuro;
			donationValueGwei = _realDonationValueGwei;
			totalDonationValueGwei += _realDonationValueGwei;
			totalDonationValueEuro += _realDonationValueEuro;
            numberDonations++;
            isDonated = true;
        } else {
            revert();
        }
    }
    
}