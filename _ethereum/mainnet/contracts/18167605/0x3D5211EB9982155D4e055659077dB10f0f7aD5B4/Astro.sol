
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;
import "./Initializable.sol";

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ScarabICO is Initializable {
    //define the admin of ICO
    address public owner;
    address public fundWallet;
    //  address public inputtoken;
    address public outputtoken;

    bool public claimenabled ;
    bool public investingenabled ;
    uint8 icoindex;

    mapping(address => bool) public claimBlocked;
    address[] public whitelistaddressesTier1;
    address[] public whitelistaddressesTier2;

    mapping(address => uint256) public UserTier;

    uint256 public totalsupply;

    uint256 public round ;

    mapping(address => uint256) public userinvested;
    address[] public investors;
    mapping(address => bool) public existinguser;
    mapping(address => uint256) public userremaininigClaim;
    mapping(address => uint8) public userclaimround;

    uint256 public Tier1maxInvestment ;
    uint256 public Tier2maxInvestment ;

    bool tierInitialized ;

    uint256 public tokenPrice;

    uint256 public idoTime;
    uint256 public claimTime;

    //hardcap
    uint256 public icoTarget;

    //define a state variable to track the funded amount
    uint256 public receivedFund;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "callable not owner");
        _;
    }
    function Initialize(
        address _fundWallet //admin wallet

    ) public initializer {
        require(_fundWallet != address(0), "address can't be 0");
        owner = msg.sender;
        fundWallet=_fundWallet;
    }

    function checkTier(address _user) public view returns (uint256 _tier) {
        require(_user != address(0), "null address");
        uint256 tier = 0;
        tier = UserTier[_user];
        return tier;
    }

    function checkMaxInvestment(address _user)
        public
        view
        returns (uint256 _maxInv)
    {
        uint256 tier = checkTier(_user);

        uint256 maxInv = 0;
        if (round == 1 || round == 0) {
            if (
                (round == 1 && tier == 1) ||
                (round == 0 && checkWhitelistTierWise(_user, 1))
            ) {
                maxInv = Tier1maxInvestment;
            } else if (
                (round == 1 && tier == 2) ||
                (round == 0 && checkWhitelistTierWise(_user, 2))
            ) {
                maxInv = Tier2maxInvestment;
            }
        } else {
            uint256 _balance = address(msg.sender).balance;
            maxInv = Tier1maxInvestment;
            if (_balance < Tier1maxInvestment) {
                maxInv = _balance;
            }
        }
        return maxInv;
    }

    function checkWhitelistTierWise(address _user, uint256 _tier)
        public
        view
        returns (bool)
    {
        if (_tier == 1) {
            address[] memory users = whitelistaddressesTier1;
            for (uint256 i = 0; i < users.length; i++) {
                if (users[i] == _user) {
                    return true;
                }
            }
            return false;
        } else if (_tier == 2) {
            address[] memory users = whitelistaddressesTier2;
            for (uint256 i = 0; i < users.length; i++) {
                if (users[i] == _user) {
                    return true;
                }
            }
            return false;
        } else {
            return false;
        }
    }

    function checkWhitelist(address _user) public view returns (bool) {
        uint256 tier = UserTier[_user];

        if (tier == 1) {
            address[] memory users = whitelistaddressesTier1;
            for (uint256 i = 0; i < users.length; i++) {
                if (users[i] == _user) {
                    return true;
                }
            }
            return false;
        } else if (tier == 2) {
            address[] memory users = whitelistaddressesTier2;
            for (uint256 i = 0; i < users.length; i++) {
                if (users[i] == _user) {
                    return true;
                }
            }
            return false;
        } else {
            return false;
        }
    }

    function Investing() external payable {
        require(investingenabled == true, "ICO in not active");
        uint256 _amount = msg.value;
        if (round == 0) {
            bool iswhitelisted = checkWhitelist(msg.sender);
            require(iswhitelisted == true, "Not whitelisted address");
            uint256 Tier = UserTier[msg.sender];
            if (Tier == 1) {
                require(
                    _amount <= Tier1maxInvestment,
                    "Investment not in allowed range"
                );
            } else if (Tier == 2) {
                require(
                    _amount <= Tier2maxInvestment,
                    "Investment not in allowed range"
                );
            }
        } else if (round == 1) {
            uint256 Tier = UserTier[msg.sender];

            if (Tier == 1) {
                require(
                    _amount <= Tier1maxInvestment,
                    "Investment not in allowed range"
                );
                UserTier[msg.sender] = 1;
            } else if (Tier == 2) {
                require(
                    _amount <= Tier2maxInvestment,
                    "Investment not in allowed range"
                );
                UserTier[msg.sender] = 1;
            }
        } else if (round == 2) {
            require(
                _amount <= Tier1maxInvestment,
                "Investment not in allowed range"
            );
            UserTier[msg.sender] = 2;
        }

        // check claim Status
        require(claimenabled == false, "Claim active");
        //check for hard cap
        require(
            icoTarget >= receivedFund + _amount,
            "Target Achieved. Investment not accepted"
        );
        require(_amount > 0, "min Investment not zero");
        require(
            _amount <= remainingContribution(msg.sender),
            "max Investment reached"
        );

        existinguser[msg.sender] = true;
        investors.push(msg.sender);
        userinvested[msg.sender] += _amount;
        receivedFund = receivedFund + _amount;
        userremaininigClaim[msg.sender] = ((userinvested[msg.sender] *
            tokenPrice) / 1000);
        (bool sucess, ) = fundWallet.call{value: _amount}("");
        require(sucess, "failed withdarwInputToken");
        
    }

    function remainingContribution(address _account)
        public
        view
        returns (uint256)
    {
        uint256 _rem = checkMaxInvestment(_account) - userinvested[_account];
        return _rem;
    }

    function claimTokens() public {
        // check anti-bot
        require(claimenabled == true, "Claim not start");

        require(investingenabled == false, "Ico active");

        require(
            claimBlocked[msg.sender] == false,
            "Sorry, Bot address not allowed"
        );

        // check ico Status

        // check claim Status

        // bool iswhitelisted = checkWhitelist(msg.sender);
        uint256 redeemtokens = userremaininigClaim[msg.sender];
        require(redeemtokens > 0, "No tokens to Claim");
        require(existinguser[msg.sender] == true, "Already claim");
        existinguser[msg.sender] = false;
        userinvested[msg.sender] = 0;
        userremaininigClaim[msg.sender] = 0;
        userclaimround[msg.sender] = 0;
        UserTier[msg.sender] = 0;
        IBEP20(outputtoken).transfer(
            msg.sender,
            userremaininigClaim[msg.sender]
        );

    }

    function checkICObalance(uint8 _token)
        public
        view
        returns (uint256 _balance)
    {
        if (_token == 1) {
            return IBEP20(outputtoken).balanceOf(address(this));
        } else if (_token == 2) {
            return address(this).balance;
        } else {
            return 0;
        }
    }

    function withdarwInputToken(address _admin) public onlyOwner {
        uint256 raisedamount = address(this).balance;
        require(raisedamount > 0, "no token to withdraw");
        (bool sucess, ) = _admin.call{value: raisedamount}("");
        require(sucess, "failed withdarwInputToken");
    }

    function startIco() external onlyOwner {
        require(claimenabled == false, "Claim live");
        require(icoindex == 0, "Cannot restart ico");
        investingenabled = true;
    }

    function stopIco() external onlyOwner {
        require(claimenabled == false, "Claim live");
        investingenabled = false;
    }

    function startClaim() external onlyOwner {
        claimenabled = true;
        investingenabled = false;
        icoindex = icoindex + 1;
    }

    function setIdoTime(uint256 _time) external onlyOwner {
        idoTime = _time;
    }

    function setClaimTime(uint256 _time) external onlyOwner {
        claimTime = _time;
    }

    function stopClaim() external onlyOwner {
        claimenabled = false;
    }

    function startAstroshotRound() public onlyOwner {
        round = 1; //privateround
    }


    function startNormalRound() public onlyOwner {
        round = 2; //publicround
    }

    function blockClaim(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            claimBlocked[_users[i]] = true;
        }
    }

    function unblockClaim(address user) external onlyOwner {
        claimBlocked[user] = false;
    }

    function addWhitelistTier1(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistaddressesTier1.push(_users[i]);
            UserTier[_users[i]] = 1;
        }
    }

    function addWhitelistTier2(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistaddressesTier2.push(_users[i]);
            UserTier[_users[i]] = 2;
        }
    }

    function withdrawOutputToken(address _admin, uint256 _amount)
        public
        onlyOwner
    {
        uint256 remainingamount = IBEP20(outputtoken).balanceOf(address(this));
        require(remainingamount >= _amount, "Not enough token to withdraw");
        IBEP20(outputtoken).transfer(_admin, _amount);
    }

    function initializeTier(uint256 _val1, uint256 _val2) external onlyOwner {
        require(
            tierInitialized == false,
            "Max Investment already, initialized"
        );

        Tier1maxInvestment = _val1; //200
        Tier2maxInvestment = _val2; //425
        tierInitialized = true;
    }

    function resetICO() public onlyOwner {
        for (uint256 i = 0; i < investors.length; i++) {
            if (existinguser[investors[i]] == true) {
                existinguser[investors[i]] = false;
                userinvested[investors[i]] = 0;
                userremaininigClaim[investors[i]] = 0;
                userclaimround[investors[i]] = 0;
                UserTier[investors[i]] = 0;
            }
        }

        address[] memory whitelistaddress1 = whitelistaddressesTier1;
        for (uint256 i = 0; i < whitelistaddress1.length; i++) {
            if (existinguser[whitelistaddress1[i]] == true) {
                existinguser[whitelistaddress1[i]] = false;
                userinvested[whitelistaddress1[i]] = 0;
                userremaininigClaim[whitelistaddress1[i]] = 0;
                userclaimround[whitelistaddress1[i]] = 0;
                UserTier[whitelistaddress1[i]] = 0;
            }
        }

        address[] memory whitelistaddress2 = whitelistaddressesTier2;
        for (uint256 i = 0; i < whitelistaddress2.length; i++) {
            if (existinguser[whitelistaddress2[i]] == true) {
                existinguser[whitelistaddress2[i]] = false;
                userinvested[whitelistaddress2[i]] = 0;
                userremaininigClaim[whitelistaddress2[i]] = 0;
                userclaimround[whitelistaddress2[i]] = 0;
                UserTier[whitelistaddress2[i]] = 0;
            }
        }

        require(
            IBEP20(outputtoken).balanceOf(address(this)) <= 0,
            "Ico is not empty"
        );
        totalsupply = 0;
        icoTarget = 0;
        receivedFund = 0;
        Tier1maxInvestment = 0;
        Tier2maxInvestment = 0;
        outputtoken = 0x0000000000000000000000000000000000000000;
        tokenPrice = 0;
        claimenabled = false;
        investingenabled = false;
        tierInitialized = false;
        icoindex = 0;
        round = 0;
        delete whitelistaddressesTier1;
        delete whitelistaddressesTier2;
        delete investors;
    }

    function initializeICO(address _outputtoken, uint256 _tokenprice)
        public
        onlyOwner
    {
        require(_tokenprice > 0, "Token price must be greater than 0");
        outputtoken = _outputtoken;
        tokenPrice = _tokenprice;
        require(
            IBEP20(outputtoken).balanceOf(address(this)) > 0,
            "Please first give Tokens to ICO"
        );
        require(
            IBEP20(outputtoken).decimals() == 18,
            "Only 18 decimal output token allowed"
        );
        totalsupply = IBEP20(outputtoken).balanceOf(address(this));
        icoTarget = ((totalsupply / _tokenprice) * 1000);
    }
    
    function getInvestorsCount() external view returns (uint256) {
        return investors.length;
    }

    function updateFundWallet(address _updateFundWallet) external onlyOwner {
        require(_updateFundWallet!=address(0),"null address");
        fundWallet = _updateFundWallet;
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = newOwner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);

    }


 

}
