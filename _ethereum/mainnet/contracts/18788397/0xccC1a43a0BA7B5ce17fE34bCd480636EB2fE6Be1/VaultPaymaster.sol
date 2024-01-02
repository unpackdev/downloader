// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/* solhint-disable reason-string */
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./IPaymaster.sol";
import "./IEntryPoint.sol";
import "./IOwnable.sol";
import "./IPlatformFacet.sol";
import "./IPaymasterFacet.sol";
import "./IExchangeAdapter.sol";
import "./IERC20.sol";
import "./IWeth9.sol";
import "./SafeERC20.sol";
contract VaultPaymaster is  Initializable, UUPSUpgradeable,IPaymaster,ReentrancyGuardUpgradeable{ 
    //calculated cost of the postOp
    uint256 public constant COST_OF_POST = 15000;
    IEntryPoint public entryPoint;
    address public diamond;
    uint256 public COST_OF_POST_V2;
    using SafeERC20 for IERC20;
    modifier onlyOwner{
        require(msg.sender == IOwnable(diamond).owner(),"only owner");
        _;
    }

    event Deposit(address _caller,address _wallet,uint256 _amount);
    event WithdrawEth(address _caller,address _wallet,uint256 _amount);
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    function initialize(address  _diamond,IEntryPoint _entryPoint,uint256 _newCostOfPost) public initializer {
        __UUPSUpgradeable_init();
        diamond=_diamond;
        entryPoint=_entryPoint;
        COST_OF_POST_V2=_newCostOfPost;
    }
    function setCostOfPost(uint256 _newCostOfPost) external onlyOwner{
            COST_OF_POST_V2=_newCostOfPost;
    }
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
    //--
    function setQuotaWhiteList(address _target,uint256 _amount,bool _type) external {
         require(msg.sender == IOwnable(diamond).owner() || msg.sender==IPaymasterFacet(diamond).getPayer(),"only owner");
         IPaymasterFacet(diamond).setQuotaWhiteList(_target,_amount,_type);
    }
    function deposit(IPaymasterFacet.DepositInfo memory _depositInfo) external nonReentrant{
           IPlatformFacet platformFacet=IPlatformFacet(diamond);
           address IPlatformAdapter = platformFacet.getModuleToProtocolA(address(this),_depositInfo.protocol);
           address weth=platformFacet.getWeth();
           require(IPlatformAdapter !=address(0),"VaultPaymaster:protocol must be platform allowed");
           uint256 sendAssetType=platformFacet.getTokenType(_depositInfo.sendAsset);
           uint256 receiveAssetType= platformFacet.getTokenType(_depositInfo.receiveAsset);
           require(sendAssetType !=0 && receiveAssetType!=0 && sendAssetType== _depositInfo.positionType && receiveAssetType == _depositInfo.positionType,"VaultPaymaster:asset must be platform allowed");
           require(_depositInfo.receiveAsset ==weth,"VaultPaymaster:receiveAsset must be weth");    
           IERC20(_depositInfo.sendAsset).safeTransferFrom(msg.sender,address(this),_depositInfo.amountIn);


           IExchangeAdapter.AdapterCalldata memory adapterCalldata   = IExchangeAdapter(IPlatformAdapter).getAdapterCallData(
           address(this), _depositInfo.sendAsset, _depositInfo.receiveAsset,_depositInfo.adapterType,_depositInfo.amountIn,_depositInfo.amountLimit, _depositInfo.adapterData); 
           IERC20(_depositInfo.sendAsset).approve(adapterCalldata.spender, _depositInfo.approveAmount);
           (bool success, bytes memory result) = adapterCalldata.target.call{value:adapterCalldata.value}(adapterCalldata.data);
           if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
           }
           //handle weth
           uint256 wethBalance= IERC20(weth).balanceOf(address(this));
           if(wethBalance>0){
              IWETH9(weth).withdraw(wethBalance);
           }
           uint256 allBalance= address(this).balance;
           deposit(allBalance);
           //storage balance data
           IPaymasterFacet(diamond).setWalletPaymasterBalance(_depositInfo.wallet,allBalance,true);
           emit Deposit(msg.sender,_depositInfo.wallet,allBalance);
    }
    


    function depositEth(address _wallet) payable external nonReentrant{
         require(msg.value >0 ,"VaultPaymaster:amount error");
         deposit(msg.value);
         IPaymasterFacet(diamond).setWalletPaymasterBalance(_wallet,msg.value,true);
         emit Deposit(msg.sender,_wallet,msg.value);

    }
    
    function withdrawEth(address payable _wallet,uint256 _amount) external nonReentrant{
         IPaymasterFacet(diamond).setWalletPaymasterBalance(_wallet,_amount,false);
         withdrawTo(_wallet,_amount);
         emit WithdrawEth(msg.sender,_wallet,_amount);
    }

    function getWalletPaymasterBalance(address _wallet) external view returns(uint256){
       return  IPaymasterFacet(diamond).getWalletPaymasterBalance(_wallet);
    }
    function getQuota(address _wallet) external view returns(uint256){
       return  IPaymasterFacet(diamond).getQuota(_wallet);
    }
    //----
    function setOpenValidMiner(bool _openValidMiner) external onlyOwner{
         IPaymasterFacet(diamond).setOpenValidMiner(_openValidMiner);
    }
    function setMinerList(address[] memory _addMiners,address[] memory _delMiners) external onlyOwner{
          IPaymasterFacet(diamond).setMinerList(_addMiners,_delMiners);
    } 
    //--
    function deposit(uint256 _value) internal {
        entryPoint.depositTo{value: _value}(address(this));
    }

    function withdrawTo(
        address payable withdrawAddress,
        uint256 amount
    ) internal {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

 

    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    function getDeposit() public view returns (uint256) {
        return entryPoint.balanceOf(address(this));
    }

    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entryPoint.withdrawStake(withdrawAddress);
    }

    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
        _requireFromEntryPoint();
        return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }

    function _requireFromEntryPoint() internal virtual {
        require(msg.sender == address(entryPoint), "Sender not EntryPoint");
    }

    /**
     * validate the request:
     * if this is a constructor call, make sure it is a known account.
     * verify the sender has enough tokens.
     * (since the paymaster is also the token, there is no notion of "approval")
     */
    function _validatePaymasterUserOp(UserOperation calldata userOp,bytes32 /*userOpHash*/,uint256 requiredPreFund) internal view returns (bytes memory context, uint256 validationData) {
         (requiredPreFund);
        // verificationGasLimit is dual-purposed, as gas limit for postOp. make sure it is high enough
        // make sure that verificationGasLimit is high enough to handle postOp

        require(
            userOp.verificationGasLimit > COST_OF_POST_V2,
            "Paymaster: gas too low for postOp"
        );
        return (abi.encode(userOp.sender), 0);
    }

    /// @inheritdoc IPaymaster
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external override {
        verifyMiner();
        _requireFromEntryPoint();
        _postOp(mode, context, actualGasCost);
    }

    /**
     * actual charge of user.
     * this method will be called just after the user's TX with mode==OpSucceeded|OpReverted (account pays in both cases)
     * BUT: if the user changed its balance in a way that will cause  postOp to revert, then it gets called again, after reverting
     * the user's TX , back to the state it was before the transaction started (before the validatePaymasterUserOp),
     * and the transaction should succeed there.    _validatePaymasterUserOp->    call ->_postOp   userOp[]
     */

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal {
        //we don't really care about the mode, we just pay the gas with the user's tokens.
        (mode);
        address sender = abi.decode(context, (address));
        IPaymasterFacet paymasterFacet=IPaymasterFacet(diamond);
        address wallet = IOwnable(sender).owner();
        uint256 charge = actualGasCost + COST_OF_POST_V2;
       
        uint256 quota=paymasterFacet.getQuota(wallet);
        if( quota > 0) {
            address payer=paymasterFacet.getPayer();
            uint256 payerBalance=paymasterFacet.getWalletPaymasterBalance(payer);
            if(payerBalance>=quota && payer !=address(0)){
                if(quota>=charge){
                     quota=charge;
                     charge=0;
                }else{
                    charge =charge-quota;
                }
                paymasterFacet.setQuotaWhiteList(wallet,quota,false);
                paymasterFacet.setWalletPaymasterBalance(payer,quota,false);  
            }
        }    
        if(charge>0){
            paymasterFacet.setWalletPaymasterBalance(wallet,charge,false);
        }
    }
    
    function verifyMiner() internal view {
         IPaymasterFacet paymasterFacet=IPaymasterFacet(diamond);
         if(paymasterFacet.getOpenValidMiner()){
             require(paymasterFacet.getMinerStatus(tx.origin),"VaultPaymaster:invaliad miner");
         }  
    }



    fallback() external payable {
        // custom function code
    }

    receive() external payable {
        // custom function code
    }
}
