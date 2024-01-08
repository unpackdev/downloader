// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IWETH.sol";
import "./OneInchAgregator.sol";
import "./IDynaset.sol";

contract DynasetForge is AccessControl {
    using SafeMath for uint256;
  
    // uses the default admin role
    bytes32 constant public CONTROLLER_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 constant public BLACK_SMITH = keccak256(abi.encode("BLACK_SMITH"));


    address constant AGGREGATION_ROUTER_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d; //https://etherscan.io/address/0x1111111254fb6c44bAC0beD2854e76F90643097d

    // withdraw fees
    uint256 public OPERATING_FEE = 100; // 1% fees
    uint256 public constant WITHDRAW_FEE_MAX = 1000; // 10% fees max
    uint256 public constant WITHDRAW_FEE_FACTOR = 10000;
    uint256 public total_fee;

    mapping(address => uint256) public ethBalanceOf;
    mapping(address => uint256) public outputBalanceOf;

    uint256 public cap;
    // contribution
    uint256 public minContribution;
    uint256 public maxContribution;

    bool withdraw_enabled = false;
    bool deposit_enabled = false;

    IERC20 public Dynaset;

    OneInchAgregator constant OneInch = OneInchAgregator(
        0x1111111254fb6c44bAC0beD2854e76F90643097d
    );

    IWETH public constant WETH = IWETH(
       0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2    //rinkkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15 //main 
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
        address _dynaset
    ) public {
        _setupRole(BLACK_SMITH, _blacksmith);
        Dynaset = IERC20(_dynaset);
    }

    modifier onlyRole(bytes32 _role) {
        require(hasRole(_role, msg.sender), "AUTH_FAILED");
        _;
    }

    // Initialisation contribution
    function initializeContribution(uint256 _min, uint256 _max) external onlyRole(BLACK_SMITH)
    {
        minContribution = _min;
        maxContribution = _max;

        emit Initialised(_min,_max);
    }

    function getUserContribution(address user) external view returns (uint256){
        return ethBalanceOf[user];
    }

    function getForgeBalance () external view returns(uint256)  {
       return  WETH.balanceOf(address(this));
    }

    function getUserEthBalance () external view returns(uint256) {
        return ethBalanceOf[msg.sender];
    }
    
    function getUserTokensBalance () external view returns(uint256) {
        return outputBalanceOf[msg.sender];
    }

    function Approve(address dest,address token,uint256 amount) external onlyRole(BLACK_SMITH) {
      IERC20(token).approve(dest, amount);
    }
    

    // _maxprice should be equal to the sum of _receivers.
    // this variable is needed because in the time between calling this function
    // and execution, the _receiver amounts can differ.
    function forge(
        address[] calldata _receivers,//users for witch you will mint tokens
        address _dynaset,
        uint256 _outputAmount,//expected amount to be minted in the dynaset
        uint256 _maxPrice,//maximum eth contributed by the receivers
        uint256 realPrice//get quote in weth value of all the underlying tokens corresponding to the _outputAmount expected from the dynaset
    ) external  onlyRole(BLACK_SMITH) {

        require(realPrice <= _maxPrice, "PRICE_ERROR");
        require(_receivers.length > 0, "RECEIVERS_NULL");

        uint256 totalInputAmount = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {

            uint256 userAmount = ethBalanceOf[_receivers[i]];
            if (totalInputAmount == realPrice) {
                break;
            } else if (totalInputAmount.add(userAmount) <= realPrice) {
                totalInputAmount = totalInputAmount.add(userAmount);
            } else {
                userAmount = realPrice.sub(totalInputAmount);
                // e.g. totalInputAmount = realPrice
                totalInputAmount = totalInputAmount.add(userAmount);
            }

            ethBalanceOf[_receivers[i]] = ethBalanceOf[_receivers[i]].sub(
                userAmount
            );

            uint256 userForgeAmount = _outputAmount.mul(userAmount).div(
                realPrice
            );
            outputBalanceOf[_receivers[i]] = outputBalanceOf[_receivers[i]].add(
                userForgeAmount
            );

            emit Forge(_receivers[i], userForgeAmount, userAmount);
        }
        // Provided balances are too low.
        require(totalInputAmount == realPrice, "INSUFFICIENT_FUNDS");

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
           // IERC20(token).approve(_dynaset, amount);
        }

        IDynaset dynaset = IDynaset(_dynaset);
        dynaset.joinDynaset(_dynasetAmount);
    }

    //swap tokens get quote amount from one inchapi for each underlying,  weth-> underlying 
    function _swapToToken(
        address _token,//weth
        uint256 _amount,//amount to send
        uint256 minReturn,
        bytes32[] calldata _data,//data from one inch
        address _dynaset // approve the dynaset for the swapped token
    ) external payable onlyRole(BLACK_SMITH) {  

        require(WETH.balanceOf(address(this)) >= _amount, "swap: not enough funds to swap");        
        WETH.approve(AGGREGATION_ROUTER_V4, _amount);
        OneInch.unoswap(_token,_amount,minReturn,_data);
    }

    //for test
    // function batchadd(address[] calldata _receivers,uint256[] calldata amounts) external onlyRole(BLACK_SMITH) {
    //      for (uint256 i = 0; i < _receivers.length; i++) {
    //       ethBalanceOf[_receivers[i]] = ethBalanceOf[_receivers[i]].add(amounts[i]);
    //     }
    // }

    function deposit() public payable  {  
       
        require(minContribution <= msg.value, "deposit: amount < min");

        uint256 total_contribution = ethBalanceOf[msg.sender].add(msg.value);

        require(total_contribution <= maxContribution, "deposit: amount > max");
        require(deposit_enabled, "deposit: not enabeled");
        require(address(this).balance <= cap, "MAX_CAP");
        //convert to weth the eth deposited to the contract
        
        //comment to run tests
        WETH.deposit{value: msg.value}();

        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].add(msg.value);
        
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();
    }

    function withdrawAll(address payable _receiver) external  {
        require(withdraw_enabled, "deposit: cooldown already enable");
        withdrawAllETH(_receiver);
        withdrawOutput(_receiver);
    }

    function withdrawAllETH(address payable _receiver) public  {
        require(withdraw_enabled , "deposit: cooldown already enable");
        withdrawETH(ethBalanceOf[msg.sender], _receiver);
    }

    function withdrawETH(uint256 _amount, address payable _receiver)
        public
    {
        require(withdraw_enabled, "withdraw: not enabled");
        require(ethBalanceOf[msg.sender] >= _amount, "user balance insufficient");

        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_amount);
        _receiver.transfer(_amount);
        emit WithdrawETH(msg.sender, _amount, _receiver);
    }

    function withdrawOutput(address _receiver) public  {
        require(withdraw_enabled, "withdraw: not enabled");

        // withdraw fee
        uint256 withdraw_fee = outputBalanceOf[msg.sender]
        .mul(WITHDRAW_FEE_FACTOR
        .sub(OPERATING_FEE))
        .div(WITHDRAW_FEE_FACTOR);

        uint256 final_fee = outputBalanceOf[msg.sender].sub(withdraw_fee);
        uint256 _amount = outputBalanceOf[msg.sender].sub(final_fee);

        require(Dynaset.balanceOf(address(this))>=_amount, "balance insufficient");

        //total_fee
        Dynaset.transfer(_receiver, _amount);

        total_fee = total_fee.add(final_fee);
        outputBalanceOf[msg.sender] = 0;
        emit WithdrawOuput(msg.sender, _amount, _receiver);

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
