// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IVesting.sol";
import "./IStripToken.sol";

contract Presale {
    using SafeMath for uint256;

    address private owner;

    struct PresaleBuyer {
        uint256 amountDepositedWei; // Funds token amount per recipient.
        uint256 amountStrip; // Rewards token that needs to be vested.
    }

    mapping(address => PresaleBuyer) public recipients; // Presale Buyers

    uint256 public constant MAX_ALLOC_STRIP = 2e8 * 1e18; // 200,000,000 STRIP is the max allocation for each presale buyer
    uint256 public constant MAX_ALLOC_WEI = 505e15; // 0.5 ETH + 1% tax is the max allocation for each presale buyer
    uint256 public constant IDS = 120e27; // Total StripToken amount for presale : 120b
    uint256 public constant PERIOD = 2 weeks; // Presale Period

    uint256 public startTime; // Presale start time
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds token to after presale

    bool private isPresaleStarted;
    uint256 public soldStripAmount;

    IStripToken public stripToken; // Rewards Token : Token for distribution as rewards.
    IVesting private vestingContract; // Vesting Contract

    event PresaleRegistered(address _registeredAddress, uint256 _weiAmount, uint256 _stripAmount);
    event PresaleStarted(uint256 _startTime);
    event PresalePaused(uint256 _endTime);
    event MultiSigAdminUpdated(address _multiSigAdmin);

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier whileOnGoing() {
        require(block.timestamp >= startTime, "Presale has not started yet");
        require(block.timestamp <= startTime + PERIOD, "Presale has ended");
        require(isPresaleStarted, "Presale has ended or paused");
        _;
    }

    modifier whileFinished() {
        require(block.timestamp > startTime + PERIOD, "Presale has not ended yet!");
        _;
    }

    modifier whileDeposited() {
        require(getDepositedStrip() >= IDS, "Deposit enough Strip tokens to the vesting contract first!");
        _;
    }

    constructor(address _stripToken, address payable _multiSigAdmin) {
        owner = msg.sender;

        stripToken = IStripToken(_stripToken);
        multiSigAdmin = _multiSigAdmin;

        isPresaleStarted = false;
    }

    /********************** Internal ***********************/
    
    /**
     * @dev Get the StripToken amount of vesting contract
     */
    function getDepositedStrip() internal view returns (uint256) {
        address addrVesting = address(vestingContract);
        return stripToken.balanceOf(addrVesting);
    }

    /**
     * @dev Get remaining StripToken amount of vesting contract
     */
    function getUnsoldStrip() internal view returns (uint256) {
        uint256 totalDepositedStrip = getDepositedStrip();
        return totalDepositedStrip.sub(soldStripAmount);
    }

    /********************** External ***********************/
    
    function remainingStrip() external view returns (uint256) {
        return getUnsoldStrip();
    }

    function isPresaleGoing() external view returns (bool) {
        return isPresaleStarted && block.timestamp >= startTime && block.timestamp <= startTime + PERIOD;
    }

    /**
     * @dev Start presale after checking if there's enough strip in vesting contraact
     */
    function startPresale() external whileDeposited onlyOwner {
        require(!isPresaleStarted, "StartPresale: Presale has already started!");
        isPresaleStarted = true;
        startTime = block.timestamp;
        emit PresaleStarted(startTime);
    }

    /**
     * @dev Pause the ongoing presale by emergency
     */
    function pausePresaleByEmergency() external onlyOwner {
        isPresaleStarted = false;
        emit PresalePaused(block.timestamp);
    }

    /**
     * @dev All remaining funds will be sent to multiSig admin  
     */
    function setMultiSigAdminAddress(address payable _multiSigAdmin) external onlyOwner {
        require (_multiSigAdmin != address(0x00));
        multiSigAdmin = _multiSigAdmin;
        emit MultiSigAdminUpdated(multiSigAdmin);
    }

    function setStripTokenAddress(address _stripToken) external onlyOwner {
        require (_stripToken != address(0x00));
        stripToken = IStripToken(_stripToken);
    }

    function setVestingContractAddress(address _vestingContract) external onlyOwner {
        require (_vestingContract != address(0x00));
        vestingContract = IVesting(_vestingContract);
    }

    /** 
     * @dev After presale ends, we withdraw funds to the multiSig admin
     */ 
    function withdrawRemainingFunds() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");

        uint256 weiBalance = address(this).balance;
        require(weiBalance > 0, "Withdraw: No ETH balance to withdraw");

        (bool sent, ) = multiSigAdmin.call{value: weiBalance}("");
        require(sent, "Withdraw: Failed to withdraw remaining funds");
       
        return weiBalance;
    }

    /**
     * @dev After presale ends, we withdraw unsold StripToken to multisig
     */ 
    function withdrawUnsoldStripToken() external whileFinished onlyOwner returns (uint256) {
        require(multiSigAdmin != address(0x00), "Withdraw: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");

        uint256 unsoldStrip = getUnsoldStrip();

        require(
            stripToken.transferFrom(address(vestingContract), multiSigAdmin, unsoldStrip),
            "Withdraw: can't withdraw Strip tokens"
        );

        return unsoldStrip;
    }

    /**
     * @dev Receive Wei from presale buyers
     */ 
    function deposit(address sender) external payable whileOnGoing returns (uint256) {
        require(sender != address(0x00), "Deposit: Sender should be valid address");
        require(multiSigAdmin != address(0x00), "Deposit: Project Owner address hasn't been set!");
        require(address(vestingContract) != address(0x00), "Withdraw: Set vesting contract!");
        require(vestingContract.getVestingPlan(sender) == 0, "Deposit: sender should not be allowed to participate in presale");
        
        uint256 weiAmount = msg.value;
        uint256 newDepositedWei = recipients[sender].amountDepositedWei.add(weiAmount);
        uint256 weiWithoutTax = weiAmount.mul(100).div(101);   // 1% of tax for each purchase

        require(MAX_ALLOC_WEI >= newDepositedWei, "Deposit: Can't exceed the MAX_ALLOC!");

        uint256 newStripAmount = weiWithoutTax.mul(MAX_ALLOC_STRIP).div(5e17);
        require(soldStripAmount + newStripAmount <= IDS, "Deposit: All sold out");

        recipients[sender].amountDepositedWei = newDepositedWei;
        soldStripAmount = soldStripAmount.add(newStripAmount);

        recipients[sender].amountStrip = recipients[sender].amountStrip.add(newStripAmount);
        vestingContract.addNewRecipient(sender, recipients[sender].amountStrip, 0);

        require(weiAmount > 0, "Deposit: No ETH balance to withdraw");

        (bool sent, ) = multiSigAdmin.call{value: weiAmount}("");
        require(sent, "Deposit: Failed to send Ether");

        emit PresaleRegistered(sender, weiAmount, recipients[sender].amountStrip);

        return recipients[sender].amountStrip;
    }
}

