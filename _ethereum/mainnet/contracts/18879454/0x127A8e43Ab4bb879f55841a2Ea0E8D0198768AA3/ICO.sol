// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./DriftPresale.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

contract ICO is Ownable {
    DriftPresale public tokenAddress;
     AggregatorV3Interface internal priceFeed;

    enum Tier {
        none,
        gold,
        silver,
        bronze
    }

    enum userType {
        dynamic,
        stake
    }

    struct AmbassadorInfo {
        address ambassadorAddress;
        string ambassadorCode;
        Tier userTier;
        uint256 earning;
        uint256 referrals;
        uint256 amountRaised;
    }
    
    address[] public ambassadorsList; //Ambassador Array
    uint256 public totalReceivedFunds;
    uint256 public icoStartTime;
    uint256 public limitPerUser;
    
    uint256 public icoStage;
    uint256 public eligibleSilverAmbassador = 0.5 ether;
    uint256 public eligibleBronzeAmbassador = 0.25 ether;
    uint256 public noOfAmbassadors;
    uint256 public AmbassadorPayout;
    uint256 public stakingLimit;
    // uint256 public minimumBuyLimit = ;
    bool public isSalePaused = false;

    // Mapping (Stage => Price)
    mapping(uint256 => uint256) public prices;
    // Mapping (Stage => ETH target)
    mapping(uint256 => uint256) public icoTarget;
    mapping(uint256 => uint256) public tokensTransferred;
    mapping(uint256 => uint256) public receivedFunds;
    mapping(userType => uint256) public noOfTokens;
    // Decimals 2
    mapping(Tier => uint32[]) public percent;
    mapping(userType => address[]) private users;
    mapping(address => mapping(userType => bool)) public isAddressExist;
    mapping(address => mapping(userType => uint256))
        public amountOfAddressPerType;
    // Is code is enabled/valid
    mapping(string => bool) public isEnableCode;
    // Generated promo code against address
    mapping(address => string) public codeOfAddress;
    // Generated promo code
    mapping(string => address) public promoCode;
    // How much money the address invest
    mapping(address => AmbassadorInfo) internal ambassadorInfo;
    // Mapping Stage => Tier => Amount
    mapping(uint256 => mapping(Tier => uint256)) public totalTierRaised;
    mapping(Tier => mapping(string => bool)) public ambassadorCode;
    // How much money the address invest
    mapping(address => uint256) public investAmount;
    mapping(address => bool) public isAmbassadorEligible;
    mapping(address => uint256) public ambassadorPercentExt;

    modifier isCodeValid(string memory _code) {
        require(
            isEnableCode[_code] || compareStringsbyBytes(_code, ""),
            "Code is invalid"
        );
        _;
    }

    modifier isUsingOwnCode(string memory _code) {
        require(promoCode[_code] != msg.sender, "Can't use your own code");
        _;
    }


    // Is crowdsale Open
    function changeSaleStatus(bool _status) public onlyOwner  {
       isSalePaused=_status;
    }
    // bool public isSalePaused;

    constructor(DriftPresale _tokenAddress) {
        tokenAddress = _tokenAddress;
    priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        percent[Tier.gold] = [1000, 500];
        percent[Tier.silver] = [1000, 500];
        percent[Tier.bronze] = [750, 500];
        stakingLimit = 2000000000 * 10**tokenAddress.decimals();
        limitPerUser = 150000000 * 10**tokenAddress.decimals();
    }

    // Is crowdsale Open
    function isOpen() public view returns (bool) {
        return icoTarget[icoStage] > tokensTransferred[icoStage] && block.timestamp >= icoStartTime;
    }

    function updateStakingLimit(uint256 _newLimit) public onlyOwner {
        stakingLimit = _newLimit;
    }

    // Percentage with multiplied by 100, eg. 10% => 10*100 = 1000
    function updateAmbassadorPercent(address _address, uint256 _percent) public onlyOwner {
        ambassadorPercentExt[_address] = _percent;
    }

    // Create new crowdsale stage
    function createStage(
        uint256 _price,
        uint256 _startTime,

        uint256 _target
    ) public onlyOwner {
        require(!isOpen(), "Previous ICO is open");
        require(_price > 0, "Price is zero");
        require(_startTime > block.timestamp, "Invalid Time");
        icoStartTime = _startTime;        
        icoStage += 1;
        prices[icoStage] = _price;
        icoTarget[icoStage] = _target;
    }

    function calculateTokens(uint256 _amount) internal view returns (uint256) {
        uint256 tokens = ((_amount * 10**18) / getPriceRate(prices[icoStage]));
        return tokens;
    }

//Conversion Rate
        function getPriceRate(uint _amount) public view returns (uint) {
        (, int price,,,) = priceFeed.latestRoundData();
        uint adjust_price = uint(price) * 1e10;
        uint usd = _amount ;
        uint rate = (usd * 1e18) / adjust_price;
        return rate;
    }


    // Buy tokens
    function buyTokens(string memory _code, bool _isStaker)
        public
        payable
        isCodeValid(_code)
        isUsingOwnCode(_code)
    {
        require(!isSalePaused,"Sale is Paused");
        require(msg.value >= getPriceRate(50000000000000000000), "Minimum Buy Limit is USD $50.00");
        require(tokenAddress.balanceOf(_msgSender()) <= limitPerUser, "Sorry! Looks like this wallet has reached Max. Purchase Limit per address. As per our Presale Rules, a single wallet cannot purchase more than 1.5% of total supply.");
        require(isOpen(), "Current stage of Presale has been filled completely. Please stay tuned for the next lap.");
        
        

        uint256 tokens = calculateTokens(msg.value);

        if (!compareStringsbyBytes(_code, "")) {
            Tier tier;
            if (ambassadorCode[Tier.gold][_code]) {
                tier = Tier.gold;
            } else if (ambassadorCode[Tier.silver][_code]) {
                tier = Tier.silver;
            } else if (ambassadorCode[Tier.bronze][_code]) {
                tier = Tier.bronze;
            }

            uint256 extraToken = (tokens * percent[tier][1]) / 10**4;
            tokens += extraToken;
            
            AmbassadorInfo storage _ambassadorInfoCode = ambassadorInfo[
                promoCode[_code]
            ];

            uint256 ambassadorPer = ambassadorPercentExt[_ambassadorInfoCode.ambassadorAddress] != 0 ? ambassadorPercentExt[_ambassadorInfoCode.ambassadorAddress] : percent[tier][0];

            uint256 ambassadorAmount = (msg.value * ambassadorPer) / 10**4;
            totalTierRaised[icoStage][tier] += msg.value;

            _ambassadorInfoCode.amountRaised += msg.value;
            _ambassadorInfoCode.referrals += 1;
            _ambassadorInfoCode.earning += ambassadorAmount;
            AmbassadorPayout += ambassadorAmount;

            (bool sentToAmbassador, ) = payable(promoCode[_code]).call{
                value: ambassadorAmount
            }("");

            require(sentToAmbassador, "Sent to ambassador failed");
        }

        bool success = tokenAddress.transferFrom(
            tokenAddress.owner(),
            _msgSender(),
            tokens
        );
        require(success, "Transfer failed");

        tokensTransferred[icoStage]+=tokens;

        userType _type = _isStaker ? userType.stake : userType.dynamic;

        require(
            (_type == userType.stake &&
                noOfTokens[userType.stake] < stakingLimit) ||
                _type == userType.dynamic,
            "Staking Pool Full. A max. 20% of entire supply can be staked during Presale stage. "
        );

        if (!isAddressExist[_msgSender()][_type]) {
            isAddressExist[_msgSender()][_type] = true;
            users[_type].push(_msgSender());
        }

        amountOfAddressPerType[_msgSender()][_type] += tokens;
        noOfTokens[_type] += tokens;

        receivedFunds[icoStage] += msg.value;
        totalReceivedFunds += msg.value;
        investAmount[_msgSender()] += msg.value;
        

        Tier _eligible = Tier.none;

        if (investAmount[_msgSender()] >= eligibleSilverAmbassador) {
            _eligible = Tier.silver;
        } else if (investAmount[_msgSender()] >= eligibleBronzeAmbassador) {
            _eligible = Tier.bronze;
        }

        AmbassadorInfo storage _ambassadorInfo = ambassadorInfo[_msgSender()];
        if (!isAmbassadorEligible[_msgSender()] && _eligible != Tier.none) {
            
            _ambassadorInfo.userTier = _eligible;
            _ambassadorInfo.ambassadorAddress = _msgSender();

            isAmbassadorEligible[_msgSender()] = true;
            noOfAmbassadors++;
        } else if (_ambassadorInfo.userTier == Tier.bronze) {
            string memory _codeOfAddress = codeOfAddress[_msgSender()];
            delete ambassadorCode[Tier.bronze][_codeOfAddress];
            _ambassadorInfo.userTier = _eligible;
            ambassadorCode[_eligible][_codeOfAddress] = true;
        }
    }

    function getAmbassadorInfo(address _address)
        public
        view
        returns (
            Tier _tier,
            string memory _promocode,
            address _ambassador,
            uint256 _earnings,
            uint256 _referrals,
            uint256 _raised
        )
    {
        AmbassadorInfo memory _ambassadorInfo = ambassadorInfo[_address];
        return (
            _ambassadorInfo.userTier,
            _ambassadorInfo.ambassadorCode,
            _ambassadorInfo.ambassadorAddress,
            _ambassadorInfo.earning,
            _ambassadorInfo.referrals,
            _ambassadorInfo.amountRaised
        );
    }

    function changeStatusCode(string memory _code, bool status)
        public
        onlyOwner
    {
        isEnableCode[_code] = status;
    }

    function createAmbassadorCode(
        address _address,
        Tier _tier,
        string memory _code
    ) public onlyOwner {
        require(isNotAlreadyAmbassador(_address), "Already Ambasador");
        ambassadorsList.push(_address);
        require(!isEnableCode[_code], "Code already exist");
        isAmbassadorEligible[_address] = true;
        isEnableCode[_code] = true;
        codeOfAddress[_address] = _code;
        promoCode[_code] = _address;
        ambassadorCode[_tier][_code] = true;
        AmbassadorInfo storage _ambassadorInfo = ambassadorInfo[_address];
        _ambassadorInfo.ambassadorAddress = _address;
        _ambassadorInfo.ambassadorCode = _code;
        _ambassadorInfo.userTier = _tier;
        noOfAmbassadors++;
    }

    function createCode(string memory _code) public {
        require(isAmbassadorEligible[_msgSender()], "Sorry! You are not an ambassador yet. Please visit www.drifttoken.io during Presale and purchase a minimum of 0.25 ETH to become a Bronze Tier Ambassador. ");
        require(isNotAlreadyAmbassador(_msgSender()), "You have already assigned a Promo Code to this Ambassador Wallet. Please visit www.influ3nce.me/ambassador and connect this wallet to view your promo code. ");
        require(!compareStringsbyBytes(_code, ""), "Oops! Seems like you forgot to type-in your Promo Code.");
        require(!isEnableCode[_code], "Unfortunately, this Promo Code has already been assigned to an Ambassador. Please choose another Promo Code. ");
        ambassadorsList.push(_msgSender());
        isEnableCode[_code] = true;
        codeOfAddress[_msgSender()] = _code;
        promoCode[_code] = _msgSender();
        AmbassadorInfo storage _ambassadorInfo = ambassadorInfo[_msgSender()];
        ambassadorCode[_ambassadorInfo.userTier][_code] = true;
        _ambassadorInfo.ambassadorCode = _code;
    }

    function upgradeAmbassador(address _address, Tier _tier) public onlyOwner {
        AmbassadorInfo storage _ambassadorInfo = ambassadorInfo[_address];
        delete ambassadorCode[_ambassadorInfo.userTier][
            codeOfAddress[_address]
        ];
        ambassadorCode[_tier][codeOfAddress[_address]] = true;
        _ambassadorInfo.userTier = _tier;

  
    }

    function isNotAlreadyAmbassador(address user) public view returns (bool) {
        return compareStringsbyBytes(codeOfAddress[user], "");
    }

    function getUsers(userType _type) public view returns (address[] memory) {
        return users[_type];
    }

    function getAmbassadorList() public view returns (address[] memory) {
        return ambassadorsList;
    }

    function withdrawFunds() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function compareStringsbyBytes(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
