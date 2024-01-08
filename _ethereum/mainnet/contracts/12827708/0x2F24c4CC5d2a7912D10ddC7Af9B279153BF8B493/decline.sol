pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./DydxFlashloanBase.sol";
import "./ICallee.sol";

import "./IERC20.sol";

interface Cryptopunks {
    function punkIndexToAddress (uint256 punkIndex) external view returns (address);
    function punkBids (uint256 punkIndex) external view returns ( bool , uint256 , address , uint256 );
    function enterBidForPunk (uint256 punkIndex) external payable;
    function withdrawBidForPunk (uint256 punkIndex) external;
    function withdraw () external;
}

interface ENS{
    function setName(string calldata name) external returns (bytes32);
}


interface IWETH {
    function deposit() external payable;

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function withdraw(uint wad) external; ///only for Weth
}

contract declinePunkBid is ICallee, DydxFlashloanBase {
    Cryptopunks constant punkContract=Cryptopunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    address constant wethAddress= 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant soloMargin=0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    IWETH constant WETH =IWETH(wethAddress);
    ENS constant ensRegistar=ENS(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    address public owner;
    bool public paused=false;
    struct MyCustomData {
        address token;
        uint256 repayAmount;
        uint256 punkIndex;
    }

    constructor() public {
        // Give infinite approval to dydx to withdraw WETH on contract deployment,
        // so we don't have to approve the loan repayment amount (+2 wei) on each call.
        // The approval is used by the dydx contract to pay the loan back to itself.
        owner= msg.sender;
        WETH.approve(soloMargin, uint(-1));
    }

    // This is the function that will be called postLoan
    // i.e. Encode the logic to handle your flashloaned funds here
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        MyCustomData memory mcd = abi.decode(data, (MyCustomData));

        uint256 balOfLoanedToken = IERC20(mcd.token).balanceOf(address(this));

        // Note that you can ignore the line below
        // if your dydx account (this contract in this case)
        // has deposited at least ~2 Wei of assets into the account
        // to balance out the collaterization ratio
        require(
            balOfLoanedToken >= mcd.repayAmount,
            "Not enough funds to repay dydx loan!"
        );

        WETH.withdraw(WETH.balanceOf(address(this)));
        

        punkContract.enterBidForPunk.value(mcd.repayAmount)(mcd.punkIndex);
        punkContract.withdrawBidForPunk(mcd.punkIndex);
        punkContract.withdraw();
        WETH.deposit.value( address(this).balance)();


    }

    function declineBid(uint256 punkIndex)
        external 
    {
        require (!paused,"paused");
        (,,,uint _amount) = punkContract.punkBids(punkIndex) ; 
        require (_amount!=0,"No bid on this punk!");
        require (msg.sender==punkContract.punkIndexToAddress(punkIndex),"Not your punk!");
        _amount+=1;

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(soloMargin, wethAddress);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            // Encode MyCustomData for callFunction
            abi.encode(MyCustomData({token: wethAddress, repayAmount: repayAmount, punkIndex: punkIndex}))
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();
        ISoloMargin solo = ISoloMargin(soloMargin);
        solo.operate(accountInfos, operations);
    }
    function() external payable {
            // React to receiving ether
        }
    function setReverseRecord(string calldata _name) external 
    {
        require (msg.sender==owner);
        ensRegistar.setName(_name);
    }
    function togglePause() public  
    {
        require (msg.sender==owner);
        paused=!paused;  
    }
}