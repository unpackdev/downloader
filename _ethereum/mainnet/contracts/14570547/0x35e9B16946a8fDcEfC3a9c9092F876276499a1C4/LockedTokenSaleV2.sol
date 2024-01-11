// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IPancakeRouter.sol";
import "./ITokenVesting.sol";


contract LockedTokenSaleV2 is Ownable {

    ITokenVesting public tokenVesting;
    IPancakeRouter01 public router;
    AggregatorInterface public ref;
    address public token;

    uint constant lock_period1 = 121;
    uint constant lock_period2 = 242;

    uint constant lock_period1_without_referrer = 182;
    uint constant lock_period2_without_referrer = 365;

    uint constant plan1_price_limit = 1.25 * 1e18; // ie18 1.25
    uint constant plan2_price_limit = 1 * 1e18; // ie18 1

    uint[] lockedTokenPrice;

    uint public referral_ratio = 30; //30 %

    uint public eth_collected;
    uint public eth_referral;

    struct AccountantInfo {
        address accountant;
        address withdrawal_address;
    }

    AccountantInfo[] accountantInfo;
    mapping(address => address) withdrawalAddress;

    uint min_withdrawal_amount;

    address[] referrers;
    mapping(uint => bool) referrer_status;
    mapping(address => uint) referrer_to_ids;

    event Buy_Locked_Tokens(address indexed account, uint plan, uint amount, uint referral_id);
    event Set_Accountant(AccountantInfo[] info);
    event Set_Min_Withdrawal_Amount(uint amount);
    event Set_Referral_Ratio(uint ratio);
    event Add_Referrers(address[] referrers);
    event Delete_Referrers(uint[] referrer_ids);

    modifier onlyAccountant() {
        address withdraw_address = withdrawalAddress[msg.sender];
        require(withdraw_address != address(0x0), "Only Accountant can perform this operation");
        _;
    }

    constructor(address _router, address _tokenVesting, address _ref, address _token) {
        router = IPancakeRouter01(_router); // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        tokenVesting = ITokenVesting(_tokenVesting); // 0x63570e161Cb15Bb1A0a392c768D77096Bb6fF88C 0xDB83E3dDB0Fa0cA26e7D8730EE2EbBCB3438527E
        ref = AggregatorInterface(_ref); // 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526 bscTestnet
        token = _token; //0x5Ca372019D65f49cBe7cfaad0bAA451DF613ab96
        lockedTokenPrice.push(0);
        lockedTokenPrice.push(plan1_price_limit); // plan1
        lockedTokenPrice.push(plan2_price_limit); // plan2
        IERC20(_token).approve(_tokenVesting, 1e25);
        _add_referrer(address(this));
    }

    function balanceOfToken() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getUnlockedTokenPrice() public view returns (uint) {
        address pair = IPancakeFactory(router.factory()).getPair(token, router.WETH());
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(pair).getReserves();
        uint pancake_price;
        if( IPancakePair(pair).token0() == token ){
            pancake_price = reserve1 * (10 ** IERC20(token).decimals()) / reserve0;
        }
        else {
            pancake_price = reserve0 * (10 ** IERC20(token).decimals()) / reserve1;
        }
        return pancake_price;
    }

    function setLockedTokenPrice(uint plan, uint price) public onlyOwner{
        if(plan == 1)
            require(plan1_price_limit <= price, "Price should not below the limit");
        if(plan == 2)
            require(plan2_price_limit <= price, "Price should not below the limit");
        lockedTokenPrice[plan] = price;
    }

    function getLockedTokenPrice(uint plan) public view returns (uint){
        return lockedTokenPrice[plan] * 1e8 / ref.latestAnswer();
    }

    function buyLockedTokens(uint plan, uint amount, uint referral_id) public payable{

        require(amount >= 100, "You should buy at least 100 locked token");
        bool is_valid_referrer = referral_id > 0 && referrer_status[referral_id] == true;
        address referrer = referrers[referral_id];

        uint price = getLockedTokenPrice(plan);
        
        uint amount_eth = amount * price;
        uint referral_value = amount_eth * referral_ratio / 100;

        require(amount_eth <= msg.value, 'Insufficient msg.value');
        if(is_valid_referrer && referrer != msg.sender) {
            payable(referrer).transfer(referral_value);
            eth_referral += referral_value;
        }
        
        require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient token in the contract");
        uint256 lockdays;
        if(plan == 1)
        {    
            if(is_valid_referrer)
                lockdays = lock_period1;
            else
                lockdays = lock_period1_without_referrer;
        } else {
            if(is_valid_referrer)
                lockdays = lock_period2;
            else
                lockdays = lock_period2_without_referrer;
        }
        uint256 endEmission = block.timestamp + 1 days * lockdays;
        _lock_wjxn(msg.sender, amount, endEmission);

        if(amount_eth < msg.value) {
            payable(msg.sender).transfer(msg.value - amount_eth);
        }

        eth_collected += amount_eth;
    }

    function _lock_wjxn(address owner, uint amount, uint endEmission) internal {
        ITokenVesting.LockParams[] memory lockParams = new ITokenVesting.LockParams[](1);
        ITokenVesting.LockParams memory lockParam;
        lockParam.owner = payable(owner);
        lockParam.amount = amount;
        lockParam.startEmission = 0;
        lockParam.endEmission = endEmission;
        lockParam.condition = address(0);
        lockParams[0] = lockParam;
        tokenVesting.lock(token, lockParams);
    }

    function setReferralRatio(uint ratio) external onlyOwner {
        require(ratio >= 10 && ratio <= 50, "Referral ratio should be 10% ~ 50%");
        referral_ratio = ratio;
        emit Set_Referral_Ratio(ratio);
    }

    function setMinWithdrawalAmount(uint amount) external onlyOwner {
        min_withdrawal_amount = amount;
        emit Set_Min_Withdrawal_Amount(amount);
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyAccountant {
        require(amount >= min_withdrawal_amount, "Below minimum withdrawal amount");
        payable(withdrawalAddress[msg.sender]).transfer(amount);
    }

    function setAccountant(AccountantInfo[] calldata _accountantInfo) external onlyOwner {
        uint length = accountantInfo.length;
        for(uint i; i < length; i++) {
            withdrawalAddress[accountantInfo[i].accountant] = address(0x0);
        }
        delete accountantInfo;
        length = _accountantInfo.length;
        for(uint i; i < length; i++) {
            accountantInfo.push(_accountantInfo[i]);
            withdrawalAddress[_accountantInfo[i].accountant] = _accountantInfo[i].withdrawal_address;
        }
        emit Set_Accountant(_accountantInfo);
    }

    function add_referrers(address[] memory _referrers) external onlyOwner {
        uint i = 0;
        for(; i < _referrers.length; i += 1) {
            _add_referrer(_referrers[i]);
        }
        emit Add_Referrers(_referrers);
    }

    function delete_referrers(uint[] memory _referrer_ids) external onlyOwner {
        uint i = 0;
        for(; i < _referrer_ids.length; i += 1) {
            referrer_status[_referrer_ids[i]] = false;
        }
        emit Delete_Referrers(_referrer_ids);
    }

    function get_referrer_status(uint id) external view returns(bool) {
        require(id < referrers.length, "Invalid referrer id");
        return referrer_status[id];
    }

    function get_referrer(uint id) external view returns(address) {
        require(id < referrers.length, "Invalid referrer id");
        return referrers[id];
    }

    function get_referrers() external view returns(address[] memory) {
        return referrers;
    }

    function get_referrer_id(address referrer) external view returns(uint) {
        return referrer_to_ids[referrer];
    }

    function _add_referrer(address referrer) internal {
        uint referrer_id = referrer_to_ids[referrer];
        if( referrer_id == 0) {
            referrer_id = referrers.length;
            referrers.push(referrer);
            referrer_to_ids[referrer] = referrer_id;
        }
        referrer_status[referrer_id] = true;
    }
}

interface AggregatorInterface{
    function latestAnswer() external view returns (uint256);
}