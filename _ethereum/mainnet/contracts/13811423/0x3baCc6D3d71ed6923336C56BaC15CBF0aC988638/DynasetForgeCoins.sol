// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IWETH.sol";
import "./OneInchAgregator.sol";
import "./IDynaset.sol";

contract DynasetForgeCoins is AccessControl {
    using SafeMath for uint256;
    // uses the default admin role
    bytes32 constant public CONTROLLER_ROLE = DEFAULT_ADMIN_ROLE;

    bytes32 constant public BLACK_SMITH = keccak256(abi.encode("BLACK_SMITH"));

    mapping(address => uint256) public tokenBalanceOf;
    mapping(address => uint256) public outputBalanceOf;
    
    using SafeMath for uint256;

    bool isWithdrawActive = false;

    IERC20 public Dynaset;
    IERC20 public TokenContrib;
    uint256 public cap;

    // boolean to simulate cooldown
    bool withdraw_enabled = false;
    bool deposit_enabled = false;
    // contribution
    uint256 minContribution;
    uint256 maxContribution;

    // withdraw fee
    uint256 public OPERATING_FEE = 100; // 1% fees
    uint256 public constant WITHDRAW_FEE_MAX = 1000; // 10% fees max
    uint256 public constant WITHDRAW_FEE_FACTOR = 10000;
    uint256 public total_fee;

    address constant AGGREGATION_ROUTER_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;// https://etherscan.io/address/0x1111111254fb6c44bAC0beD2854e76F90643097d

    OneInchAgregator constant OneInch = OneInchAgregator(
        0x1111111254fb6c44bAC0beD2854e76F90643097d
    );



    event Deposit(address user, uint256 amount);
    event WithdrawETH(address user, uint256 amount, address receiver);
    event WithdrawOuput(address user, uint256 amount, address receiver);
    event Forge(address user, uint256 amount, uint256 price);
    event CapSet(uint256 max);
    event Initialised(uint256 min, uint256 max);
    event FeeSet(uint256 fee);
    event DepositSet(bool set);
    event WithdrawSet(bool set);

    constructor(
        address _blacksmith,
        address _dynaset,
        address _token
    ) public {
        _setupRole(BLACK_SMITH, _blacksmith);
        Dynaset = IERC20(_dynaset);
        TokenContrib  = IERC20(_token);
    }


    modifier onlyRole(bytes32 _role) {
        require(hasRole(_role, msg.sender), "AUTH_FAILED");
        _;
    }

    // Initialisation contribution
    function initializeContribution(uint256 _min, uint256 _max) external 
    onlyRole(BLACK_SMITH)
    {
        minContribution = _min;
        maxContribution = _max;

        emit Initialised(_min,_max);
    }

    function getUserContribution(address user) external view  returns (uint256){
        return tokenBalanceOf[user];
    }


    function getForgeBalance () external view  returns(uint256)  {
       return  TokenContrib.balanceOf(address(this));
    }

    function Approve(address dest,address token,uint256 amount) external onlyRole(BLACK_SMITH) {
      IERC20(token).approve(dest, amount);
    }


    // _maxprice should be equal to the sum of _receivers.
    // this variable is needed because in the time between calling this function
    // and execution, the _receiver amounts can differ.
    function forge(
        address[] calldata _receivers,
        address _dynaset,
        uint256 _outputAmount,
        uint256 _maxPrice,//maximum eth contributed by the receivers
        uint256 _realPrice
    ) external onlyRole(BLACK_SMITH) {

        require(_realPrice <= _maxPrice, "PRICE_ERROR");
        require(_receivers.length > 0, "RECEIVERS_NULL");

        uint256 totalInputAmount = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {

            uint256 userAmount = tokenBalanceOf[_receivers[i]];
            if (totalInputAmount == _realPrice) {
                break;
            } else if (totalInputAmount.add(userAmount) <= _realPrice) {
                totalInputAmount = totalInputAmount.add(userAmount);
            } else {
                userAmount = _realPrice.sub(totalInputAmount);
                // e.g. totalInputAmount = realPrice
                totalInputAmount = totalInputAmount.add(userAmount);
            }

            tokenBalanceOf[_receivers[i]] = tokenBalanceOf[_receivers[i]].sub(
                userAmount
            );

            uint256 userForgeAmount = _outputAmount.mul(userAmount).div(
                _realPrice
            );
            outputBalanceOf[_receivers[i]] = outputBalanceOf[_receivers[i]].add(
                userForgeAmount
            );

            emit Forge(_receivers[i], userForgeAmount, userAmount);
        }
        // Provided balances are too low.
        require(totalInputAmount == _realPrice, "INSUFFICIENT_FUNDS");
        _mintDynaset(_dynaset, _outputAmount);
    }

    function _mintDynaset(address _dynaset, uint256 _dynasetAmount) internal {
        (address[] memory tokens, uint256[] memory amounts) = IDynaset(_dynaset)
            .calcTokensForAmount(_dynasetAmount);

        //check if enough tokens for swap
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            IERC20 underlygin_token = IERC20(token);
            require (underlygin_token.balanceOf(address(this)) >= amount,"not enough tokens" );
            //IERC20(token).approve(_dynaset, amount);
        }

        IDynaset dynaset = IDynaset(_dynaset);
        dynaset.joinDynaset(_dynasetAmount);
    }

      //swap tokens get quote amount from oneinch api for each underlying,  weth-> underlying 
    function _swapToToken(
        address _token,//weth
        uint256 _amount,//amount to send
        uint256 minReturn,
        bytes32[] calldata _data,//data from one inch
        address _dynaset // approve the dynaset for the swapped token
    ) external payable onlyRole(BLACK_SMITH) {  

        require(IERC20(_token).balanceOf(address(this)) >= _amount, "swap: not enough funds to swap");
        IERC20(_token).approve(AGGREGATION_ROUTER_V4, _amount);
        OneInch.unoswap(_token,_amount,minReturn,_data);
  
    }


    function deposit(uint256 amount) external  {
        require(deposit_enabled, "deposit: not enabeled");
        require (TokenContrib.balanceOf(address(msg.sender)) >= amount,"not enough tokens");
        require(minContribution <= amount, "deposit: amount < min");
        uint256 contribution = tokenBalanceOf[msg.sender].add(amount);
        require(contribution <= maxContribution, "deposit: amount > max");
        require(TokenContrib.balanceOf(address(this)) <= cap, "MAX_CAP");

        TokenContrib.transferFrom(msg.sender,address(this),amount);
        tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(amount);

        emit Deposit(msg.sender, amount);
    }


    function withdrawAll(address payable _receiver) external {
        withdrawOutput(_receiver);
    }


    function withdrawToken(uint256 _amount, address _receiver)
        external
    {
        require(withdraw_enabled, "withdraw: not enabled");
        require(tokenBalanceOf[msg.sender] >=_amount, "balance insufficient");

        tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].sub(_amount);
        TokenContrib.transfer(_receiver,_amount);
        emit WithdrawETH(msg.sender, _amount, _receiver);
    }

    function withdrawOutput(address _receiver) public {
        require(withdraw_enabled, "withdraw: not enabled");

        // withdraw fee
        uint256 withdraw_fee = outputBalanceOf[msg.sender]
        .mul(WITHDRAW_FEE_FACTOR
        .sub(OPERATING_FEE))
        .div(WITHDRAW_FEE_FACTOR);

        uint256 final_fee = outputBalanceOf[msg.sender].sub(withdraw_fee);

        uint256 _amount = outputBalanceOf[msg.sender].sub(final_fee);
        require(Dynaset.balanceOf(address(this))>=_amount, "balance insufficient");

        Dynaset.transfer(_receiver, _amount);
        total_fee = total_fee.add(final_fee);
        outputBalanceOf[msg.sender] = 0;
    }

    function setCap(uint256 _cap) external onlyRole(BLACK_SMITH) {
        cap = _cap;

        emit CapSet(_cap);
    }

    function getCap() external view returns (uint256) {
        return cap;
    }

    function setWithdraw(bool _enable) external onlyRole(BLACK_SMITH)
    {
        withdraw_enabled = _enable;
        emit WithdrawSet(_enable);
    }

    function setDeposit(bool _enable) external onlyRole(BLACK_SMITH)
    {
        deposit_enabled = _enable;
         emit DepositSet(_enable);
    }

    function withdrawFee() external onlyRole(BLACK_SMITH) {
        require(Dynaset.balanceOf(address(this))>=total_fee, "balance insufficient");
        Dynaset.transfer(msg.sender, total_fee); 
        total_fee = 0;
    }

    function withdrawAnyTokens(address token,uint256 amount) external onlyRole(BLACK_SMITH) {
        IERC20 Token = IERC20(token);
        require(Token.balanceOf(address(this))>=amount, "balance insufficient");
        Token.transfer(msg.sender, amount); 
    }

    function withdrawEth(uint256 amount) external onlyRole(BLACK_SMITH) {
        require(address(this).balance >=amount, "balance insufficient");
        msg.sender.transfer(amount); 
    }

    function setFee(uint _feeAmount) external onlyRole(BLACK_SMITH) {
        require(WITHDRAW_FEE_MAX > _feeAmount , "setFee: FEE must be inferior of 10%");
        OPERATING_FEE = _feeAmount;

        emit FeeSet(_feeAmount);
    }
}
