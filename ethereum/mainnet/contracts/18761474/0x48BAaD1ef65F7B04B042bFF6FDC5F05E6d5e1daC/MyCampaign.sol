/**
 *Submitted for verification at Etherscan.io on 2023-12-11
*/

// SPDX-License-Identifier: MyCampaign.vip by Osher Haim Glick aka encrypto.bite
pragma solidity ^0.8.23;

contract MyCampaign {

    //A Campaign struct
    struct Campaign {
        string phoneNumber; //phonenumber or email of the campaign owner
        address owner; //public wallet address of the campaign owner
        string title; //title of the campaign
        string description; //description of the campaign
        uint256 target; //the target amount for raising in the campaign
        uint256 endDate; //the date of the end of the campaign
        uint256 amountCollected; //the amount that the campaign collected so far
        string videoLinkFromPinata; //the Hash (from pinata.cloud) of the video
        string typeOfCampaign; //the category of the campaign
        address[] donators; //list of the donators
        uint256[] donations; //the amount each donator donated
        string[] comments; //the comments of the donators
        bool cashedOut; //check if the campaign took the money and finished or not yet
        bool isCheckedByWebsite; //checks if the campaign is verified
        string websiteComment; //a comment of the website on the campaign, like how much it collected or proofes for achieve the goals the campaign intended
    }

    // Events for transparancy
    event CampaignCreated(uint256 campaignId, address owner, string title);
    event DonationReceived(uint256 campaignId, address donor, uint256 amount);
    event CampaignWithdrawn(uint256 campaignId, address owner, uint256 amount);
    event CampaignClosed(uint256 campaignId, address byModerator);
    event ModeratorAdded(address moderator, address bySuperMod);
    event SuperModeratorAdded(address superModerator);
    event ModeratorRemoved(address moderator, address bySuperMod);
    event SuperModeratorRemoved(address superModerator);
    event CampaignReported(uint256 campaignId, address reporter);
    event CampaignStopped(uint256 campaignId);


    //Global Vars
    mapping (uint256 => Campaign) public campaigns;
    uint256[] public activeCampaignIDs;
    uint256 public numberOfCampaigns = 0;
    mapping(address => bool) moderators; // Mapping to check if an address is a moderator
    mapping(address => bool) superModerators; // Mapping to check if an address is a supermoderator
    mapping(uint256 => uint256) reportBalances; // Mapping to store report balances for campaigns
    mapping(uint256 => uint256) reportCounts; // Mapping to store report counts for campaigns
    uint256 constant REPORT_COST = 1e16; // Cost to report a campaign
    uint256 constant MIN_DONATION = 1e16; //Minimum amount for donation
    address public contractOwner; //Osher Haim Glick
    mapping(uint256 => mapping(address => uint256)) individualReportAmounts; // Mapping to store individual report amounts for campaigns
    mapping(uint256 => address[]) campaignReporters; // Mapping to store addresses of all reporters for a campaign
    mapping(uint256 => mapping(address => bool)) hasReported; //Mapping to check if a user already reported a campaign
    mapping(uint256 => mapping(address => string)) reportReasons; //Mapping to get the reason of the report
    address[] private modAddresses; //list of moderators
    address[] private superModAddresses; //list of supermoderators


    //Checks the user doesnt attack the SmartContract by entering to a function before the function ends it ends.
    //For example: It required for functions like withdraw so no user can withdraw more then once, the user must wait until the function ends to try again
    bool internal locked = false;
    modifier reentrancyGuard() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _MyCampaign) {
        contractOwner = _MyCampaign;
    }

    //modifier to make some of the functions only for the contract owner, Osher Haim Glick
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can execute this");
        _;
    }

    //modifier to make some of the functions only for a moderator
    modifier onlyModerator() {
        require(moderators[msg.sender], "Only a moderator can execute this");
        _;
    }

    //modifier to make some of the functions only for a supermoderator
    modifier onlySuperModerator() {
        require(superModerators[msg.sender], "Only a SuperModerator can execute this");
        _;
    }



    //The next 8 functions are about creating a string (means "text") of fructional numbers because in code there is no fructional numbers.
    //for example the number 5.567 cannot be calculated in solidity code. only numbers like 5 or 9, only whole numbers.
    //so, to create the amount the campaign owners collected represented in the website correctly I needed to create those functions.
   
    //the amount of digits after the point for a fructional number.
    uint256 constant DECIMAL_FACTOR = 1000;

    //add 2 whole numbers
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    //substract 2 whole numbers
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }
    
    //multiplay 2 whole numbers divided by the decimal factor for achieving the text convert and fructional number correctly
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / DECIMAL_FACTOR;
    }

    //divide 2 whole numbers multiplay by the decimal factor for achieving the text convert and fructional number correctly
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return (a * DECIMAL_FACTOR ) / b;
    }

    // finaly convert a whole number to a decimal fructional string (text) representation
    function uintToDecimalString(uint256 value) internal pure returns (string memory) {
        uint256 integerPart = value / DECIMAL_FACTOR;
        uint256 fractionalPart = value % DECIMAL_FACTOR;

        // Ensure the fractional part is represented correctly
        string memory fractionalPartStr = uintToString(fractionalPart);
        if (fractionalPart < DECIMAL_FACTOR / 10) {
            fractionalPartStr = string(abi.encodePacked("0", fractionalPartStr));
        }

        return string(abi.encodePacked(uintToString(integerPart), ".", fractionalPartStr));
    }

    // convert whole number to string (to text)
    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    //normalizeFractionalPart in the number
    function normalizeFractionalPart(uint256 fractionalPart) internal pure returns (string memory) {
        uint256 requiredDigits = calculateDigits(DECIMAL_FACTOR);
        uint256 actualDigits = calculateDigits(fractionalPart);

        // Add leading zeros if necessary
        string memory leadingZeros = new string(requiredDigits - actualDigits);
        for (uint256 i = 0; i < requiredDigits - actualDigits; i++) {
            leadingZeros = string(abi.encodePacked("0", leadingZeros));
        }

        return string(abi.encodePacked(leadingZeros, uintToString(fractionalPart)));
    }

    //calculate how much digits the number has
    function calculateDigits(uint256 number) internal pure returns (uint256 digits) {
        while (number != 0) {
            number /= 10;
            digits++;
        }
    }

    //create new campaign
    function createCampaign(string memory _phoneNumber , string memory _title, string memory _description, uint256 _target, uint256 _endDate, string memory _videoLinkFromPinata, string memory _type) public reentrancyGuard returns (uint256) {
        require(_endDate > block.timestamp, "The endDate should be a date in the future");
        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = msg.sender;
        campaign.phoneNumber = _phoneNumber;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.endDate = _endDate;
        campaign.videoLinkFromPinata = _videoLinkFromPinata;
        campaign.typeOfCampaign = _type;
        campaign.amountCollected = 0;
        campaign.cashedOut = false;
        numberOfCampaigns++;
        campaign.isCheckedByWebsite = false;
        campaign.websiteComment = "Hasn't verified yet";
        
        emit CampaignCreated(numberOfCampaigns-1, msg.sender, _title);

        return numberOfCampaigns-1;
    }

    //let the moderator verify the campaign and add proofes from the campaign owner afterwards
    function verifyCampaign(uint256 _id,string memory _websiteComment) public onlyModerator {
        Campaign storage campaign = campaigns[_id];
        campaign.isCheckedByWebsite = true;
        campaign.websiteComment = _websiteComment;
        activeCampaignIDs.push(_id);
    }

    //donate to a campaign
    function donateToCampaign(uint256 _id, string memory _comment) public payable reentrancyGuard {
        require( campaigns[_id].cashedOut==false ,"Campaign already cashed out");
        require(_id < numberOfCampaigns && campaigns[_id].owner != address(0)&& campaigns[_id].isCheckedByWebsite == true, "Invalid campaign Id or the campaign hasn't reviewed yet by the website");
        require(msg.value>=MIN_DONATION,"Minimum donation amount is 0.01 ETH");
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.endDate, "Donation period for this campaign has ended");
        campaign.comments.push(_comment);
        uint256 amount = msg.value;
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.amountCollected += amount;
        emit DonationReceived(_id, msg.sender, amount);
    }

    //get all the donators and donations of specified campaign
    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory, string[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations, campaigns[_id].comments);
    }

    //get a list of all the campaigns
    function getCampaigns() view public returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }

    //add 3 text vars to create one sentence
    function concatenate(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    //withdraw the campaign after it finished (can be after the end date or after achieving the goal)
    function withdrawCampaign(uint256 _id) public reentrancyGuard {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.owner, "Only the campaign owner can withdraw");
        require( campaign.target <= campaign.amountCollected || block.timestamp > campaign.endDate, "Cannot withdraw before reaching the target amount or before the campaign's end time");
        require( campaign.cashedOut==false ,"Campaign already cashed out");
        require(campaign.isCheckedByWebsite==true, "Please note that this campaign has not yet been reviewed by our team. For further assistance or inquiries, kindly reach out to us at support@YourCampaign.io");
        uint256 fee = campaign.amountCollected * 35 / 1000;
        uint256 amountToWithdraw = campaign.amountCollected - fee;
        
        payable(contractOwner).transfer(fee + reportBalances[_id]);
        payable(campaign.owner).transfer(amountToWithdraw);

        for (uint256 i = 0; i < activeCampaignIDs.length; i++) {
            if (activeCampaignIDs[i] == _id) {
                activeCampaignIDs[i] = activeCampaignIDs[activeCampaignIDs.length - 1];
                activeCampaignIDs.pop();
                break;
            }
        }
        
        campaign.amountCollected = 0;

        campaign.cashedOut = true;
        string memory part1 = "The campaign raised ";
        string memory part2 = uintToDecimalString(div(amountToWithdraw,1e18));
        string memory part3 = " Ethereum successfully!";
        
        campaign.websiteComment = concatenate(part1, part2, part3);
        emit CampaignWithdrawn(_id, campaign.owner, amountToWithdraw);
    }

    //refund all the reporters if campaign closed for any reason
    function RefundReportFunds(uint256 _campaignId) internal {
        uint256 totalReportFunds = reportBalances[_campaignId];
        address[] memory reporters = campaignReporters[_campaignId];

        for (uint256 i = 0; i < reporters.length; i++) {
            address reporter = reporters[i];
            uint256 refundAmount = individualReportAmounts[_campaignId][reporter];

            if (refundAmount > 0 && totalReportFunds >= refundAmount) {
                payable(reporter).transfer(refundAmount);
                totalReportFunds -= refundAmount;
                individualReportAmounts[_campaignId][reporter] = 0;
            }
        }
        reportBalances[_campaignId] = 0;
    }

    //close a campaign if its against website rules
    function closeCampaign(uint256 _id) public onlySuperModerator {
        Campaign storage campaign = campaigns[_id];
        if (campaign.donations.length>0) {
            returnFundsToDonators(_id);
        }

        for (uint256 i = 0; i < activeCampaignIDs.length; i++) {
            if (activeCampaignIDs[i] == _id) {
                activeCampaignIDs[i] = activeCampaignIDs[activeCampaignIDs.length - 1];
                activeCampaignIDs.pop();
                break;
            }
        }

        campaign.isCheckedByWebsite = false;
        campaign.videoLinkFromPinata = "X";
        campaign.websiteComment = "Refunded because of illegal activity";
        emit CampaignClosed(_id, msg.sender);
    }

    //just like the name of the function, add a new moderator for the website
    function addModerator(address _moderator) public onlySuperModerator {
        moderators[_moderator] = true;
        modAddresses.push(_moderator); // Add to the array
        emit ModeratorAdded(_moderator, msg.sender);
    }

    //remove a moderator
    function removeModerator(address _moderator) public onlySuperModerator {
        moderators[_moderator] = false;
        // Remove from the array
        for (uint256 i = 0; i < modAddresses.length; i++) {
            if (modAddresses[i] == _moderator) {
                modAddresses[i] = modAddresses[modAddresses.length - 1];
                modAddresses.pop();
                break;
            }
        }
        emit ModeratorRemoved(_moderator, msg.sender);
    }

    //add supermoderator
    function addSuperModerator(address _superModerator) public onlyOwner {
        superModerators[_superModerator] = true;
        superModAddresses.push(_superModerator); // Add to the array
        emit SuperModeratorAdded(_superModerator);
    }

    //remove supermoderator
    function removeSuperModerator(address _superModerator) public onlyOwner {
        superModerators[_superModerator] = false;
        // Remove from the array
        for (uint256 i = 0; i < superModAddresses.length; i++) {
            if (superModAddresses[i] == _superModerator) {
                superModAddresses[i] = superModAddresses[superModAddresses.length - 1];
                superModAddresses.pop();
                break;
            }
        }
        emit SuperModeratorRemoved(_superModerator);
    }

    //get all the modertors addresses if needed to remove one
    function getModsAddresses() onlySuperModerator public view returns (address[] memory) {
        return modAddresses;
    }

    //get all the supermodertors addresses if needed to remove one
    function getSuperModsAddresses() onlySuperModerator public view returns (address[] memory) {
        return superModAddresses;
    }

    //report a campaign, cost 0.01 ETH to avoid spam
    function reportCampaign(uint256 _campaignId, string memory _reason) public payable reentrancyGuard {
        require(msg.value >= REPORT_COST, "Insufficient report fee, must pay 0.01 ETH to report.");
        require(!hasReported[_campaignId][msg.sender], "You have already reported this campaign");
        
        hasReported[_campaignId][msg.sender] = true;
        
        if(individualReportAmounts[_campaignId][msg.sender] == 0) {
            campaignReporters[_campaignId].push(msg.sender);
        }

        individualReportAmounts[_campaignId][msg.sender] += msg.value;
        reportBalances[_campaignId] += msg.value;
        reportCounts[_campaignId]++;

        emit CampaignReported(_campaignId, msg.sender);

        reportReasons[_campaignId][msg.sender] = _reason;
    }

    //stop campaign in the middle if needed before choosing if to continue it or close it
    function stopCampaignByMod(uint256 _campaignId) public onlyModerator {
        Campaign storage campaign = campaigns[_campaignId];
        campaign.isCheckedByWebsite = false;
        campaign.websiteComment = "Stopped for review because of suspicious activity";
        emit CampaignStopped(_campaignId);
    }

    //refund all the donators if a campaign closed for any reason
    function returnFundsToDonators(uint256 _campaignId) internal {
        for (uint256 i = 0; i < campaigns[_campaignId].donators.length; i++) {
            payable(campaigns[_campaignId].donators[i]).transfer(campaigns[_campaignId].donations[i]);
        }
        RefundReportFunds(_campaignId);
        campaigns[_campaignId].amountCollected = 0;
    }

    //get all the reports of a specified campaign, available only to moderator
    function getReportReasonsOfCampaign(uint256 campaignId) public view onlyModerator returns (address[] memory, string[] memory) {
        address[] memory reportersForThisCampaign = campaignReporters[campaignId];
        string[] memory reasonsForThisCampaign = new string[](reportersForThisCampaign.length);

        for (uint256 i = 0; i < reportersForThisCampaign.length; i++) {
            reasonsForThisCampaign[i] = reportReasons[campaignId][reportersForThisCampaign[i]];
            }

        return (reportersForThisCampaign, reasonsForThisCampaign);
    }

    //get info of campaign by phone or email
    function getCampaignsByPhoneOrEmail(string memory _phoneNumber) public onlyModerator view returns (Campaign[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (keccak256(abi.encodePacked(campaigns[i].phoneNumber)) == keccak256(abi.encodePacked(_phoneNumber))) {
                count++;
            }
        }
        Campaign[] memory campaignsByPhoneOrEmail = new Campaign[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            if (keccak256(abi.encodePacked(campaigns[i].phoneNumber)) == keccak256(abi.encodePacked(_phoneNumber))) {
                campaignsByPhoneOrEmail[j] = campaigns[i];
                j++;
            }
        }
        return campaignsByPhoneOrEmail;
    }

}