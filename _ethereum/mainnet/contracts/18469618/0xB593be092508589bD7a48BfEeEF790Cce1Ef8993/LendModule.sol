// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";

import "./ModuleBase.sol";


import "./IOwnable.sol";
import "./SafeERC20.sol";
import "./Invoke.sol";
import "./ILendFacet.sol";
import "./ILendModule.sol";
import "./IERC721.sol";
contract LendModule is ModuleBase,ILendModule,Initializable,UUPSUpgradeable,ReentrancyGuardUpgradeable{ 
    using Invoke for IVault;
    using SafeERC20 for IERC20;
    modifier onlyOwner() {
        require(
            msg.sender == IOwnable(diamond).owner(),
            "TradeModule:only owner"
        );
        _;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _diamond) public initializer {
        __UUPSUpgradeable_init();
        diamond=_diamond;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
    function setDomainHash(string memory _name,string memory _version) public onlyOwner{
        bytes32  DomainInfoTypeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        bytes32  _domainHash= keccak256(abi.encode(
              DomainInfoTypeHash,
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                block.chainid,
                address(this)
        ));
        ILendFacet(diamond).setDomainHash(_domainHash);
        emit SetDomainHash(_name,_version,block.chainid,address(this),_domainHash);
    }

    function setLendFeePlatformRecipient(address _recipient) public onlyOwner {
         ILendFacet(diamond).setLendFeePlatformRecipient(_recipient);
         emit SetLendFeePlatformRecipient(_recipient);
    }

    function submitOrder(ILendFacet.LendInfo memory _lendInfo,bytes calldata _debtorSignature,bytes calldata _loanerSignature) external nonReentrant {
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          require(vaultFacet.getVaultType(_lendInfo.debtor) == 3,"LendModule:debtor vaultType error");
          require(vaultFacet.getVaultType(_lendInfo.loaner) == 2,"LendModule:loaner vaultType error");
          require(_lendInfo.recipient != address(0) && _lendInfo.recipient != _lendInfo.debtor,"LendModule:recipient error");
          require(_lendInfo.loaner != _lendInfo.debtor,"LendModule:loaner error");
          require(_lendInfo.maturity > block.timestamp,"LendModule:invalid maturity");
          require(_lendInfo.borrowAmount>=_lendInfo.borrowMinAmount,"LendModule:borrowAmount error");
          address eth=IPlatformFacet(diamond).getEth();
          if(_lendInfo.collateralAsset == eth){
             require(_lendInfo.debtor.balance >= _lendInfo.collateralAmount,"LendModule:collateralAmount not enough");
          }else{
             require(IERC20(_lendInfo.collateralAsset).balanceOf(_lendInfo.debtor) >= _lendInfo.collateralAmount,"LendModule:collateralAmount not enough");
          }
          if(_lendInfo.borrowAsset == eth){
              require(_lendInfo.loaner.balance >= _lendInfo.borrowAmount,"LendModule:borrowAmount not enough");
          }else{
              require(IERC20(_lendInfo.borrowAsset).balanceOf(_lendInfo.loaner) >= _lendInfo.borrowAmount,"LendModule:borrowAmount not enough");
          }    
          handleOrder(_lendInfo.debtor,_lendInfo,_debtorSignature);
          handleOrder(_lendInfo.loaner,_lendInfo,_loanerSignature);   
          //storage data
          vaultFacet.setVaultLock(_lendInfo.debtor,true);
          ILendFacet  lendFacet=ILendFacet(diamond);
        
          _lendInfo.index=lendFacet.getLoanerLendInfoLength(_lendInfo.loaner);
          lendFacet.setDebtorLendInfo(_lendInfo.debtor,_lendInfo);
          lendFacet.setLoanerLendInfo(_lendInfo.loaner,_lendInfo.debtor);
          //tranfer lendFeePlatformRecipient
          address lendFeePlatformRecipient=lendFacet.getLendFeePlatformRecipient();
          
          if(_lendInfo.borrowAsset == eth){
            if(lendFeePlatformRecipient != address(0)){
                IVault(_lendInfo.loaner).invokeTransferEth(lendFeePlatformRecipient,_lendInfo.platformFee);
            }     
             IVault(_lendInfo.loaner).invokeTransferEth(_lendInfo.recipient,_lendInfo.borrowAmount-_lendInfo.platformFee);
          }else{
            if(lendFeePlatformRecipient != address(0)){
                 IVault(_lendInfo.loaner).invokeTransfer(_lendInfo.borrowAsset,lendFeePlatformRecipient,_lendInfo.platformFee);
            }   
            //tranfer metamask
            IVault(_lendInfo.loaner).invokeTransfer(_lendInfo.borrowAsset,_lendInfo.recipient,_lendInfo.borrowAmount-_lendInfo.platformFee);
          }
          updatePosition(_lendInfo.debtor,_lendInfo.collateralAsset,1,0);
          updatePosition(_lendInfo.loaner,_lendInfo.borrowAsset,1,0);
          //set CurrentVaultModule
          vaultFacet.setFuncBlackList(_lendInfo.loaner,bytes4(keccak256("setVaultType(address,uint256)")),true);
          emit SubmitOrder(msg.sender,_lendInfo);      
    }

    function handleOrder(address _signer,ILendFacet.LendInfo memory _lendInfo,bytes memory _signature) internal  view{
        ILendFacet.LendInfo memory tempInfo= ILendFacet.LendInfo({
            orderId:_lendInfo.orderId,
            loaner:_lendInfo.loaner,
            debtor:_lendInfo.debtor,
            recipient:_lendInfo.recipient,
            collateralAsset:_lendInfo.collateralAsset,
            collateralAmount:_lendInfo.collateralAmount,
            borrowAsset:_lendInfo.borrowAsset,
            borrowMinAmount:_lendInfo.borrowMinAmount,
            borrowAmount:_lendInfo.borrowAmount,
            maturity:_lendInfo.maturity,
            platformFee:_lendInfo.platformFee,
            index:_lendInfo.index,
            collateralAssetType:_lendInfo.collateralAssetType,
            nftId:_lendInfo.nftId
        });
        if(_signer == tempInfo.debtor){
            tempInfo.borrowAmount=0;
            tempInfo.loaner=address(0);
        }
        bytes32  infoTypeHash = keccak256("LendInfo(uint256 orderId,address loaner,address debtor,address recipient,address collateralAsset,uint256 collateralAmount,address borrowAsset,uint256 borrowMinAmount,uint256 borrowAmount,uint256 maturity,uint256 platformFee,uint256 index)");
        bytes32  _hashInfo= keccak256(abi.encode(
            infoTypeHash,
            tempInfo
        ));
        verifySigbature(_signer,_hashInfo,_signature);
    }
    function verifySigbature(address _signer,bytes32 _hash,bytes memory _signature) internal  view{
        bytes32 domainHash= ILendFacet(diamond).getDomainHash();
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainHash,
            _hash
        ));
        address signer=IVault(_signer).owner();
        address recoverAddress=ECDSA.recover(digest,_signature);
        require(recoverAddress == signer,"LendModule:signature error");
    }
    //liquidate
    /**
     -debtor  borrow
      _type=true:liqudate collateralAsset
      _type=false:liqudate borrowAsset

     -loaner lender 
        liqudate collateralAsset
     */
    function liquidateOrder(address _debtor,bool _type) external nonReentrant {
          ILendFacet  lendFacet=ILendFacet(diamond);
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          ILendFacet.LendInfo memory lendInfo = ILendFacet(diamond).getDebtorLendInfo(_debtor);
          require(lendInfo.debtor != address(0),"LendModule:lendInfo not exist");
          lendFacet.deleteDebtorLendInfo(_debtor);
          vaultFacet.setVaultLock(_debtor,false);
          address owner=IVault(lendInfo.debtor).owner();  
          address eth=IPlatformFacet(diamond).getEth();     
          if(owner == msg.sender || IOwnable(msg.sender).owner() == owner ){
               if(_type){
                   if(lendInfo.collateralAsset == eth) {
                       IVault(lendInfo.debtor).invokeTransferEth(lendInfo.loaner,lendInfo.collateralAmount);
                   }else{
                       IVault(lendInfo.debtor).invokeTransfer(lendInfo.collateralAsset,lendInfo.loaner,lendInfo.collateralAmount);
                   }             
                   updatePosition(lendInfo.debtor,lendInfo.collateralAsset,1,0);
                   updatePosition(lendInfo.loaner,lendInfo.collateralAsset,1,0);
               }else{
                   //if borrowAsset == eth  repay asset is weth
                   if(lendInfo.borrowAsset == eth){
                       lendInfo.borrowAsset=IPlatformFacet(diamond).getWeth();
                   }
                   IERC20(lendInfo.borrowAsset).safeTransferFrom(lendInfo.recipient,lendInfo.loaner,lendInfo.borrowAmount);                       
                   updatePosition(lendInfo.loaner,lendInfo.borrowAsset,1,0);
               }   
          } else if( lendInfo.maturity <= block.timestamp){    
               if(lendInfo.collateralAsset == eth){
                   IVault(lendInfo.debtor).invokeTransferEth(lendInfo.loaner,lendInfo.collateralAmount);
               }else{
                  IVault(lendInfo.debtor).invokeTransfer(lendInfo.collateralAsset,lendInfo.loaner,lendInfo.collateralAmount);
               }          
               updatePosition(lendInfo.debtor,lendInfo.collateralAsset,1,0);
               updatePosition(lendInfo.loaner,lendInfo.collateralAsset,1,0);
          }else{
              revert("LendModule:liquidate time not yet");
          }
          lendFacet.deleteLoanerLendInfo(lendInfo.loaner,lendInfo.index);
          vaultFacet.setFuncBlackList(lendInfo.loaner,bytes4(keccak256("setVaultType(address,uint256)")),false);
          emit LiquidateOrder(msg.sender,lendInfo);
    }
    function submitStakeOrder(ILendFacet.StakeInfo memory _stakeInfo,bytes calldata _lenderSignature,bytes calldata _borrowerSignature) external nonReentrant{
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          require(vaultFacet.getVaultType(_stakeInfo.borrower) == 7,"LendModule:borrower vaultType error");
          require(vaultFacet.getVaultType(_stakeInfo.lender) == 6,"LendModule:lender vaultType error");
          require(_stakeInfo.recipient != address(0) && _stakeInfo.recipient != _stakeInfo.borrower,"LendModule:recipient error");
          require(_stakeInfo.borrower != _stakeInfo.lender,"LendModule:borrower error");
          require(_stakeInfo.maturity > block.timestamp,"LendModule:invalid maturity");
          require(_stakeInfo.payNowAmount>=_stakeInfo.payLaterMinAmount,"LendModule:payNowAmount error");
          require(_stakeInfo.payLaterAmount>=_stakeInfo.payLaterMinAmount,"LendModule:payLaterAmount error");
          require(IERC20(_stakeInfo.borrowAsset).balanceOf(_stakeInfo.borrower) >= _stakeInfo.borrowAmount,"LendModule:borrowAmount not enough");
          require(IERC20(_stakeInfo.lendAsset).balanceOf(_stakeInfo.lender) >=(_stakeInfo.payNowAmount+_stakeInfo.interestAmount+_stakeInfo.platformFee),"LendModule:lendAmount not enough");
          handleStakeOrder(_stakeInfo.lender,_stakeInfo,_lenderSignature);
          handleStakeOrder(_stakeInfo.borrower,_stakeInfo,_borrowerSignature);
          
          ILendFacet  lendFacet=ILendFacet(diamond);
          //store data
           _stakeInfo.index= lendFacet.getBorrowersLength(_stakeInfo.lender);
           lendFacet.setBorrowerStakeInfo(_stakeInfo.borrower,_stakeInfo);
           lendFacet.setLenderStakeInfo(_stakeInfo.lender,_stakeInfo.borrower);
          //tranfer lendFeePlatformRecipient
          address lendFeePlatformRecipient=lendFacet.getLendFeePlatformRecipient();
          IVault(_stakeInfo.lender).invokeTransfer(_stakeInfo.lendAsset,lendFeePlatformRecipient,_stakeInfo.platformFee);
          //tranfer metamask
          IVault(_stakeInfo.lender).invokeTransfer(_stakeInfo.lendAsset,_stakeInfo.recipient,(_stakeInfo.payNowAmount+_stakeInfo.interestAmount));
          //update position
          updatePosition(_stakeInfo.lender,_stakeInfo.lendAsset,1,0);
          updatePosition(_stakeInfo.borrower,_stakeInfo.borrowAsset,1,0);
          //set CurrentVaultModule
          vaultFacet.setFuncBlackList(_stakeInfo.lender,bytes4(keccak256("setVaultType(address,uint256)")),true);
          vaultFacet.setVaultLock(_stakeInfo.borrower,true);
          emit   SubmitStakeOrder(msg.sender,_stakeInfo);
    }

    function handleStakeOrder(address _signer,ILendFacet.StakeInfo memory _stakeInfo,bytes memory _signature) internal view{
          ILendFacet.StakeInfo memory tempInfo= ILendFacet.StakeInfo({
            orderId:_stakeInfo.orderId,
            borrower:_stakeInfo.borrower,
            lender:_stakeInfo.lender,
            recipient:_stakeInfo.recipient,
            borrowAsset:_stakeInfo.borrowAsset,
            borrowAmount:_stakeInfo.borrowAmount,
            lendAsset:_stakeInfo.lendAsset,
            payNowAmount:_stakeInfo.payNowAmount,
            payNowMinAmount:_stakeInfo.payNowMinAmount,
            interestAmount:_stakeInfo.interestAmount,
            payLaterAmount:_stakeInfo.payLaterAmount,
            payLaterMinAmount:_stakeInfo.payLaterMinAmount,
            maturity:_stakeInfo.maturity,
            platformFee:_stakeInfo.platformFee,
            index:_stakeInfo.index
          });    
        if(_signer == tempInfo.borrower){
            tempInfo.payNowAmount=0;
            tempInfo.payLaterAmount=0;
            tempInfo.lender=address(0);
        }
        bytes32  infoTypeHash = keccak256("StakeInfo(uint256 orderId,address borrower,address lender,address recipient,address borrowAsset,uint256 borrowAmount,address lendAsset,uint256 payNowAmount,uint256 payNowMinAmount,uint256 interestAmount,uint256 payLaterMinAmount,uint256 payLaterAmount,uint256 maturity,uint256 platformFee,uint256 index)");
        bytes32  _hashInfo= keccak256(abi.encode(
            infoTypeHash,
            tempInfo
        ));
        verifySigbature(_signer,_hashInfo,_signature);
    }

    function liquidateStakeOrder(address _borrower,bool _type) external nonReentrant{
           ILendFacet  lendFacet=ILendFacet(diamond);
           IVaultFacet vaultFacet= IVaultFacet(diamond);
           ILendFacet.StakeInfo memory stakeInfo = ILendFacet(diamond).getBorrowerStakeInfo(_borrower);
           require(stakeInfo.borrower != address(0),"LendModule:stakeInfo not exist");
            lendFacet.deleteBorrowerStakeInfo(_borrower);
            vaultFacet.setVaultLock(_borrower,false);
            address owner=IVault(stakeInfo.lender).owner();
            if(msg.sender == owner || msg.sender ==stakeInfo.lender){
                if(_type){
                    //payLater time
                    IERC20(stakeInfo.lendAsset).safeTransferFrom(stakeInfo.recipient,stakeInfo.borrower,stakeInfo.payLaterAmount);
                    IVault(stakeInfo.borrower).invokeTransfer(stakeInfo.borrowAsset,stakeInfo.recipient,stakeInfo.borrowAmount);
                    updatePosition(stakeInfo.lender,stakeInfo.lendAsset,1,0);
                    updatePosition(stakeInfo.lender,stakeInfo.borrowAsset,1,0);
                    updatePosition(stakeInfo.borrower,stakeInfo.borrowAsset,1,0);
                }
            }else if(block.timestamp>stakeInfo.maturity){
                //unlock
            }else{
                revert("LendModule:liquidate time not yet");
            }
            vaultFacet.setFuncBlackList(stakeInfo.lender,bytes4(keccak256("setVaultType(address,uint256)")),false);


          emit LiquidateStakeOrder(msg.sender,stakeInfo);
    }
          
}
