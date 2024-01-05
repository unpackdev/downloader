/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./PresaleData.sol";
import "./PresaleSettings.sol";
import "./IERC20Timelock.sol";
import "./IERC20TimelockFactory.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract YsecPresale is Ownable, ReentrancyGuard{
    using SafeMath for uint;

    //steps
    //0:initialized
    //1:Tokens transfered and ready for contributions
    //>1 presale finished
    //2:Tokens transfered to locks
    //3:Liquidity Added on Uni and ready for withdrawal
    //>3 tokens claimable and eth distributable

    address public UniswapRouterAddress;
    address public UniswapFactoryAddress;
    
    address public TimelockFactoryAddress;
    address public YieldFeeAddress;
    address public FeeAddress;

    mapping(uint256 => PresaleData) public Presales;
    uint256[] public PresaleIndexer;

    event TokensTransfered(uint256 presaleId, uint256 amount);
    event Contributed(uint256 presaleId, address contributor, uint256 amount);
    event RetrievedEth(uint256 presaleId, address contributor, uint256 amount);
    event RetrievedTokens(uint256 presaleId, uint256 amount);
    event TokensTransferedToLocks(uint256 presaleId, uint256 amount);
    event NoTokensTransferedToLocks(uint256 presaleId);
    event UniswapLiquidityAdded(uint256 presaleId, bool permaLockedLiq, uint256 amountOfEth, uint256 amountOfTokens);
    event ClaimedTokens(uint256 presaleId, address claimer, uint256 amount);
    event EthYieldFeeDistributed(uint256 presaleId, address reciever, uint256 amount);
    event EthFeeDistributed(uint256 presaleId, address reciever, uint256 amount);
    event EthDistributed(uint256 presaleId, address reciever, uint256 amount);

    constructor(address timelockFactoryAddress, address yieldFeeAddress, address feeAddress) public{
        UniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        UniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        TimelockFactoryAddress = timelockFactoryAddress;
        YieldFeeAddress = yieldFeeAddress;
        FeeAddress = feeAddress;
    }

    function SetTimelockFactory(address timelockFactoryAddress) onlyOwner() external{
        TimelockFactoryAddress = timelockFactoryAddress;
    }

    function SetYieldFeeAddress(address yieldFeeAddress) onlyOwner() external{
        YieldFeeAddress = yieldFeeAddress;
    }

    function SetFeeAddress(address feeAddress) onlyOwner() external{
        FeeAddress = feeAddress;
    }

    function SetUniswapRouterAddress(address router) onlyOwner() external{
        UniswapRouterAddress = router;
    }

    function SetUniswapFactoryAddress(address router) onlyOwner() external{
        UniswapFactoryAddress = router;
    }

    function CreatePresale(PresaleSettings memory settings) external returns(uint256 presaleId){
        require(settings.EndDate > settings.StartDate, "Do not start before end");
        require(settings.StartDate > block.timestamp, "Start in future");
        require(settings.Hardcap >= settings.Softcap, "Hardcap has to equal or exceed softcap");

        presaleId = PresaleIndexer.length.add(1);

        Presales[presaleId].StartDate = settings.StartDate;
        Presales[presaleId].EndDate = settings.EndDate;
        Presales[presaleId].Softcap = settings.Softcap;
        Presales[presaleId].Hardcap = settings.Hardcap;
        Presales[presaleId].TokenLiqAmount = settings.TokenLiqAmount;
        Presales[presaleId].LiqPercentage = settings.LiqPercentage;
        Presales[presaleId].TokenPresaleAllocation = settings.TokenPresaleAllocation;
        Presales[presaleId].PermalockLiq = settings.PermalockLiq;
        if(!settings.PermalockLiq) require(settings.LiquidityTokenAllocation.ReleaseDate > block.timestamp, "Liquidity allocation not set in future");
        Presales[presaleId].LiquidityTokenAllocation = settings.LiquidityTokenAllocation;

        Presales[presaleId].Addresses.TokenOwnerAddress = _msgSender();
        Presales[presaleId].Addresses.TokenAddress = settings.Token;
        Presales[presaleId].Addresses.TokenTimeLock = address(0x0);

        Presales[presaleId].State.TotalTokenAmount = 0;
        Presales[presaleId].State.Step = 0;
        Presales[presaleId].State.ContributedEth = 0;
        Presales[presaleId].State.RaisedFeeEth = 0;
        Presales[presaleId].State.Exists = true;
        Presales[presaleId].State.RetrievedTokenAmount = 0;
        Presales[presaleId].State.RetrievedEthAmount = 0;
        Presales[presaleId].State.NumberOfContributors = 0;

        Presales[presaleId].Info.Name = settings.Name;
        Presales[presaleId].Info.Website = settings.Website;
        Presales[presaleId].Info.Telegram = settings.Telegram;
        Presales[presaleId].Info.Twitter = settings.Twitter;
        Presales[presaleId].Info.Github = settings.Github;
        Presales[presaleId].Info.Medium = settings.Medium;

        Presales[presaleId].State.TotalTokenAmount = Presales[presaleId].State.TotalTokenAmount.add(settings.TokenLiqAmount);
        Presales[presaleId].State.TotalTokenAmount = Presales[presaleId].State.TotalTokenAmount.add(settings.TokenPresaleAllocation);
        for(uint i=0; i<settings.TokenAllocations.length; i++)
        {
            require(settings.TokenAllocations[i].ReleaseDate > block.timestamp, "Allocation not set in future");
            TokenAllocation memory allocation = settings.TokenAllocations[i];
            if(allocation.Token == Presales[presaleId].Addresses.TokenAddress) Presales[presaleId].State.TotalTokenAmount = Presales[presaleId].State.TotalTokenAmount.add(allocation.Amount);
            Presales[presaleId].TokenAllocations.push(allocation);
        }
        PresaleIndexer.push(presaleId);
    }

    //step 0 -> part of init
    function TransferTokens(uint256 presaleId) nonReentrant() RequireTokenOwner(presaleId) external{
        RequireStep(presaleId, 0);
        require(IERC20(Presales[presaleId].Addresses.TokenAddress).allowance(_msgSender(), address(this)) >= Presales[presaleId].State.TotalTokenAmount , "Transfer of token has not been approved");
        IERC20(Presales[presaleId].Addresses.TokenAddress).transferFrom(_msgSender(), address(this), Presales[presaleId].State.TotalTokenAmount);
        Presales[presaleId].State.Step = 1;
        emit TokensTransfered(presaleId, Presales[presaleId].State.TotalTokenAmount);
    }

    //step 1 -> contributions open
    function Contribute(uint256 presaleId) nonReentrant() public payable{
        RequireStep(presaleId, 1);
        require(msg.value > 0, "Cannot contribute 0");
        require(!PresaleFinished(presaleId), "Presale has already finished");
        require(PresaleStarted(presaleId), "Presale has not started yet!");

        uint256 amountRecieved = msg.value;
        require(Presales[presaleId].State.ContributedEth + amountRecieved <= Presales[presaleId].Hardcap, "Incoming contribution exceeds hardcap");
        Presales[presaleId].State.ContributedEth = Presales[presaleId].State.ContributedEth.add(amountRecieved);
        Presales[presaleId].State.RaisedFeeEth = Presales[presaleId].State.RaisedFeeEth.add(amountRecieved.div(100).mul(5));//5% is fee
        if(Presales[presaleId].EthContributedPerAddress[_msgSender()] == 0) Presales[presaleId].State.NumberOfContributors = Presales[presaleId].State.NumberOfContributors.add(1);
        Presales[presaleId].EthContributedPerAddress[_msgSender()] = Presales[presaleId].EthContributedPerAddress[_msgSender()].add(amountRecieved);
        emit Contributed(presaleId, _msgSender(), amountRecieved);
     }

    //step 1 -> in case of failed presale allow users to retrieve invested eth
    //https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now
    function RetrieveEth(uint256 presaleId, address contributor) nonReentrant() external{
        RequireStep(presaleId, 1);
        require(!SoftcapMet(presaleId), "Softcap has been met! you are not able to retrieve ETH");
        require(PresaleFinished(presaleId), "Presale has not finished! you are not able to retrieve ETH");

        uint256 ethContributedForAddress = Presales[presaleId].EthContributedPerAddress[contributor];
        require(ethContributedForAddress > 0, "No eth available for withdrawal");
        Presales[presaleId].EthContributedPerAddress[contributor] = 0;
        (bool success, ) = contributor.call{value:ethContributedForAddress}('');
        require(success, "Transfer failed.");
        emit RetrievedEth(presaleId, contributor, ethContributedForAddress);
    }

    //step 1 -> in case of failed presale allow tokenowner to retrieve tokens
    function RetrieveTokens(uint256 presaleId) RequireTokenOwner(presaleId) nonReentrant() external{
        RequireStep(presaleId, 1);
        require(!SoftcapMet(presaleId), "Softcap has been met! you are not able to retrieve ETH");
        require(PresaleFinished(presaleId), "Presale has not finished! you are not able to retrieve ETH");
        
        uint256 remainingAmount = Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].State.RetrievedTokenAmount);
        require(remainingAmount > 0, "No remaining tokens for retrieval");
        uint256 balance = IERC20(Presales[presaleId].Addresses.TokenAddress).balanceOf(address(this));
        require(balance >= remainingAmount, "No tokens left!");

        Presales[presaleId].State.RetrievedTokenAmount = Presales[presaleId].State.RetrievedTokenAmount.add(remainingAmount);
        IERC20(Presales[presaleId].Addresses.TokenAddress).transfer(_msgSender(), remainingAmount);
        emit RetrievedTokens(presaleId, remainingAmount);
    }

    //step 1 -> transfer tokens to allocated locks in preperation for step 2 
    function TransferTokensToLocks(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 1);
        require(SoftcapMet(presaleId), "Softcap has not been met!");
        require(PresaleFinished(presaleId), "Presale has not finished!");
        //create timelock
        Presales[presaleId].Addresses.TokenTimeLock = IERC20TimelockFactory(TimelockFactoryAddress).CreateTimelock(address(this), Presales[presaleId].Addresses.TokenOwnerAddress);

        if(Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].TokenPresaleAllocation).sub(Presales[presaleId].TokenLiqAmount) == 0){
            Presales[presaleId].State.Step = 2;
            emit NoTokensTransferedToLocks(presaleId);
        }else{
            //approve all tokens except used for presale and liq
            IERC20(Presales[presaleId].Addresses.TokenAddress).approve(Presales[presaleId].Addresses.TokenTimeLock, Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].TokenPresaleAllocation).sub(Presales[presaleId].TokenLiqAmount));
            //create and transfer allocations
            for(uint i=0; i<Presales[presaleId].TokenAllocations.length; i++)
            {
                IERC20Timelock(Presales[presaleId].Addresses.TokenTimeLock).AddAllocation(Presales[presaleId].TokenAllocations[i].Name, Presales[presaleId].TokenAllocations[i].Amount, Presales[presaleId].TokenAllocations[i].ReleaseDate, Presales[presaleId].TokenAllocations[i].IsInterval, Presales[presaleId].TokenAllocations[i].PercentageOfRelease, Presales[presaleId].TokenAllocations[i].IntervalOfRelease, Presales[presaleId].Addresses.TokenAddress);
            }
            Presales[presaleId].State.Step = 2;
            emit TokensTransferedToLocks(presaleId, Presales[presaleId].State.TotalTokenAmount.sub(Presales[presaleId].TokenPresaleAllocation).sub(Presales[presaleId].TokenLiqAmount));
        }
    }

    //step 2 -> add liquidity to uniswap in preperation for step 3
    function AddUniswapLiquidity(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 2);
        IERC20(Presales[presaleId].Addresses.TokenAddress).approve(UniswapRouterAddress, Presales[presaleId].TokenLiqAmount);//approve unirouter
        uint256 amountOfEth = Presales[presaleId].State.ContributedEth.sub(Presales[presaleId].State.RaisedFeeEth).div(100).mul(Presales[presaleId].LiqPercentage);
        if(Presales[presaleId].PermalockLiq)//permanently locked liq
        {
            IUniswapV2Router02(UniswapRouterAddress).addLiquidityETH{value : amountOfEth}(address(Presales[presaleId].Addresses.TokenAddress), Presales[presaleId].TokenLiqAmount, 0, 0, address(0x000000000000000000000000000000000000dEaD), block.timestamp.add(1 days));
        }
        else// use allocation for locking
        {
            IUniswapV2Router02(UniswapRouterAddress).addLiquidityETH{value : amountOfEth}(address(Presales[presaleId].Addresses.TokenAddress), Presales[presaleId].TokenLiqAmount, 0, 0, address(this), block.timestamp.add(1 days));
            address pairAddress = IUniswapV2Factory(UniswapFactoryAddress).getPair(IUniswapV2Router02(UniswapRouterAddress).WETH(), Presales[presaleId].Addresses.TokenAddress);
            IERC20(pairAddress).approve(Presales[presaleId].Addresses.TokenTimeLock, IERC20(pairAddress).balanceOf(address(this)));
            IERC20Timelock(Presales[presaleId].Addresses.TokenTimeLock).AddAllocation(Presales[presaleId].LiquidityTokenAllocation.Name, IERC20(pairAddress).balanceOf(address(this)), Presales[presaleId].LiquidityTokenAllocation.ReleaseDate, Presales[presaleId].LiquidityTokenAllocation.IsInterval, Presales[presaleId].LiquidityTokenAllocation.PercentageOfRelease, Presales[presaleId].LiquidityTokenAllocation.IntervalOfRelease, pairAddress);
        }
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(amountOfEth);
        Presales[presaleId].State.Step = 3;
        emit UniswapLiquidityAdded(presaleId, Presales[presaleId].PermalockLiq, amountOfEth, Presales[presaleId].TokenLiqAmount);
    }

    //step 3 -> claim tokens for presale contributors
    function ClaimTokens(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 3);
        require(Presales[presaleId].EthContributedPerAddress[_msgSender()] > 0, "No contributions for address");
        require(Presales[presaleId].ClaimedAddress[_msgSender()] == false, "Already claimed for address");

        uint256 amountToSend = Presales[presaleId].EthContributedPerAddress[_msgSender()].mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].State.ContributedEth);
        Presales[presaleId].ClaimedAddress[_msgSender()] = true;
        IERC20(Presales[presaleId].Addresses.TokenAddress).transfer(_msgSender(), amountToSend);
        emit ClaimedTokens(presaleId, _msgSender(), amountToSend);
    }

    //step 3 -> distribute eth to presale host and fees to ysec
    function DistributeEth(uint256 presaleId) nonReentrant() external{
        RequireStep(presaleId, 3);
        require(Presales[presaleId].State.ContributedEth.sub(Presales[presaleId].State.RetrievedEthAmount) > 0, "No eth left to distribute");
        
        (bool successDiv, ) = YieldFeeAddress.call{value: Presales[presaleId].State.RaisedFeeEth.div(2)}('');
        require(successDiv, "Transfer to yield fee address failed.");
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(Presales[presaleId].State.RaisedFeeEth.div(2));
        (bool successFee, ) = FeeAddress.call{value: Presales[presaleId].State.RaisedFeeEth.div(2)}('');
        require(successFee, "Transfer to fee address failed.");
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(Presales[presaleId].State.RaisedFeeEth.div(2));
        uint256 amountSendToOwner = Presales[presaleId].State.ContributedEth.sub(Presales[presaleId].State.RetrievedEthAmount);
        (bool successOwner, ) = Presales[presaleId].Addresses.TokenOwnerAddress.call{value: amountSendToOwner}('');
        require(successOwner, "Transfer to owner failed.");
        Presales[presaleId].State.RetrievedEthAmount = Presales[presaleId].State.RetrievedEthAmount.add(amountSendToOwner);

        emit EthYieldFeeDistributed(presaleId, YieldFeeAddress, Presales[presaleId].State.RaisedFeeEth.div(2));
        emit EthFeeDistributed(presaleId, FeeAddress, Presales[presaleId].State.RaisedFeeEth.div(2));
        emit EthDistributed(presaleId, Presales[presaleId].Addresses.TokenOwnerAddress, amountSendToOwner);
    }

    modifier RequireTokenOwner(uint256 presaleId){
        ValidPresale(presaleId);
        require(Presales[presaleId].Addresses.TokenOwnerAddress == _msgSender(), "Sender is not owner of tokens!");
        _;
    }

    function PresaleStarted(uint256 presaleId) public view returns(bool){
        return Presales[presaleId].State.Step > 0 && Presales[presaleId].StartDate <= block.timestamp && !PresaleFinished(presaleId);
    }

     function PresaleFinished(uint256 presaleId) public view returns(bool){
        return HardcapMet(presaleId) || Presales[presaleId].EndDate <= block.timestamp;
    }

    function SoftcapMet(uint256 presaleId) public view returns (bool){
        return Presales[presaleId].State.ContributedEth >= Presales[presaleId].Softcap;
    }

    function HardcapMet(uint256 presaleId) public view returns (bool){
        return Presales[presaleId].State.ContributedEth >= Presales[presaleId].Hardcap;
    }

    function RequireStep(uint256 presaleId, uint256 step) private{
        require(Presales[presaleId].State.Step == step, "Required step is not active!");
    }

    function ValidPresale(uint256 presaleId) private{
        require(Presales[presaleId].State.Exists, "Presale does not exist");
    }
    
    function PresaleIndexerLength() public view returns(uint256){
        return PresaleIndexer.length;
    }

    function GetTokenAllocations(uint256 presaleId) public view returns(TokenAllocation[] memory){
        TokenAllocation[] memory result = new TokenAllocation[](Presales[presaleId].TokenAllocations.length);
        for(uint i=0; i< Presales[presaleId].TokenAllocations.length; i++)
        {
            TokenAllocation storage allocation = Presales[presaleId].TokenAllocations[i];
            result[i] = allocation;
        }
        return result;
    }

    function GetEthContributedForAddress(uint256 presaleId, address forAddress) public view returns(uint256){
        return Presales[presaleId].EthContributedPerAddress[forAddress];
    }

    function GetAmountOfTokensForAddress(uint256 presaleId, address forAddress) public view returns(uint256){
        return Presales[presaleId].EthContributedPerAddress[forAddress].mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].State.ContributedEth);
    }

    function GetHardcapAmountOfTokensForAddress(uint256 presaleId, address forAddress) public view returns(uint256){
        return Presales[presaleId].EthContributedPerAddress[forAddress].mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].Hardcap);
    }

    function GetRatio(uint256 presaleId) public view returns(uint256){
        uint256 oneEth = 1000000000000000000;
        return oneEth.mul(Presales[presaleId].TokenPresaleAllocation).div(Presales[presaleId].State.ContributedEth);
    }

    function GetNumberOfContributors(uint256 presaleId) public view returns(uint256){
        return Presales[presaleId].State.NumberOfContributors;
    }
}