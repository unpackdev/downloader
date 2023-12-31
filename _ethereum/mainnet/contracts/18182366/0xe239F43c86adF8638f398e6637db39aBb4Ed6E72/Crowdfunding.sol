// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
   
    struct Campaign {
        address owner;
        string title;
        string url;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        address invited;
        bool exists;
    }
    
    IERC20 private _token;
    address private _owner;
    address public _crowdfunding;

    address payable public wallet;

    mapping(uint256 => Campaign) public campaigns;
    mapping (uint256 => bool) public votingsCampaigns;

    uint256 public numberOfCampaigns = 0;
    uint256 public tokenAmount;

    modifier onlyOwner() {
        require(msg.sender == _owner, "owner only");
        _;
    }

    event TokenDonate(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 amount
    );

    constructor(IERC20 token, uint256 _tokenAmount, address payable _wallet) ReentrancyGuard() {
        require(_wallet != address(0));
        _token = token;
        tokenAmount = _tokenAmount * 10 ** 18;
        _owner = msg.sender;
        wallet = _wallet;
    }

    function createCampaign(string memory _title, string memory _url, string memory _description, uint256 _target, uint256 _deadline, string memory _image, address _invited) nonReentrant public returns (uint256) {
        uint _titleLength = bytes(_title).length;
        uint _descriptionLength = bytes(_description).length;
        require(_target >= 100 * 10 ** 18, "Mininum voice 100 GRAv");
        require(_target <= 500 * 10 ** 18, "Maximum voice 500 GRAv");
        require(_deadline > block.timestamp, 'Check you deadline');
        require(_getBalance(msg.sender) > 1000 * 10 ** 18, "You must need to buy GRAV");
        require(_titleLength < 50, "Title is so long");
        require(_descriptionLength < 200, "Description is so long");
        Campaign storage campaign = campaigns[numberOfCampaigns];       

        campaign.owner = msg.sender;
        campaign.title = _title;
        campaign.url = _url;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.invited = _invited;
        campaign.exists = true;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) nonReentrant public payable {
        uint256 bal = _getBalance(msg.sender);
        
        Campaign storage campaign = campaigns[_id];
        require(_getBalance(msg.sender) > 1000 * 10 ** 18, "You must need to buy GRAV");
        require(campaign.exists == true, 'Project missing');
        require(campaign.deadline > block.timestamp, 'Voting over you can create a new');
        
        _preValidatePurchase(msg.sender, 0, bal, campaign.owner, _id);
        _processPurchase(campaign.owner, tokenAmount);

        emit TokenDonate(
            msg.sender,
            campaign.owner,
            tokenAmount
        );       
        
        campaign.donators.push(msg.sender);
        campaign.donations.push(tokenAmount);
        campaign.amountCollected = campaign.amountCollected + tokenAmount;
        
    }

    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        Campaign storage campaign = campaigns[_id];
        require(campaign.exists == true, 'Project missing');
        require(_getBalance(msg.sender) > 1000 * 10 ** 18, "You must need to buy GRAV");
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    function getCampaign(uint256 _id) public view returns (Campaign memory) {
        require(_getBalance(msg.sender) > 1000 * 10 ** 18, "Insufficient GRAV");
        Campaign storage campaign = campaigns[_id];
        require(campaign.exists == true, 'Project missing');

        return campaign;
    }

    function _getBalance(address _addr) internal view returns (uint256) {
        return _token.balanceOf(_addr);
    }

    function _deliverTokens(
        address _to,
        uint256 _tokenAmount
    )
        internal
    {
        _token.transfer( _to, _tokenAmount);
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _bal,
        address _campaingOwner,
        uint256 _id
    )
        internal view
    {
        require(_beneficiary != address(0));
        require(_weiAmount == 0);
        require(_bal > 1000 * 10 ** 18, "Insufficient GRAV");
        require(_campaingOwner != msg.sender, "Owner can`t voting");
        require(votingsCampaigns[_id], "Please provide a project number in support");
    }

    function _processPurchase(
        address _to,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens( _to, _tokenAmount);
    }

    function _getTokenAmount()
        public view returns (uint256)
    {
        return tokenAmount;
    }

    function setVoting(uint256 _id, uint256 _amount)
       nonReentrant public payable
    {
        uint256 bal = _getBalance(msg.sender);
        
        Campaign storage campaign = campaigns[_id];
        require(campaign.exists == true, 'Project missing');
        require(campaign.deadline > block.timestamp, "Voting over you can create a new");
        require(msg.sender != address(0));
        require(msg.sender == campaign.owner, "Publication owner only");
        require(bal > 1000 * 10 ** 18, "Insufficient GRAV");
        require(_amount >= 100 * 10 ** 18, "Minimum voting");
        require(_amount <= 500 * 10 ** 18, "Maximum voting");
        _processPurchase(_crowdfunding, _amount);

        emit TokenDonate(
            msg.sender,
            _crowdfunding,
            _amount
        );    
        votingsCampaigns[_id] = true;
    }

    function getVoting(uint256 _id) external view returns(bool) {
        return votingsCampaigns[_id];
    }

    function setCrowdfundingAddress(address _crowdfund) external onlyOwner {
        _crowdfunding = _crowdfund;
    }

}