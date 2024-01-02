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
import "./INonfungiblePositionManager.sol";
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

    function verifyPutOrder(ILendFacet.PutOrder memory _putOrder)  internal view{
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          require(!vaultFacet.getVaultLock(_putOrder.borrower),"LendModule:borrower is locked");
          require(!vaultFacet.getVaultLock(_putOrder.lender),"LendModule:lender is locked");
          require(vaultFacet.getVaultType(_putOrder.borrower) == 3,"LendModule:borrower vaultType error");
          require(vaultFacet.getVaultType(_putOrder.lender) == 2,"LendModule:lender vaultType error");
          require(_putOrder.recipient != address(0) && _putOrder.recipient != _putOrder.borrower,"LendModule:recipient error");
          require(_putOrder.lender != _putOrder.borrower,"LendModule:lender error");
          require(_putOrder.expirationDate > block.timestamp,"LendModule:invalid expirationDate");
          require(_putOrder.borrowAmount>=_putOrder.borrowMinAmount,"LendModule:borrowAmount error");
          IPlatformFacet platformFacet=  IPlatformFacet(diamond);
          ILendFacet  lendFacet=ILendFacet(diamond);
          address eth=platformFacet.getEth();
          //verify collateralAsset
          if(_putOrder.collateralAsset == eth){
             require(_putOrder.borrower.balance >= _putOrder.collateralAmount,"LendModule:collateralAmount not enough");
          }else{
             if(_putOrder.collateralAssetType == 0){
                //verify token amount
                require(IERC20(_putOrder.collateralAsset).balanceOf(_putOrder.borrower) >= _putOrder.collateralAmount,"LendModule:collateralAmount not enough");
             }else if(_putOrder.collateralAssetType == 1){
                //verify uniswapv3 nft liquidity
                if(lendFacet.getCollateralNft(_putOrder.collateralAsset) == ILendFacet.CollateralNftType.UniswapV3){
                   (,,address token0,address token1,,,,uint128 liquidity,,,,) =INonfungiblePositionManager(_putOrder.collateralAsset).positions(_putOrder.collateralNftId);
                   require(platformFacet.getTokenType(token0) !=0 && platformFacet.getTokenType(token1) != 0,"LendModule:nft assets error");
                   require(uint256(liquidity) >= _putOrder.collateralAmount,"LendModule:collateralAmount not enough"); 
                }else{
                   revert("LendModule:invalid Nft");  
                }
             }else{
                revert("LendModule:collateralAssetType error"); 
             }     
          }
            //verify borrowAsset
         if(_putOrder.borrowAsset == eth){
              require(_putOrder.lender.balance >= _putOrder.borrowAmount,"LendModule:borrowAmount not enough");
          }else{
              require(IERC20(_putOrder.borrowAsset).balanceOf(_putOrder.lender) >= _putOrder.borrowAmount,"LendModule:borrowAmount not enough");
          }   
    } 

    function handlePutOrder(address _signer,ILendFacet.PutOrder memory _putOrder,bytes memory _signature) internal  view{
        ILendFacet.PutOrder memory tempInfo= ILendFacet.PutOrder({
            orderId:_putOrder.orderId,
            lender:_putOrder.lender,
            borrower:_putOrder.borrower,
            recipient:_putOrder.recipient,
            collateralAsset:_putOrder.collateralAsset,
            collateralAmount:_putOrder.collateralAmount,
            borrowAsset:_putOrder.borrowAsset,
            borrowMinAmount:_putOrder.borrowMinAmount,
            borrowAmount:_putOrder.borrowAmount,
            expirationDate:_putOrder.expirationDate,
            platformFee:_putOrder.platformFee,
            index:_putOrder.index,
            collateralAssetType:_putOrder.collateralAssetType,
            collateralNftId:_putOrder.collateralNftId
        });
        if(_signer == tempInfo.borrower){
            tempInfo.borrowAmount=0;
            tempInfo.lender=address(0);
        }
        bytes32  infoTypeHash = keccak256("PutOrder(uint256 orderId,address lender,address borrower,address recipient,address collateralAsset,uint256 collateralAmount,address borrowAsset,uint256 borrowMinAmount,uint256 borrowAmount,uint256 expirationDate,uint256 platformFee,uint256 index,uint256 collateralAssetType,uint256 collateralNftId)");
        bytes32  _hashInfo= keccak256(abi.encode(
            infoTypeHash,
            tempInfo
        ));
        verifySigbature(_signer,_hashInfo,_signature);
    }


    function submitPutOrder(ILendFacet.PutOrder memory _putOrder,bytes calldata _borrowerSignature,bytes calldata _lenderSignature) external nonReentrant {
          //verify data
          verifyPutOrder(_putOrder);   

          handlePutOrder(_putOrder.borrower,_putOrder,_borrowerSignature);
          handlePutOrder(_putOrder.lender,_putOrder,_lenderSignature);  
          //storage data 
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          address eth=IPlatformFacet(diamond).getEth();
         
          vaultFacet.setVaultLock(_putOrder.borrower,true);
          ILendFacet  lendFacet=ILendFacet(diamond);
        
          _putOrder.index=lendFacet.getLenderPutOrderLength(_putOrder.lender);
          lendFacet.setBorrowerPutOrder(_putOrder.borrower,_putOrder);
          lendFacet.setLenderPutOrder(_putOrder.lender,_putOrder.borrower);
          //tranfer lendFeePlatformRecipient
          address lendFeePlatformRecipient=lendFacet.getLendFeePlatformRecipient();
          
          if(_putOrder.borrowAsset == eth){
            if(lendFeePlatformRecipient != address(0)){
                IVault(_putOrder.lender).invokeTransferEth(lendFeePlatformRecipient,_putOrder.platformFee);
             }     
             IVault(_putOrder.lender).invokeTransferEth(_putOrder.recipient,_putOrder.borrowAmount-_putOrder.platformFee);
          }else{
            if(lendFeePlatformRecipient != address(0)){
                 IVault(_putOrder.lender).invokeTransfer(_putOrder.borrowAsset,lendFeePlatformRecipient,_putOrder.platformFee);
            }   
            //tranfer metamask
            IVault(_putOrder.lender).invokeTransfer(_putOrder.borrowAsset,_putOrder.recipient,_putOrder.borrowAmount-_putOrder.platformFee);
          }
          updatePosition(_putOrder.lender,_putOrder.borrowAsset,0);
          //set CurrentVaultModule
          setFuncBlackAndWhiteList(1,_putOrder.lender,_putOrder.borrower,true);
        //   vaultFacet.setFuncBlackList(_lendInfo.loaner,bytes4(keccak256("setVaultType(address,uint256)")),true);
        //   vaultFacet.setFuncWhiteList(_lendInfo.debtor,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),true);
          emit SubmitPutOrder(msg.sender,_putOrder);      
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
    function liquidatePutOrder(address _borrower,bool _type) external payable nonReentrant {
          ILendFacet  lendFacet=ILendFacet(diamond);
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          ILendFacet.PutOrder memory putOrder = ILendFacet(diamond).getBorrowerPutOrder(_borrower);
          require(putOrder.borrower != address(0),"LendModule:putOrder not exist");
          lendFacet.deleteBorrowerPutOrder(putOrder.borrower);
          vaultFacet.setVaultLock(putOrder.borrower,false);
          address owner=IVault(putOrder.borrower).owner();  
          if(owner == msg.sender ||  (IPlatformFacet(diamond).getIsVault(msg.sender) && IOwnable(msg.sender).owner() == owner) ){
               if(_type){
                   liquidate(putOrder,1);            
               }else{
                   liquidate(putOrder,2);   
               }   
          } else if( putOrder.expirationDate <= block.timestamp){    
                 liquidate(putOrder,1);
          }else{
              revert("LendModule:liquidate time not yet");
          }
          lendFacet.deleteLenderPutOrder(putOrder.lender,putOrder.index);
          setFuncBlackAndWhiteList(1,putOrder.lender,putOrder.borrower,false);
        //   vaultFacet.setFuncBlackList(putOrder.loaner,bytes4(keccak256("setVaultType(address,uint256)")),false);
        //   vaultFacet.setFuncWhiteList(putOrder.debtor,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),false);
          emit LiquidatePutOrder(msg.sender,putOrder);
    }
    function liquidate(ILendFacet.PutOrder memory _putOrder,uint256 _liquidateWay) internal  {   
        address eth=IPlatformFacet(diamond).getEth();     
         if(_liquidateWay==1){
            if(_putOrder.collateralAsset == eth){
                IVault(_putOrder.borrower).invokeTransferEth(_putOrder.lender,_putOrder.collateralAmount);
            }else{
                if(_putOrder.collateralAssetType ==0){
                    //transfer token
                    // IVault(_putOrder.debtor).invokeTransfer(_putOrder.collateralAsset,_putOrder.loaner,_putOrder.collateralAmount);
                    uint256 balance=IERC20(_putOrder.collateralAsset).balanceOf(_putOrder.borrower);
                    require(balance>=_putOrder.collateralAmount,"LendModule:balance error");
                    IVault(_putOrder.borrower).invokeTransfer(_putOrder.collateralAsset,_putOrder.lender,balance);
                }else if(_putOrder.collateralAssetType ==1){
                    //transfer nft  
                    IVault(_putOrder.borrower).invokeTransferNft(_putOrder.collateralAsset,_putOrder.lender,_putOrder.collateralNftId); 
                }else{
                    revert("LendModule:collateralAssetType error"); 
                } 
                updatePosition(_putOrder.borrower,_putOrder.collateralAsset,0);
                updatePosition(_putOrder.lender,_putOrder.collateralAsset,0);
            }  
          }else if(_liquidateWay==2){
                  //if borrowAsset == eth  repay asset is weth
                   if( _putOrder.borrowAsset == eth  && msg.value >= _putOrder.borrowAmount){
                      (bool success,)=_putOrder.recipient.call{value:_putOrder.borrowAmount}("");
                      require(success,"LendModule:trafer eth fail");
                   }else{
                        if(_putOrder.borrowAsset == eth){
                            _putOrder.borrowAsset=IPlatformFacet(diamond).getWeth();
                        }
                        IERC20(_putOrder.borrowAsset).safeTransferFrom(_putOrder.recipient,_putOrder.lender,_putOrder.borrowAmount); 
                   }             
                   updatePosition(_putOrder.lender,_putOrder.borrowAsset,1,0);
          }else{
                revert("LendModule:liquidateWay error"); 
          }
    }
    //--------------
    function verifyCallOrder(ILendFacet.CallOrder memory _callOrder) internal view{
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          require(!vaultFacet.getVaultLock(_callOrder.borrower),"LendModule:borrower is locked");
          require(!vaultFacet.getVaultLock(_callOrder.lender),"LendModule:lender is locked");
          require(vaultFacet.getVaultType(_callOrder.borrower) == 7,"LendModule:borrower vaultType error");
          require(vaultFacet.getVaultType(_callOrder.lender) == 6,"LendModule:lender vaultType error");
          require(_callOrder.recipient != address(0) && _callOrder.recipient != _callOrder.borrower,"LendModule:recipient error");
          require(_callOrder.borrower != _callOrder.lender,"LendModule:borrower error");
          require(_callOrder.expirationDate > block.timestamp,"LendModule:invalid expirationDate");
          require(_callOrder.borrowNowAmount>=_callOrder.borrowNowMinAmount,"LendModule:borrowNowAmount error");
          require(_callOrder.borrowLaterAmount>=_callOrder.borrowLaterMinAmount,"LendModule:borrowLaterAmount error");
          IPlatformFacet platformFacet=  IPlatformFacet(diamond);
          ILendFacet  lendFacet=ILendFacet(diamond);
          address eth=platformFacet.getEth();
          //verify collateralAsset
          if(_callOrder.collateralAsset == eth){
               require(_callOrder.lender.balance >= _callOrder.collateralAmount,"LendModule:collateralAmount not enough");
          }else{
               if(_callOrder.collateralAssetType == 0){
                   require(IERC20(_callOrder.collateralAsset).balanceOf(_callOrder.lender) >= _callOrder.collateralAmount,"LendModule:collateralAmount not enough");
               }else if(_callOrder.collateralAssetType == 1){
                 //verify uniswapv3 nft liquidity
                if(lendFacet.getCollateralNft(_callOrder.collateralAsset) == ILendFacet.CollateralNftType.UniswapV3){
                   (,,address token0,address token1,,,,uint128 liquidity,,,,) =INonfungiblePositionManager(_callOrder.collateralAsset).positions(_callOrder.collateralNftId);
                   require(platformFacet.getTokenType(token0) !=0 && platformFacet.getTokenType(token1) != 0,"LendModule:nft assets error");
                   require(uint256(liquidity) >= _callOrder.collateralAmount,"LendModule:collateralAmount not enough"); 
                }else{
                   revert("LendModule:invalid Nft");  
                }  
               }else{
                  revert("LendModule:collateralAssetType error"); 
               }
          }
           //verify lendAsset
          if(_callOrder.borrowAsset == eth){
              require(_callOrder.borrower.balance >= (_callOrder.borrowNowAmount+_callOrder.interestAmount+_callOrder.platformFee),"LendModule:borrowAmount not enough");
          }else{
              require(IERC20(_callOrder.borrowAsset).balanceOf(_callOrder.borrower) >=(_callOrder.borrowNowAmount+_callOrder.interestAmount+_callOrder.platformFee),"LendModule:borrowAmount not enough");
          }     
    }

    function handleCallOrderr(address _signer,ILendFacet.CallOrder memory _callOrder,bytes memory _signature) internal view{
          ILendFacet.CallOrder memory tempInfo= ILendFacet.CallOrder({
            orderId:_callOrder.orderId,
            borrower:_callOrder.borrower,
            lender:_callOrder.lender,
            recipient:_callOrder.recipient,
            collateralAsset:_callOrder.collateralAsset,
            collateralAmount:_callOrder.collateralAmount,
            borrowAsset:_callOrder.borrowAsset,
            borrowNowAmount:_callOrder.borrowNowAmount,
            borrowNowMinAmount:_callOrder.borrowNowMinAmount,
            interestAmount:_callOrder.interestAmount,
            borrowLaterMinAmount:_callOrder.borrowLaterMinAmount,
            borrowLaterAmount:_callOrder.borrowLaterAmount,
            expirationDate:_callOrder.expirationDate,
            platformFee:_callOrder.platformFee,
            index:_callOrder.index,
            collateralAssetType:_callOrder.collateralAssetType,
            collateralNftId:_callOrder.collateralNftId
          });    
        if(_signer == tempInfo.borrower){
            tempInfo.borrowNowAmount=0;
            tempInfo.borrowLaterAmount=0;
            tempInfo.lender=address(0);
        }
        bytes32  infoTypeHash = keccak256("CallOrder(uint256 orderId,address borrower,address lender,address recipient,address collateralAsset,uint256 collateralAmount,address borrowAsset,uint256 borrowNowAmount,uint256 borrowNowMinAmount,uint256 interestAmount,uint256 borrowLaterMinAmount,uint256 borrowLaterAmount,uint256 expirationDate,uint256 platformFee,uint256 index,uint256 collateralAssetType,uint256 collateralNftId)");
        bytes32  _hashInfo= keccak256(abi.encode(
            infoTypeHash,
            tempInfo
        ));
        verifySigbature(_signer,_hashInfo,_signature);
    }


    function submitCallOrder(ILendFacet.CallOrder memory _callOrder,bytes calldata _borrowerSignature,bytes calldata _lenderSignature) external nonReentrant{
          verifyCallOrder(_callOrder);
          IVaultFacet vaultFacet= IVaultFacet(diamond);    
          handleCallOrderr(_callOrder.lender,_callOrder,_lenderSignature);
          handleCallOrderr(_callOrder.borrower,_callOrder,_borrowerSignature);       
          ILendFacet  lendFacet=ILendFacet(diamond);
          //store data
          _callOrder.index= lendFacet.getBorrowerCallOrderLength(_callOrder.borrower);
          lendFacet.setLenderCallOrder(_callOrder.lender,_callOrder);
          lendFacet.setBorrowerCallOrder(_callOrder.borrower,_callOrder.lender);
          //tranfer lendFeePlatformRecipient
          address lendFeePlatformRecipient=lendFacet.getLendFeePlatformRecipient();
          IPlatformFacet platformFacet= IPlatformFacet(diamond);
          address eth=platformFacet.getEth();
          if(_callOrder.borrowAsset ==eth){
               if(lendFeePlatformRecipient !=address(0)){
                   IVault(_callOrder.borrower).invokeTransferEth(lendFeePlatformRecipient,_callOrder.platformFee);
               }  
               IVault(_callOrder.borrower).invokeTransferEth(_callOrder.recipient,(_callOrder.borrowNowAmount+_callOrder.interestAmount));
          }else{
                if(lendFeePlatformRecipient !=address(0)){
                    IVault(_callOrder.borrower).invokeTransfer(_callOrder.borrowAsset,lendFeePlatformRecipient,_callOrder.platformFee);
                }         
                 //tranfer metamask
                IVault(_callOrder.borrower).invokeTransfer(_callOrder.borrowAsset,_callOrder.recipient,(_callOrder.borrowNowAmount+_callOrder.interestAmount));
          } 
          //update position
          updatePosition(_callOrder.borrower,_callOrder.borrowAsset,1,0);
          //set CurrentVaultModule
          setFuncBlackAndWhiteList(2,_callOrder.borrower,_callOrder.lender,true);
          vaultFacet.setVaultLock(_callOrder.lender,true);
          emit   SubmitCallOrder(msg.sender,_callOrder);
    }



    function liquidateCallOrder(address _lender,bool _type) external payable nonReentrant{
            ILendFacet  lendFacet=ILendFacet(diamond);
            IVaultFacet vaultFacet= IVaultFacet(diamond);
            ILendFacet.CallOrder memory callOrder = ILendFacet(diamond).getLenderCallOrder(_lender);
            require(callOrder.lender != address(0),"LendModule:callOrder not exist");

            lendFacet.deleteLenderCallOrder(callOrder.lender);
            vaultFacet.setVaultLock(callOrder.lender,false);
            IPlatformFacet platformFacet= IPlatformFacet(diamond);
            address owner=IVault(callOrder.borrower).owner();
            address eth=platformFacet.getEth();
            if(msg.sender == owner || (IPlatformFacet(diamond).getIsVault(msg.sender) && IOwnable(msg.sender).owner() == owner)){
                if(_type){
                    //payLater time
                    //traferFrom borrowAsset to lender
                    if(callOrder.borrowAsset == eth){
                        IVault(callOrder.borrower).invokeTransferEth(callOrder.recipient,callOrder.borrowLaterAmount);
                    }else{
                        IERC20(callOrder.borrowAsset).safeTransferFrom(callOrder.borrower,callOrder.recipient,callOrder.borrowLaterAmount);
                    }                   
                    //tanferFrom collateralAsset to borrower
                    if(callOrder.collateralAssetType == 0){
                        if(callOrder.collateralAsset == eth){
                           IVault(callOrder.lender).invokeTransferEth(callOrder.borrower,callOrder.collateralAmount);
                        }else{
                           uint256 balance= IERC20(callOrder.collateralAsset).balanceOf(callOrder.lender);  
                           IVault(callOrder.lender).invokeTransfer(callOrder.collateralAsset,callOrder.borrower,balance);
                        }                   
                    }else if(callOrder.collateralAssetType == 1){
                         IVault(callOrder.lender).invokeTransferNft(callOrder.collateralAsset,callOrder.borrower,callOrder.collateralNftId);   
                    }else{
                        revert("LendModule:collateralAssetType error");
                    }  
                    updatePosition(callOrder.borrower,callOrder.borrowAsset,0);
                    updatePosition(callOrder.lender,callOrder.collateralAsset,0);
                    updatePosition(callOrder.borrower,callOrder.collateralAsset,0);
                }
            }else if(block.timestamp>callOrder.expirationDate){
                //unlock
            }else{
                revert("LendModule:liquidate time not yet");
            }
            setFuncBlackAndWhiteList(2,callOrder.borrower,callOrder.lender,false);
            emit LiquidateCallOrder(msg.sender,callOrder);
    }
    function setFuncBlackAndWhiteList(uint256 _orderType,address _blacker,address _whiter,bool _type) internal{
         IVaultFacet vaultFacet= IVaultFacet(diamond);
         ILendFacet  lendFacet=ILendFacet(diamond);
         if((_orderType==1 && lendFacet.getLenderPutOrderLength(_blacker)==0) || (_orderType==2 && lendFacet.getBorrowerCallOrderLength(_blacker)==0)){        
              vaultFacet.setFuncBlackList(_blacker,bytes4(keccak256("setVaultType(address,uint256)")),_type);
         }    
         vaultFacet.setFuncWhiteList(_whiter,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),_type);
         vaultFacet.setFuncWhiteList(_whiter,bytes4(keccak256("liquidateStakeOrder(address,bool)")),_type);
    }                
}
