//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.6;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

contract SwashTeamVestingUpgradable is OwnableUpgradeable {
    uint256 internal constant periodLength = 1 days;
    uint256 public initialValue;
    uint256 public totalVest;
    uint256 public vestingDays;
    uint256 public totalShares;

    address public token;

    struct Recipient {
        uint256 withdrawnAmount;
        uint256 recipientTotalShare;
        uint256 recipientInitialShare;
        uint256 recipientDailyShare;
        uint256 startDate;
        uint256 revokedDate;
    }

    string public name;
    uint256 public totalRecipients;
    address[] public recipientList;
    mapping(address => Recipient) public recipients;

    event LogRecipientAdded(address recipient, uint256 recipientTotalShare, uint256 recipientInitialShare, uint256 recipientDailyShare);
    event LogTokensClaimed(address recipient, uint256 amount);

    modifier onlyValidShareAmount(uint256 _recipientTotalShare) {
        require(
            _recipientTotalShare > 0 && _recipientTotalShare <= totalVest,
            "Provided _recipientTotalShare should be less than or equals to totalVest"
        );
        _;
    }

    constructor() {
    }

    function initialize(
        string memory _name,
        address _tokenAddress,
        uint256 _totalVest,
        uint256 _vestingDays,
        uint256 _initialValue
    )  public initializer{
        require(
            _initialValue <= 100,
            "_initialValue should be between 0 and 100"
        );
        require(
            _tokenAddress != address(0),
            "Token Address can't be zero address"
        );
        __Ownable_init();
        name = _name;
        token = _tokenAddress;
        totalVest = _totalVest;
        vestingDays = _vestingDays;
        initialValue = _initialValue;
    }


    function percDiv(uint256 period, Recipient memory recipient)
    public
    view
    returns (uint256)
    {

    return (period * recipient.recipientDailyShare) + recipient.recipientInitialShare;
    }


    function revokeRecipient(address _recipientAddress, uint256 _revokedDate) public onlyOwner {

        require(
            recipients[_recipientAddress].recipientTotalShare > 0,
            "Recipient is not available"
        );
        require(
            _revokedDate > 0,
            "_revokedDate is zero"
        );
        recipients[_recipientAddress].revokedDate = _revokedDate;

    }

    function activateRecipient(address _recipientAddress) public onlyOwner {

        require(
            recipients[_recipientAddress].recipientTotalShare > 0,
            "Recipient is not available"
        );
        recipients[_recipientAddress].revokedDate = 0;

    }

    function addRecipient(
        address _recipientAddress,
        uint256 _recipientTotalShare,
        uint256 _startDate
    ) public onlyOwner onlyValidShareAmount(_recipientTotalShare) {
        require(
            _recipientAddress != address(0),
            "Recipient Address can't be zero address"
        );
        require(
            recipients[_recipientAddress].recipientTotalShare == 0,
            "Recipient already has values saved"
        );
        require(_startDate > 0, "Start Date can't be zero");

        totalShares = totalShares + _recipientTotalShare;
        require(totalShares <= totalVest, "Total shares exceeds totalVest");
        totalRecipients++;
        recipientList.push(_recipientAddress);

        uint256 _recipientInitialShare = (initialValue * _recipientTotalShare) / 100;
        uint256 _recipientDailyShare = (_recipientTotalShare - _recipientInitialShare) / vestingDays;

        recipients[_recipientAddress] = Recipient(0, _recipientTotalShare, _recipientInitialShare, _recipientDailyShare, _startDate, 0);
        emit LogRecipientAdded(_recipientAddress, _recipientTotalShare, _recipientDailyShare, _recipientInitialShare);
    }

    function getStartDate(address _recipientAddress) public view returns(uint256){
        require(
            recipients[_recipientAddress].recipientTotalShare > 0,
            "Recipient is not available"
        );
        return recipients[_recipientAddress].startDate;
    }

    function addMultipleRecipients(
        address[] memory _recipients,
        uint256[] memory _recipientTotalShares,
        uint256[] memory _startDates
    ) external onlyOwner {
        require(
            _recipients.length < 200,
            "The recipients array size must be smaller than 200"
        );
        require(
            _recipients.length == _recipientTotalShares.length,
            "The _recipients and _recipientTotalShares are with different length"
        );
        require(
            _recipients.length == _startDates.length,
            "The _recipients and _startDates are with different length"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            addRecipient(_recipients[i], _recipientTotalShares[i], _startDates[i]);
        }
    }


    function claim() external {
        require(recipients[msg.sender].startDate != 0, "The vesting start date not set");

        require(block.timestamp >= recipients[msg.sender].startDate, "The vesting hasn't started");

        (uint256 owedAmount, uint256 calculatedAmount) = calculateAmounts();


        recipients[msg.sender].withdrawnAmount = calculatedAmount;
        emit LogTokensClaimed(msg.sender, owedAmount);
        require(IERC20(token).transfer(msg.sender, owedAmount), "error_transfer");

    }


    function hasClaim() public view returns (uint256) {
        if (block.timestamp < recipients[msg.sender].startDate) {
            return 0;
        }

        (uint256 owedAmount,) = calculateAmounts();
        return owedAmount;
    }

    function calculateAmounts()
    internal
    view
    returns (uint256 _owedAmount, uint256 _calculatedAmount)
    {
        uint256 endTime = recipients[msg.sender].revokedDate > 0 ? recipients[msg.sender].revokedDate : block.timestamp;
        if(endTime < recipients[msg.sender].startDate){
            return (0, 0);
        }
        uint256 period = (endTime - recipients[msg.sender].startDate) / (periodLength);
        Recipient memory recipient = recipients[msg.sender];


        //cuz on day 0 one share will release and day n, n+1 share will be released
        period = period + 1;

        if (period >= vestingDays) {
            //Time is completed and all recipient share should be payed
            _calculatedAmount = recipient.recipientTotalShare;
        }
        else {
            _calculatedAmount = percDiv(
                period,
                recipient
            );
            if (_calculatedAmount > recipient.recipientTotalShare) {
                _calculatedAmount = recipient.recipientTotalShare;
            }
        }

        _owedAmount = _calculatedAmount - recipients[msg.sender].withdrawnAmount;

        return (_owedAmount, _calculatedAmount);
    }
}
