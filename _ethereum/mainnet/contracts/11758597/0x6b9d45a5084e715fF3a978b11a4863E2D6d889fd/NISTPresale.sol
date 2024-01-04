//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;

// import "./console.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Router.sol";

interface INISTToken is IERC20
{
    function transferOwnership(address newOwner) external;
    function unpause() external;
    function initializeTwap() external;
}

contract NistPresaleContract is Ownable {
  using SafeMath for uint256;

  IERC20 public LamboToken;
  INISTToken public NistToken;
  uint256 public TokenDecimals;

  mapping(address => uint256) public investments; // total WEI invested per address (1ETH = 1e18WEI)
  mapping (uint256=> address) public investors;   // list of participating investor addresses
  uint256 private _investorCount = 0;             // number of unique addresses that have invested

  uint256 public INVESTMENT_LIMIT_PRESALE   = 0.5 ether; 
  uint256 public constant INVESTMENT_RATIO_PRESALE   = 0.5 ether; // pre-sale rate is 0.5 ETH/Nist
  uint256 public constant PRESALE_ETH_HARDCAP = 50 ether;
  uint256 public PRESALE_ETH_CURRENT = 0 ether;
  uint256 public listingPriceTokensPerETH = 2;

  bool public isPresaleActive  = false; // during activation, only Lambo is accepted for investment
  bool public isAcceptingEth = false; // when true, contact will accept ETH
  bool internal testing = false;
  IUniswapV2Router router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  constructor()
    public
  {
    TokenDecimals = 18;
  }

  function toggleTesting() external onlyOwner {
    testing = !testing;
  }

  function setTokenAddresses(address LamboTokenAddress, address NistTokenAddress)
    public
    onlyOwner
  {
    LamboToken = IERC20(LamboTokenAddress);
    NistToken = INISTToken(NistTokenAddress);
  }

  function startPresalePhase1() public onlyOwner {
    isPresaleActive = true;
  }

  function startPresalePhase2() public onlyOwner {
    isAcceptingEth = true;
  }

  function removePresaleEthLimits() public onlyOwner {
    INVESTMENT_LIMIT_PRESALE = 1000 ether;
  }

  function endPresale() public onlyOwner {
    isPresaleActive = false;
    isAcceptingEth = false;
    payable(owner()).transfer(address(this).balance);
    LamboToken.transfer(owner(), LamboToken.balanceOf(address(this)));
    NistToken.transfer(owner(), NistToken.balanceOf(address(this)));
  }

  function investLamboForNist(uint256 amount) presaleActive hasApprovedLamboTransfer public {
    uint approvedTokenAmount = LamboToken.allowance(msg.sender, address(this));
//    console.log("approve amount", approvedTokenAmount);
//    console.log("amount to transfer", amount);
    require(approvedTokenAmount >= amount, "Not enough Lambo approved for transfer");
    require(LamboToken.transferFrom(msg.sender, address(this), amount));
    NistToken.transfer(msg.sender, amount);
  }

  function refundInvestors() external onlyOwner {
    for (uint256 i = 0; i < _investorCount; i++) {
      address addressToRefund = investors[i];
      uint256 refundAmount = investments[investors[i]];

//      console.log("addressToRefund: '%s'", addressToRefund);
//      console.log("refundAmount: '%s'", refundAmount);

      payable(addressToRefund).transfer(refundAmount);
      investments[investors[i]].sub(refundAmount);
    }
  }

  modifier hasApprovedLamboTransfer() {
    require(LamboToken.allowance(msg.sender, address(this)) > 0, "Lambo token not approved for transfer");
    _;
  }

  modifier hardcapLimited() {
    require(PRESALE_ETH_CURRENT < PRESALE_ETH_HARDCAP, "Presale hardcap reached");
    _;
  }

  modifier acceptingEth() {
    require(isAcceptingEth, "Presale is currently only accepting Lambo tokens");
    _;
  }

  modifier presaleActive() {
    require(isPresaleActive, "Presale is currently not active.");
    _;
  }

  receive()
    external
    payable
  {
    if(msg.sender != address(router)){
      uint256 addressTotalInvestment = investments[_msgSender()].add(msg.value);
      if(!testing) _receivePublic(_msgSender(),addressTotalInvestment,msg.value);
      //Use presale code without checking most checks that is done on public sale
      _receiveInternal(_msgSender(),addressTotalInvestment,true,msg.value);
    }
  }

  function _receivePublic(address addr,uint256 _addressTotalInvestment,uint256 _value) internal
    presaleActive
    acceptingEth
    hardcapLimited
    {
      _receiveInternal(addr,_addressTotalInvestment,false,_value);
    }

  function  _receiveInternal(address sender,uint256 addressTotalInvestment,bool bypassLimit,uint256 value) internal {
    if(!bypassLimit)
      require(addressTotalInvestment <= INVESTMENT_LIMIT_PRESALE, "Max investment per pre-sale address is 0.5 ETH.");
    require(PRESALE_ETH_CURRENT.add(value) <= PRESALE_ETH_HARDCAP, "Presale hardcap reached");
    PRESALE_ETH_CURRENT = PRESALE_ETH_CURRENT.add(value);

    uint256 amountOfTokens;

    amountOfTokens = value.mul(10 ** TokenDecimals).div(INVESTMENT_RATIO_PRESALE);

    NistToken.transfer(sender, amountOfTokens);

    investors[_investorCount] = sender;
    _investorCount++;

    investments[sender] = addressTotalInvestment;
  }

  function addLiq() external onlyOwner {
    uint256 lamboTokenBal = LamboToken.balanceOf(address(this));
    if( lamboTokenBal > 0){
      LamboToken.approve(address(router),lamboTokenBal);
      address[] memory lambotoeth = new address[](2);
      lambotoeth[0] = address(LamboToken);
      lambotoeth[1] = router.WETH();
      router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        lamboTokenBal,
        0,
        lambotoeth,
        address(this),
        block.timestamp
      );
    }
    uint256 ETH = address(this).balance;
    uint256 tokensForUniswap = ETH.mul(listingPriceTokensPerETH);
    uint256 tokensExcess = NistToken.balanceOf(address(this)).sub(tokensForUniswap);

    // NistToken.initPair();
    NistToken.approve(address(router), tokensForUniswap);
    router.addLiquidityETH
    { value: ETH }
    (
      address(NistToken),
      tokensForUniswap,
      tokensForUniswap,
      ETH,
      address(NistToken),
      block.timestamp
    );
    //Init twap
    NistToken.initializeTwap();
    NistToken.unpause();

    //Send what remains to owner
    if (tokensExcess > 0){
          NistToken.transfer(owner(),tokensExcess);
    }
    //Transfer ownership to deployer
    NistToken.transferOwnership(owner());
  }

  function getInvestedAmount(address adr) public view returns (uint256){
      return investments[adr];
  }

  function getInvestorCount() public view returns (uint256){
    return _investorCount;
  }

}