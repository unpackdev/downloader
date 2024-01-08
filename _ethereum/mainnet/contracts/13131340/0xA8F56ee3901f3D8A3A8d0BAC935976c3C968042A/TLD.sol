// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC20Changeable.sol";

contract TLD is ERC20Changeable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  
  address private _owner;
  uint256 private AVERAGE_LENGTH;
  uint256 private MINT_UNIT = 1;
  uint256 private gasUnitsHistory;
  uint256 private gasPriceHistory;
  uint256 private MINTED_ETH = 0;
  uint256 private MINTED_TLD = 0;
  uint256 private MINTED_CONSTANT = 0;
  uint256 private REIMBURSEMENT_TX_GAS_HISTORY;
  uint256 private DEFAULT_REIMBURSEMENT_TX_GAS = 90000;
  uint256 private BASE_PRICE_MULTIPLIER = 3;
  uint256 private _basePrice;
  
  Counters.Counter private _reservedIds;
  mapping(uint256=>uint256) reservedPrice;
  
  event Skimmed(address destinationAddress, uint256 amount);
  constructor() ERC20Changeable("Domain Name Community Token", ".TLD") {
    _owner = msg.sender;
  }

  function changeSymbol(string memory symbol_) public onlyOwner{
    _symbol = symbol_;
  }
  function changeName(string memory name_) public onlyOwner{
    _name = name_;
  }
  
  function init(uint256 initialGasEstimation, uint256 averageLength, uint256 basePriceMultiplier) public payable onlyOwner returns(uint256){
    if(MINTED_CONSTANT != 0){
      revert("Already initialized");
    }
    AVERAGE_LENGTH = averageLength;
    BASE_PRICE_MULTIPLIER = basePriceMultiplier;
    trackGasReimburses(initialGasEstimation);
    trackGasPrice(tx.gasprice.add(1));
    uint256 toMint = msg.value.mul(unit()).div(basePrice());
    MINTED_ETH = msg.value;
    MINTED_TLD = toMint;
    MINTED_CONSTANT = MINTED_ETH.mul(MINTED_TLD);
    _mint(msg.sender, toMint);
    return toMint;
  }
  function setBasePriceMultiplier(uint256 basePriceMultiplier) public onlyOwner {
    BASE_PRICE_MULTIPLIER = basePriceMultiplier;
  }
  function setAverageLength(uint256 averageLength) public onlyOwner {
      require(averageLength > 1, "Average length must be greater than one.");
      AVERAGE_LENGTH = averageLength;
  }
  function mintedEth() public view returns(uint256){
    return MINTED_ETH;
  }
  function mintedTld() public view returns(uint256){
    return MINTED_TLD;
  }
  function unit() public view returns (uint256) {
    return MINT_UNIT.mul(10 ** decimals());
  }
  function owner() public view virtual returns (address) {
    return _owner;
  }
  function payableOwner() public view virtual returns(address payable){
    return payable(_owner);
  }
  modifier onlyOwner() {
    require(owner() == msg.sender, "Caller is not the owner");
    _;
  }
  function decimals() public view virtual override returns (uint8) {
    return 8;
  }
  function totalAvailableEther() public view returns (uint256) {
    return address(this).balance;
  }
  function basePrice() public view returns (uint256){
    return averageGasUnits().mul(averageGasPrice()).mul(BASE_PRICE_MULTIPLIER);
  }
  function mintPrice(uint256 numberOfTokensToMint) public view returns (uint256){
    if(numberOfTokensToMint >= MINTED_TLD){
        return basePrice()
            .add(uncovered()
                 .div(AVERAGE_LENGTH));
    }
    uint256 computedPrice = MINTED_CONSTANT
        .div( MINTED_TLD
              .sub(numberOfTokensToMint))
        .add(uncovered()
             .div(AVERAGE_LENGTH))
      .add(basePrice());
    if(computedPrice <= MINTED_ETH){
      return uncovered().add(basePrice());
    }
    return computedPrice
      .sub(MINTED_ETH);
  }
  
  function burnPrice(uint256 numberOfTokensToBurn) public view returns (uint256) {
    if(MINTED_CONSTANT == 0){
      return 0;
    }
    if(uncovered() > 0){
        return 0;
    }
    return MINTED_ETH.sub(MINTED_CONSTANT.div( MINTED_TLD.add(numberOfTokensToBurn)));
  }
  function isCovered() public view returns (bool){
    return  MINTED_ETH > 0 && MINTED_ETH <= address(this).balance;
  }
  function uncovered() public view returns (uint256){
    if(isCovered()){
      return 0;
    }
    
    return MINTED_ETH.sub(address(this).balance);
  }
  function overflow() public view returns (uint256){
    if(!isCovered()){
      return 0;
    }
    
    return address(this).balance.sub(MINTED_ETH);
  }
  function transferOwnership(address newOwner) public onlyOwner returns(address){
    require(newOwner != address(0), "New owner is the zero address");
    _owner = newOwner;
    return _owner;
  }
  function mintUpdateMintedStats(uint256 unitsAmount, uint256 ethAmount) internal {
    MINTED_TLD = MINTED_TLD.add(unitsAmount);
    MINTED_ETH = MINTED_ETH.add(ethAmount);
    MINTED_CONSTANT = MINTED_TLD.mul(MINTED_ETH);
  }
  function rprice(uint256 reservedId) public view returns(uint256){
      return reservedPrice[reservedId];
  }
  function reserveMint() public returns (uint256) {
    _reservedIds.increment();

    uint256 reservedId = _reservedIds.current();
    reservedPrice[reservedId] = mintPrice(unit());
    return reservedId;
  }
  function mint(uint256 reservedId) payable public onlyOwner returns (uint256){
    require(msg.value >= reservedPrice[reservedId], "Minimum payment is not met.");
    mintUpdateMintedStats(unit(), basePrice());
    _mint(msg.sender, unit());
    return unit();
  }
  function unitsToBurn(uint256 ethAmount) public view returns (uint256){
    if(MINTED_CONSTANT == 0){
      return totalSupply();
    }
    if(ethAmount > MINTED_ETH){
      return totalSupply();
    }
    return MINTED_CONSTANT.div( MINTED_ETH.sub(ethAmount) ).sub(MINTED_TLD);
  }
  function trackGasReimburses(uint256 gasUnits) internal {
      gasUnitsHistory = gasUnitsHistory.mul(AVERAGE_LENGTH-1).add(gasUnits).div(AVERAGE_LENGTH);
  }
  function trackGasPrice(uint256 gasPrice) internal {
      gasPriceHistory = gasPriceHistory.mul(AVERAGE_LENGTH-1).add(gasPrice).div(AVERAGE_LENGTH);
  }
  function averageGasPrice() public view returns(uint256){
      return gasPriceHistory;
  }
  function averageGasUnits() public view returns(uint256){
    return gasUnitsHistory;
  }
  function reimbursementValue() public view returns(uint256){
    return averageGasUnits().mul(averageGasPrice()).mul(2);
  }
  function burn(uint256 unitsAmount) public returns(uint256){
    require(balanceOf(msg.sender) >= unitsAmount, "Insuficient funds to burn");
    uint256 value = burnPrice(unitsAmount);
    if(value > 0 && value <= address(this).balance){
      _burn(msg.sender, unitsAmount);
      payable(msg.sender).transfer(value);
    }
    return 0;
  }
  function skim(address destination) public onlyOwner returns (uint256){
      uint256 amountToSkim = overflow();
      if(amountToSkim > 0){
          if(payable(destination).send(amountToSkim)){
              emit Skimmed(destination, amountToSkim);
          }
      }
      return amountToSkim;
  }
  function reimburse(uint256 gasUnits, address payable toAddress) public onlyOwner returns (bool){
    uint256 gasStart = gasleft();
    uint256 value = reimbursementValue();
    if(value > MINTED_ETH){
      return false;
    }
    uint256 reimbursementUnits = unitsToBurn(value);

    trackGasPrice(tx.gasprice.add(1));
    if(balanceOf(msg.sender) >= reimbursementUnits && address(this).balance > value){
      _burn(msg.sender, reimbursementUnits);
      payable(toAddress).transfer(value);
    }else{
      mintUpdateMintedStats(0, value);
    }
    trackGasReimburses(gasUnits.add(gasStart.sub(gasleft()))); 
    return false;
  }
  receive() external payable {
      
  }

}
