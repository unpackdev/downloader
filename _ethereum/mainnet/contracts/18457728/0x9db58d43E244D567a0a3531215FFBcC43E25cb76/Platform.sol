// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./IERC20.sol";

contract FreelanceChainPlatform {
    address payable public contractOwner;
    IERC20 public fctToken;
    IERC20 public daiToken;
    IERC20 public usdtToken;
    IERC20 public usdcToken;

    enum Currency { ETH, FCT, DAI, USDT, USDC }

    mapping(address => uint) public tokenBalances;

    constructor(IERC20 _fctToken, IERC20 _daiToken, IERC20 _usdtToken, IERC20 _usdcToken) {
        contractOwner = payable(msg.sender);

        fctToken = _fctToken;
        daiToken = _daiToken;
        usdtToken = _usdtToken;
        usdcToken = _usdcToken;

        tokenBalances[address(fctToken)] = fctToken.balanceOf(address(this));
        tokenBalances[address(daiToken)] = daiToken.balanceOf(address(this));
        tokenBalances[address(usdtToken)] = usdtToken.balanceOf(address(this));
        tokenBalances[address(usdcToken)] = usdcToken.balanceOf(address(this));
    }

    uint constant FEE_ETH = 0.005 ether;
    uint constant FEE_USD = 10 ether;
    uint constant FEE_FCT = 1 ether;

    mapping(uint => Project) public projects;
    mapping(uint => Application[]) public applications;
    mapping(uint => mapping(address => bool)) public hasApplied;

    uint[] public projectIds;
    uint public totalProjectsCount = 0;
    uint public nextProjectId = 1;

    event ProjectPosted(uint id);
    event ProjectUpdated(uint id);
    event ParticipantApplied(uint id, address participant, uint availableDate);
    event ParticipantApproved(uint id, address participant);
    event RewardReleased(uint id);

    struct Project {
        uint id;
        address payable author;
        address payable participant;
        uint reward;
        Currency rewardCurrency;
        bool isEligibleToDiscount;
        string title;
        string description;
        string[] skillsRequired;
        uint deadline;
        address payable[] candidates;
        bool rewardReleased;
    }

    struct Application {
        uint projectId;
        address payable applicant;
        uint bid;
        Currency bidCurrency;
        uint availableDate;
        bool isProjectEligibleToDiscount;
    }

    //
    // Payable functions

    function PreSaleInvest() public payable {
        uint start = 1675036800; // Nov 1st 0:00
        uint end = 1677628799; // Nov 30th 23:59

        require(
            block.timestamp >= start && block.timestamp <= end,
            "Pre-sale is not active"
        );

        uint minPurchase = 500 * 10 ** 18;
        uint rate = 16000;

        require(
            msg.value * rate >= minPurchase,
            "You have to buy at least 500 FCT"
        );

        uint tokensToBuy = msg.value * rate;

        require(
            fctToken.balanceOf(address(this)) >= tokensToBuy,
            "Not enough FCT tokens in contract"
        );

        require(
            fctToken.transfer(msg.sender, tokensToBuy),
            "Token transfer failed"
        );

        contractOwner.transfer(msg.value);
    }

    function postProject(string memory title, string memory description, string[] memory skillsRequired, uint deadline, uint reward, Currency currency, Currency rewardCurrency) public payable {
        if (currency == Currency.FCT) {
            require(
                fctToken.transferFrom(msg.sender, address(this), FEE_FCT),
                "Fee is not correct"
            );
        } else if (currency == Currency.DAI) {
            require(
                daiToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.USDT) {
            require(
                usdtToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.USDC) {
            require(
                usdcToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.ETH) {
            require(msg.value >= FEE_ETH, "Fee is not correct");
        }

        require(deadline > block.timestamp, "Deadline must be in the future");

        bool eligibilityStatus = (currency == Currency.FCT || rewardCurrency == Currency.FCT) ? true : false;

        Project storage p = projects[nextProjectId];
        p.id = nextProjectId;
        p.rewardReleased = false;
        p.author = payable(msg.sender);
        p.title = title;
        p.description = description;
        p.skillsRequired = skillsRequired;
        p.deadline = deadline;
        p.reward = reward;
        p.rewardCurrency = rewardCurrency;
        p.isEligibleToDiscount = eligibilityStatus;

        projectIds.push(nextProjectId);
        totalProjectsCount++;

        emit ProjectPosted(p.id);

        nextProjectId++;
    }

    function updateProject(uint id, uint newReward, string memory title, string memory description, string[] memory skillsRequired, uint deadline, Currency currency, Currency rewardCurrency) public payable {
        if (currency == Currency.FCT) {
            require(
                fctToken.transferFrom(msg.sender, address(this), FEE_FCT),
                "Fee is not correct"
            );
        } else if (currency == Currency.DAI) {
            require(
                daiToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.USDT) {
            require(
                usdtToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.USDC) {
            require(
                usdcToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.ETH) {
            require(msg.value >= FEE_ETH, "Fee is not correct");
        }

        require(deadline > block.timestamp, "Deadline must be in the future");

        Project storage p = projects[id];

        require(p.author == msg.sender, "Only author can update the project");

        require(
            p.participant == address(0),
            "Project info can't be updated after participant has been assigned"
        );

        bool eligibilityStatus = (currency == Currency.FCT || rewardCurrency == Currency.FCT) ? true : false;

        p.reward = newReward;
        p.title = title;
        p.description = description;
        p.skillsRequired = skillsRequired;
        p.deadline = deadline;
        p.rewardCurrency = rewardCurrency;
        p.isEligibleToDiscount = eligibilityStatus;

        emit ProjectUpdated(id);
    }

    function applyForProject(uint id, uint bid, uint availableDate, Currency currency, Currency bidCurrency) public payable {
        if (currency == Currency.FCT) {
            require(
                fctToken.transferFrom(msg.sender, address(this), FEE_FCT),
                "Fee is not correct"
            );
        } else if (currency == Currency.DAI) {
            require(
                daiToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.USDT) {
            require(
                usdtToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.USDC) {
            require(
                usdcToken.transferFrom(msg.sender, address(this), FEE_USD),
                "Fee is not correct"
            );
        } else if (currency == Currency.ETH) {
            require(msg.value >= FEE_ETH, "Fee is not correct");
        }

        Project storage p = projects[id];
        require(
            p.author != msg.sender,
            "Author cannot apply to their own project"
        );
        require(
            p.participant == address(0),
            "Project already has a participant"
        );
        require(
            availableDate > block.timestamp,
            "Available date must be in the future"
        );

        require(
            !hasApplied[id][msg.sender],
            "User has already applied to this project"
        );

        hasApplied[id][msg.sender] = true;

        p.candidates.push(payable(msg.sender));

        bool eligibilityStatus = (currency == Currency.FCT || bidCurrency == Currency.FCT) ? true : false;

        Application memory newApplication = Application({
            projectId: id,
            applicant: payable(msg.sender),
            bid: bid,
            bidCurrency: bidCurrency,
            isProjectEligibleToDiscount: eligibilityStatus,
            availableDate: availableDate
        });

        applications[id].push(newApplication);

        emit ParticipantApplied(id, msg.sender, availableDate);
    }

    function approveApplicant(uint id, address payable candidate) public payable {
        Project storage p = projects[id];
        
        Application memory candidateApplication;
        bool applicationExists = false;
        
        for (uint i = 0; i < applications[id].length; i++) {
            if (applications[id][i].applicant == candidate) {
                candidateApplication = applications[id][i];
                applicationExists = true;
                break;
            }
        }

        require(applicationExists, "This candidate has not applied");

        if (candidateApplication.bidCurrency == Currency.FCT) {
            require(
                fctToken.transferFrom(msg.sender, address(this), candidateApplication.bid),
                "Reward is not correct"
            );
        } else if (candidateApplication.bidCurrency == Currency.DAI) {
            require(
                daiToken.transferFrom(msg.sender, address(this), candidateApplication.bid),
                "Reward is not correct"
            );
        } else if (candidateApplication.bidCurrency == Currency.USDT) {
            require(
                usdtToken.transferFrom(msg.sender, address(this), candidateApplication.bid),
                "Reward is not correct"
            );
        } else if (candidateApplication.bidCurrency == Currency.USDC) {
            require(
                usdcToken.transferFrom(msg.sender, address(this), candidateApplication.bid),
                "Reward is not correct"
            );
        } else if (candidateApplication.bidCurrency == Currency.ETH) {
            require(msg.value == candidateApplication.bid, "Reward is not correct");
        }

        require(
            p.author == msg.sender,
            "Only author can approve the applicant"
        );
        require(
            p.participant == address(0),
            "A participant has already been approved"
        );

        p.participant = candidate;
        p.reward = candidateApplication.bid;
        p.rewardCurrency = candidateApplication.bidCurrency;
        p.isEligibleToDiscount = candidateApplication.isProjectEligibleToDiscount;

        emit ParticipantApproved(id, candidate);
    }

    function releaseReward(uint id) public payable {
        Project storage p = projects[id];
        require(
            p.participant != address(0),
            "No participant assigned to the project"
        );
        require(p.author == msg.sender, "Only author can release the reward");
        require(!p.rewardReleased, "Reward has already been released");

        uint platformCut;
        if (p.rewardCurrency == Currency.FCT) {
            platformCut = p.reward / 2000; // 0.05%
        } else {
            platformCut = p.reward / 200; // 0.5%
        }

        uint participantReward = p.reward - platformCut;
        
        // Transfer platform cut and participant reward
        if (p.rewardCurrency == Currency.FCT) {
            require(fctToken.transfer(contractOwner, platformCut), "Platform cut transfer failed");
            require(fctToken.transfer(p.participant, participantReward), "Participant reward transfer failed");
        } else if (p.rewardCurrency == Currency.DAI) {
            require(daiToken.transfer(contractOwner, platformCut), "Platform cut transfer failed");
            require(daiToken.transfer(p.participant, participantReward), "Participant reward transfer failed");
        } else if (p.rewardCurrency == Currency.USDT) {
            require(usdtToken.transfer(contractOwner, platformCut), "Platform cut transfer failed");
            require(usdtToken.transfer(p.participant, participantReward), "Participant reward transfer failed");
        } else if (p.rewardCurrency == Currency.USDC) {
            require(usdcToken.transfer(contractOwner, platformCut), "Platform cut transfer failed");
            require(usdcToken.transfer(p.participant, participantReward), "Participant reward transfer failed");
        } else if (p.rewardCurrency == Currency.ETH) {
            contractOwner.transfer(platformCut);
            p.participant.transfer(participantReward);
        } 

        p.rewardReleased = true;

        emit RewardReleased(id);
    }


    //
    // Read functions

    function getProjects() public view returns (uint[] memory) {
        return projectIds;
    }

    function getTotalProjectsCount() public view returns (uint256) {
        return totalProjectsCount;
    }

    function getProjectById(uint id) public view returns (uint, address, address, uint, Currency, string[] memory, string memory, string memory, uint, address[] memory) {
        Project memory p = projects[id];
        return (p.id, address(p.author), address(p.participant), p.reward, p.rewardCurrency, p.skillsRequired, p.title, p.description, p.deadline, stringsToAddresses(p.candidates));
    }

    function getFctBalance() public view returns (uint) {
        return tokenBalances[address(fctToken)];
    }

    //
    // Helper functions

    function getTotalLockedRewards() internal view returns (uint) {
        uint totalLocked = 0;
        for (uint i = 0; i < projectIds.length; i++) {
            uint id = projectIds[i];
            Project storage p = projects[id];
            if (p.participant != address(0) && !p.rewardReleased) {
                totalLocked += p.reward;
            }
        }
        return totalLocked;
    }

    function stringsToAddresses(address payable[] memory input) private pure returns (address[] memory) {
        address[] memory output = new address[](input.length);
        for (uint i = 0; i < input.length; i++) {
            output[i] = address(input[i]);
        }
        return output;
    }

    //
    // Contract owner functions

    function withdraw() public {
        require(
            msg.sender == contractOwner,
            "Only the contractOwner can withdraw"
        );

        uint totalLocked = getTotalLockedRewards();
        uint availableBalance = address(this).balance - totalLocked;

        require(availableBalance > 0, "No available balance for withdrawal");
        contractOwner.transfer(availableBalance);
    }
}
