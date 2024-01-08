//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract KlerosboardSuscription is Ownable {
    /* Events */
    /**
    *  @dev Emitted when the maintainer is changed.
    *  @param oldMaintainer address of the new maintainer.
    *  @param newMaintainer address of the new maintainer.
    */
    event MaintainerChanged(address indexed oldMaintainer, address indexed newMaintainer);

    /**
    *  @dev Emitted when the maintenance fee is changed.
    *  @param maintenanceFeeMultiplier new value of maintainance fee
    */
    event MaintenanceFeeChanged(uint maintenanceFeeMultiplier);

    /**
    *  @dev Emitted when the contract of ubiburner is changed.
    *  @param oldUbiburner address of the old contract.
    *  @param ubiburner address of the new contract.
    */
    event UBIBurnerChanged(address oldUbiburner, address ubiburner);

    /**
    *  @dev Emitted when the amount per month required of donation is changed.
    *  @param oldDonationAmount previous donation Amount
    *  @param donationAmount new donation Amount
    */
    event donationPerMonthChanged(uint256 oldDonationAmount, uint256 donationAmount);

    /**
    *  @dev Emitted when a donation it's made
    *  @param from who made the donation.
    *  @param amount amount of ETH donated.
    *  @param ethToUbiBurner amount of ETH sent to UBI Burner
    */
    event Donation(address indexed from, uint256 amount, uint256 ethToUbiBurner);

    /* Constants */
    /// @dev Contract Maintainer
    address public maintainer;
    /// @dev Maintenance Fee expresed in tens of thousands
    uint public maintenanceFeeMultiplier;
    /// @dev ubiburner Contract
    address public ubiburner;
    /// @dev Amount per month to Enable klerosboard Features
    uint256 public donationPerMonth;
    
    constructor(address _ubiburner, uint _maintenanceFee, uint96 _donationPerMonth) {
        maintainer = msg.sender;
        changeMaintenanceFee(_maintenanceFee);
        changeUBIburner(_ubiburner);
        changeDonationPerMonth(_donationPerMonth);
    }

    /**
    *  @dev Donate ETH
    */
    function donate() payable external {
        uint256 maintenanceFee = msg.value * maintenanceFeeMultiplier / 10000;
        uint256 ETHToBurnUBI = msg.value - maintenanceFee;

        // Send ETH - maintainanceFee to ubiburner
        (bool successTx, ) = ubiburner.call{value: ETHToBurnUBI}("");
        require(successTx, "ETH to ubiburner fail");

        emit Donation(msg.sender, msg.value, ETHToBurnUBI);
    }

    function changeMaintainer (address _maintainer) public onlyOwner {
        require(_maintainer != address(0), 'Maintainer could not be null');
        address oldMaintainer = maintainer;
        maintainer = _maintainer;
        emit MaintainerChanged(oldMaintainer, maintainer);
    }

    function changeMaintenanceFee (uint _newFee) public onlyOwner {
        require(_newFee <= 5000, '50% it is the max fee allowed');
        maintenanceFeeMultiplier = _newFee;
        // express maintainance as a multiplier in tens of thousands .
        emit MaintenanceFeeChanged(maintenanceFeeMultiplier);
    }

    function changeUBIburner (address _ubiburner) public onlyOwner {
        require(_ubiburner != address(0), 'UBIBurner could not be null');
        address oldUbiburner = ubiburner;
        ubiburner = _ubiburner;
        emit UBIBurnerChanged(oldUbiburner, ubiburner);
    }

    function changeDonationPerMonth (uint256 _donationPerMonth) public onlyOwner {
        require(_donationPerMonth > 0, 'donationPerMonth should not be zero');
        uint256 oldDonation = donationPerMonth;
        donationPerMonth = _donationPerMonth;
        emit donationPerMonthChanged(oldDonation, donationPerMonth);
    }

    function withdrawMaintenance() external {
        require(msg.sender == maintainer, 'Only maintainer can withdraw');
        payable(msg.sender).transfer(address(this).balance);
    }
}
