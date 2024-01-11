//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";


contract UniPlay is ERC20Upgradeable, OwnableUpgradeable,PausableUpgradeable{

    uint public taxPercent;
    address public _treasury;
    uint public maxSupply;
    uint public maxTransferLimit;
    uint public timeLimit;
    mapping(address=>uint) public isTimeLimit;
    mapping(address=>bool) public _excludeFromTime;
    mapping(address=>bool) public isExcludedFromMaxTx;
    mapping(address=>bool) public isExcludedFromTax;
    mapping(address=>bool) public isBlocklisted;

    modifier isblock(address _addr){
        require(!isBlocklisted[_addr],"User Blocked");
        _;
    }

    
    function initialize (
    string memory name,
    string memory symbol,
    address treasury,
    uint maxsupply,
    uint _taxPercent)
    public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        taxPercent = _taxPercent;
        _treasury = treasury;
        maxSupply=maxsupply*10**18;
        maxTransferLimit = maxSupply;
        _excludeFromTime[msg.sender]=true;
        isExcludedFromMaxTx[owner()]=true;
        isExcludedFromTax[owner()]=true;
       _mint(msg.sender,maxSupply);   
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override  isblock(msg.sender){
        if(from!=owner() && !isExcludedFromMaxTx[from]){
           require(amount<=maxTransferLimit,"Exceeds Max Limit");
        }
        if(from!=owner() && !_excludeFromTime[from]){
      require(isTimeLimit[from] <= block.timestamp, 'Time limit error!');
        }
       bool isfee=true;
        if(isExcludedFromTax[from] || isExcludedFromTax[to]){
            isfee=false;
        }
      feeTransfer(from, to , amount, isfee);
    }
    
    function feeTransfer(address from , address to, uint amount,bool isfee) internal whenNotPaused{
        if(!isfee){
             super._transfer(from,to,amount);
        }else{
        uint exactTaxAmount = ((amount) * (taxPercent/1000))/100;
        uint amountToTransfer = amount - exactTaxAmount;
        if(exactTaxAmount>0){
        super._transfer(from,_treasury,exactTaxAmount);
        }
        super._transfer(from,to,amountToTransfer);}
        isTimeLimit[from]=block.timestamp +(timeLimit *1 minutes);
    }
    function burnToken (uint amount) external{
        maxSupply-=amount;
        _burn(msg.sender, amount);
    }
    
    function setTreasury (address treasury) external onlyOwner {
        _treasury = treasury;
    }
    function setTaxPercent(uint percent) external onlyOwner {
        taxPercent = percent;
    }

    function setMaxTransferLimit (uint amount) external onlyOwner {
        maxTransferLimit = amount;
    }

    function excludeFromTimeLimit(address _addr) external onlyOwner{
        require(!_excludeFromTime[_addr],"Already Excluded");
        _excludeFromTime[_addr]=true;
    }

    function  setTime(uint _setTime) external onlyOwner{
        require(timeLimit!=_setTime,"same Time");
        timeLimit=_setTime;
    }
     
    function excludeFromTax(address _addr) external onlyOwner{
      isExcludedFromTax[_addr]=true;    
      }
    function includeInTax(address _addr) external onlyOwner{
        isExcludedFromTax[_addr]=false;    
      
    }

    function excludeFromMaxTxLimit(address _addr) external onlyOwner{
        isExcludedFromMaxTx[_addr]=true;
    }

    function includeInTxLimit(address _addr) external onlyOwner{
         isExcludedFromMaxTx[_addr]=false;
    }

    function blockUser(address _addr) external onlyOwner{
        isBlocklisted[_addr]=true;
    }

    function unblockUser(address _addr) external onlyOwner{
        isBlocklisted[_addr]=false;
    }

    function getEth() external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20Upgradeable _token) external onlyOwner{
      _token.transfer(owner(),_token.balanceOf(address(this)));
    }
}