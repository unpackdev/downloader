// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Settings.sol";

contract Locker is Ownable{
    using SafeMath for uint256;
    bool public initialized;
    
    Settings settings;
    uint256 totalDepositedTLD;
    mapping(address=>uint256) deposits;
    mapping(address=>uint256) extracted;
    uint256 allowDepositsUntil;
    uint256 allowEtherExtractionUntil;
    uint256 totalAvailableForExtraction;
    uint256 totalTLDForExtraction;

    event DepositsStarted(uint256 startedUntil);
    event DepositsEnded(uint256 totalTLDAmount, uint256 totalAvailableEther);
    event ExtractionsEnded();
    
    constructor(){

    }

    function initialize(Settings _settings) public onlyOwner{
      require(!initialized, "Contract instance has already been initialized");
      initialized = true;
      settings = _settings;
    }
    
    function setSettingsAddress(Settings _settings) public onlyOwner {
      
        settings = _settings;
    }
    
    function tld() public view returns(ERC20){
      return ERC20(settings.getNamedAddress("TLD"));
    }
    
    function deposit(uint256 amount) public {
        require(amount > 0, "Deposit value must be greater than zero");
        require(tld().allowance(msg.sender, address(this)) >= amount, "Allowance too small to cover deposit");
        
        require(block.timestamp <= allowDepositsUntil
                || msg.sender == owner(),"Wait for another deposit period to begin");
        tld().transferFrom(msg.sender, address(this), amount);
        totalDepositedTLD = totalDepositedTLD.add(amount);
        deposits[msg.sender] = deposits[msg.sender].add(amount);
    }
    function balanceOf(address userAddress) public view returns(uint256){
        return deposits[userAddress];
    }
    function withdraw(uint256 amount) public {
        require(deposits[msg.sender] >= amount, "Not enough deposited to withdraw");
        require(tld().balanceOf(address(this)) >= amount, "Not enough TLD to process");
        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        totalDepositedTLD = totalDepositedTLD.sub(amount);
        tld().transfer(msg.sender, amount);
    }
    function withdrawAll() public {
        require(deposits[msg.sender] > 0, "Not enough deposited to withdraw");
        withdraw(deposits[msg.sender]);
    }

    function extractionAmount(address ofAddress) public view returns(uint256){
      if(!isExtractionsOpen()){
        return 0;
      }
      if(deposits[ofAddress] == 0){
        return 0;
      }
      if(extracted[ofAddress] >= allowEtherExtractionUntil){
        return 0;
      }
      if(totalTLDForExtraction > 0){
        return totalAvailableForExtraction.mul(deposits[ofAddress]).div(totalTLDForExtraction);
      }
      return 0;
    }
    function totalEtherAvailableForExtraction() public view returns(uint256){
      return totalAvailableForExtraction;
    }
    function totalDeposited() public view returns(uint256){
      return totalTLDForExtraction;
    }
    function totalBalanceTLD() public view returns(uint256){
      return totalDepositedTLD;
    }
    function contractBalance() public view returns(uint256){
      return address(this).balance;
    }
    
    function extract() public returns(uint256){
        require(!isDepositsOpen(), "Deposits are still open");
        require(deposits[msg.sender] > 0, "Nothing deposited");
        require(extracted[msg.sender] <= allowEtherExtractionUntil, "Already extracted. Wait for another extraction period");
        uint256 availableToExtract = extractionAmount(msg.sender);
        require(availableToExtract > 0, "Nothing to extract");
        require(availableToExtract <= address(this).balance, "Not enough balance to process extraction");
        extracted[msg.sender] = allowEtherExtractionUntil + 1;
        payable(msg.sender).transfer(availableToExtract);
        return availableToExtract;
    }
    function isDepositsOpen() public view returns(bool) {
        return block.timestamp <= allowDepositsUntil;
    }
    function isExtractionsOpen() public view returns(bool) {
        return block.timestamp <= allowEtherExtractionUntil;
    }
    
    function startDeposit(uint256 window) public onlyOwner {
        require(!isDepositsOpen(), "deposits already opened");
        allowDepositsUntil = block.timestamp.add(window);
        if(allowEtherExtractionUntil > 0){
            emit ExtractionsEnded();
        }
        allowEtherExtractionUntil = 0;
        totalAvailableForExtraction = 0;
        totalTLDForExtraction = 0;
        emit DepositsStarted(allowDepositsUntil);
    }
    function startExtraction(uint256 window) public payable onlyOwner {
        allowDepositsUntil = 0;
        allowEtherExtractionUntil = block.timestamp.add(window);
        totalAvailableForExtraction = address(this).balance;
        totalTLDForExtraction = totalDepositedTLD;
        emit DepositsEnded(totalDepositedTLD, totalAvailableForExtraction);
    }

    receive() external payable {
    }
    
}
