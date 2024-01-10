// SPDX-License-Identifier: MIT

//  author Name: Alex Yap
//  author-email: <echo@alexyap.dev>
//  author-website: https://alexyap.dev

pragma solidity ^0.8.0;

interface IMeSkullz {
    function balanceOf(address _user) external view returns (uint256 balance);
}

// Part: OpenZeppelin/openzeppelin-contracts@3.2.0/Address
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Skullz is ERC20, ReentrancyGuard, Ownable {
    //START 1645833600 - Saturday, February 26, 2022 8:00:00 AM GMT+08:00
    //END   1803513600 - Thursday, February 25, 2027 8:00:00 AM GMT+08:00, 5 years, 157680000
    uint256 constant public END = 1803513600;
    uint256 constant public BASE_RATE = 10 ether;

    // max supply 
    uint256 public constant MAX_YIELD_SUPPLY = 135050000 ether;
    uint256 public constant MAX_COMMUNITY_FUND_SUPPLY = 100000000 ether;
    uint256 public constant MAX_PUBLIC_SALES_SUPPLY = 50000000 ether;
    uint256 public constant MAX_TEAM_RESERVE_SUPPLY = 30000000 ether;

    // minted amount
    uint256 public totalYieldSupply;
    uint256 public totalCommunityFundSupply;
    uint256 public totalPublicSalesSupply;
    uint256 public totalTeamReserveSupply;

    //mapping
    mapping(address => bool) councillors;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    IMeSkullz public meskullzContract;

    event CouncillorAdded(address councillor);
    event CouncillorRemoved(address councillor);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _meskullz) ERC20("SKULLZ", "SKULLZ") {
        meskullzContract = IMeSkullz(_meskullz);
        addCouncillor(_meskullz);
    }

    function setInterface(address _meskullz) external onlyOwner {
        meskullzContract = IMeSkullz(_meskullz);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function isCouncillor(address _councillor) public view returns(bool) {
        return councillors[_councillor];
    }

    function addCouncillor(address _councillor) public onlyOwner {
       require(_councillor != address(0), "Cannot add null address");
       councillors[_councillor] = true;
       emit CouncillorAdded(_councillor);
    }

    function removeCouncillor(address _councillor) public onlyOwner {
        require(isCouncillor(_councillor), "Not a councillor");
        delete councillors[_councillor];
        emit CouncillorRemoved(_councillor);
    }

    // updated_amount = (balanceOf(user) * base_rate * delta / 86400) + amount * initial rate
    function updateRewardOnMint(address _user) external {
        require(councillors[msg.sender], "Unauthorized");

        uint256 time = min(block.timestamp, END);
        uint256 timerUser = lastUpdate[_user];
        uint256 timerRemainder = 0;

        //update reward count is this is not their first mint
        if (timerUser > 0) {
            rewards[_user] = rewards[_user] + (meskullzContract.balanceOf(_user) * BASE_RATE * ((time - timerUser) / 86400));
            timerRemainder = (time - timerUser) % 86400;
        } else {
            rewards[_user] = 0;
        }
        
        //set new last updated
        lastUpdate[_user] = time - timerRemainder;
    }

    // called on transfers
    function updateReward(address _from, address _to) external {
        require(councillors[msg.sender], "Unauthorized");
        
        uint256 time = min(block.timestamp, END);
        uint256 timerFrom = lastUpdate[_from];
        uint256 timerRemainderFrom = 0;
        
        if (timerFrom > 0) {
            rewards[_from] += meskullzContract.balanceOf(_from) * BASE_RATE * ((time - timerFrom) / 86400);
            timerRemainderFrom = (time - timerFrom) % 86400;
        }

        if (timerFrom != END) {
            lastUpdate[_from] = time - timerRemainderFrom;
        }

        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];
            uint256 timerRemainderTo = 0;

            if (timerTo > 0) {
                rewards[_to] += meskullzContract.balanceOf(_to) * BASE_RATE * ((time - timerTo) / 86400);
                timerRemainderTo = (time - timerTo) % 86400;
            }

            if (timerTo != END) {
                lastUpdate[_to] = time - timerRemainderTo;
            }
        }
    }

    function getReward(address _to) external nonReentrant{
        require(councillors[msg.sender], "Unauthorized");
        
        uint256 reward = rewards[_to];
        if (reward > 0) {
            require(
                totalYieldSupply + reward <= MAX_YIELD_SUPPLY,
                "Maximum yield supply reached"
            );

            rewards[_to] = 0;
            totalYieldSupply += reward;
            
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    function communityFundMint(address to, uint256 amount) external nonReentrant{
        require(councillors[msg.sender], "Unauthorized");
        require(
            totalCommunityFundSupply + amount <= MAX_COMMUNITY_FUND_SUPPLY,
            "Maximum community fund supply reached"
        );

        totalCommunityFundSupply += amount;
        _mint(to, amount);
    }

    function publicSalesMint(address to, uint256 amount) external nonReentrant{
        require(councillors[msg.sender], "Unauthorized");
        require(
            totalPublicSalesSupply + amount <= MAX_PUBLIC_SALES_SUPPLY,
            "Maximum public sales supply reached"
        );

        totalPublicSalesSupply += amount;
        _mint(to, amount);
    }

    function teamReserveMint(address to, uint256 amount) external nonReentrant{
        require(councillors[msg.sender], "Unauthorized");
        require(
            totalTeamReserveSupply + amount <= MAX_TEAM_RESERVE_SUPPLY,
            "Maximum team reserve supply reached"
        );

        totalTeamReserveSupply += amount;
        _mint(to, amount);
    }

    function burn(address _from, uint256 _amount) external nonReentrant{
        require(councillors[msg.sender], "Unauthorized");
        
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns(uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 pending = meskullzContract.balanceOf(_user) * BASE_RATE * ((time - lastUpdate[_user]) / 86400);
        return rewards[_user] + pending;
    }
}