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

    function verifyLendInfo(ILendFacet.LendInfo memory _lendInfo)  internal view{
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          require(vaultFacet.getVaultType(_lendInfo.debtor) == 3,"LendModule:debtor vaultType error");
          require(vaultFacet.getVaultType(_lendInfo.loaner) == 2,"LendModule:loaner vaultType error");
          require(_lendInfo.recipient != address(0) && _lendInfo.recipient != _lendInfo.debtor,"LendModule:recipient error");
          require(_lendInfo.loaner != _lendInfo.debtor,"LendModule:loaner error");
          require(_lendInfo.maturity > block.timestamp,"LendModule:invalid maturity");
          require(_lendInfo.borrowAmount>=_lendInfo.borrowMinAmount,"LendModule:borrowAmount error");
          IPlatformFacet platformFacet=  IPlatformFacet(diamond);
          ILendFacet  lendFacet=ILendFacet(diamond);
          address eth=platformFacet.getEth();
          //verify collateralAsset
          if(_lendInfo.collateralAsset == eth){
             require(_lendInfo.debtor.balance >= _lendInfo.collateralAmount,"LendModule:collateralAmount not enough");
          }else{
             if(_lendInfo.collateralAssetType == 0){
                //verify token amount
                require(IERC20(_lendInfo.collateralAsset).balanceOf(_lendInfo.debtor) >= _lendInfo.collateralAmount,"LendModule:collateralAmount not enough");
             }else if(_lendInfo.collateralAssetType == 1){
                //verify uniswapv3 nft liquidity
                if(lendFacet.getCollateralNft(_lendInfo.collateralAsset) == ILendFacet.CollateralNftType.UniswapV3){
                   (,,address token0,address token1,,,,uint128 liquidity,,,,) =INonfungiblePositionManager(_lendInfo.collateralAsset).positions(_lendInfo.collateralNftId);
                   require(platformFacet.getTokenType(token0) !=0 && platformFacet.getTokenType(token1) != 0,"LendModule:nft assets error");
                   require(uint256(liquidity) >= _lendInfo.collateralAmount,"LendModule:collateralAmount not enough"); 
                }else{
                   revert("LendModule:invalid Nft");  
                }
             }else{
                revert("LendModule:collateralAssetType error"); 
             }     
          }
            //verify borrowAsset
         if(_lendInfo.borrowAsset == eth){
              require(_lendInfo.loaner.balance >= _lendInfo.borrowAmount,"LendModule:borrowAmount not enough");
          }else{
              require(IERC20(_lendInfo.borrowAsset).balanceOf(_lendInfo.loaner) >= _lendInfo.borrowAmount,"LendModule:borrowAmount not enough");
          }   
    } 

    function submitOrder(ILendFacet.LendInfo memory _lendInfo,bytes calldata _debtorSignature,bytes calldata _loanerSignature) external nonReentrant {
          //verify data
          verifyLendInfo(_lendInfo);   
          handleOrder(_lendInfo.debtor,_lendInfo,_debtorSignature);
          handleOrder(_lendInfo.loaner,_lendInfo,_loanerSignature);  
          //storage data 
          IVaultFacet vaultFacet= IVaultFacet(diamond);
          address eth=IPlatformFacet(diamond).getEth();
         
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
          updatePosition(_lendInfo.loaner,_lendInfo.borrowAsset,0);
          //set CurrentVaultModule
          setFuncBlackAndWhiteList(_lendInfo.loaner,_lendInfo.debtor,true);
        //   vaultFacet.setFuncBlackList(_lendInfo.loaner,bytes4(keccak256("setVaultType(address,uint256)")),true);
        //   vaultFacet.setFuncWhiteList(_lendInfo.debtor,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),true);
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
            collateralNftId:_lendInfo.collateralNftId
        });
        if(_signer == tempInfo.debtor){
            tempInfo.borrowAmount=0;
            tempInfo.loaner=address(0);
        }
        bytes32  infoTypeHash = keccak256("LendInfo(uint256 orderId,address loaner,address debtor,address recipient,address collateralAsset,uint256 collateralAmount,address borrowAsset,uint256 borrowMinAmount,uint256 borrowAmount,uint256 maturity,uint256 platformFee,uint256 index,uint256 collateralAssetType,uint256 collateralNftId)");
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
          if(owner == msg.sender ||  (IPlatformFacet(diamond).getIsVault(msg.sender) && IOwnable(msg.sender).owner() == owner) ){
               if(_type){
                   liquidate(lendInfo,1);            
               }else{
                   liquidate(lendInfo,2);   
               }   
          } else if( lendInfo.maturity <= block.timestamp){    
                 liquidate(lendInfo,1);
          }else{
              revert("LendModule:liquidate time not yet");
          }
          lendFacet.deleteLoanerLendInfo(lendInfo.loaner,lendInfo.index);
          setFuncBlackAndWhiteList(lendInfo.loaner,lendInfo.debtor,false);
        //   vaultFacet.setFuncBlackList(lendInfo.loaner,bytes4(keccak256("setVaultType(address,uint256)")),false);
        //   vaultFacet.setFuncWhiteList(lendInfo.debtor,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),false);
          emit LiquidateOrder(msg.sender,lendInfo);
    }
    function liquidate(ILendFacet.LendInfo memory lendInfo,uint256 _liquidateWay) internal {   
        address eth=IPlatformFacet(diamond).getEth();     
         if(_liquidateWay==1){
            if(lendInfo.collateralAsset == eth){
                IVault(lendInfo.debtor).invokeTransferEth(lendInfo.loaner,lendInfo.collateralAmount);
            }else{
                if(lendInfo.collateralAssetType ==0){
                    //transfer token
                    // IVault(lendInfo.debtor).invokeTransfer(lendInfo.collateralAsset,lendInfo.loaner,lendInfo.collateralAmount);
                    uint256 balance=IERC20(lendInfo.collateralAsset).balanceOf(lendInfo.debtor);
                    require(balance>=lendInfo.collateralAmount,"LendModule:balance error");
                    IVault(lendInfo.debtor).invokeTransfer(lendInfo.collateralAsset,lendInfo.loaner,balance);
                }else if(lendInfo.collateralAssetType ==1){
                    //transfer nft  
                    IVault(lendInfo.debtor).invokeTransferNft(lendInfo.collateralAsset,lendInfo.loaner,lendInfo.collateralNftId); 
                }else{
                    revert("LendModule:collateralAssetType error"); 
                } 
                updatePosition(lendInfo.debtor,lendInfo.collateralAsset,0);
                updatePosition(lendInfo.loaner,lendInfo.collateralAsset,0);
            }  
          }else if(_liquidateWay==2){
                 //if borrowAsset == eth  repay asset is weth
                   if(lendInfo.borrowAsset == eth){
                       lendInfo.borrowAsset=IPlatformFacet(diamond).getWeth();
                   }
                   IERC20(lendInfo.borrowAsset).safeTransferFrom(lendInfo.recipient,lendInfo.loaner,lendInfo.borrowAmount);                       
                   updatePosition(lendInfo.loaner,lendInfo.borrowAsset,1,0);
          }else{
                revert("LendModule:liquidateWay error"); 
          }
    }
    //-------replacementLiquidity-------
    function replacementLiquidity(address _holder,ReplacementLiquidityType _type,uint24 _fee,int24 _tickLower,int24 _tickUpper) external  nonReentrant onlyVault(_holder){
         uint256 tokenId;
         uint128 newLiquidity;
         int24[2] memory  priceSection=[int24(_tickLower),_tickUpper];
         if(_type==ReplacementLiquidityType.Default){
            ILendFacet.LendInfo memory lendInfo = ILendFacet(diamond).getDebtorLendInfo(_holder);
            require(lendInfo.debtor != address(0),"LendModule:lendInfo not exist");
            require(lendInfo.collateralAssetType==1,"LendModule:collateralAssetType error"); 
            (tokenId,newLiquidity)= mintNewNft(lendInfo.debtor,lendInfo.collateralAsset,lendInfo.collateralNftId,_fee,priceSection);
            ILendFacet(diamond).setDebtorLendInfoNftInfo(lendInfo.debtor,tokenId,uint256(newLiquidity));
            emit ReplacementLiquidity(_type,lendInfo.debtor,_fee,_tickLower,_tickUpper, tokenId,newLiquidity);
         }else if(_type==ReplacementLiquidityType.Stake){
            ILendFacet.StakeInfo memory stakeInfo = ILendFacet(diamond).getBorrowerStakeInfo(_holder);
            require(stakeInfo.borrower != address(0),"LendModule:stakeInfo not exist");
            require(stakeInfo.borrowAssetType==1,"LendModule:collateralAssetType error");
            (tokenId,newLiquidity)= mintNewNft(stakeInfo.borrower,stakeInfo.borrowAsset,stakeInfo.borrowNftId,_fee,priceSection);
            ILendFacet(diamond).setBorrowerStakeInfoNftInfo(stakeInfo.borrower,tokenId,uint256(newLiquidity));
            emit ReplacementLiquidity(_type,stakeInfo.borrower,_fee,_tickLower,_tickUpper, tokenId,newLiquidity);
         }else{
            revert("LendModule:ReplacementLiquidityType error");
         } 
    }

    function burnOldNft(address _holder,address _nft,uint256 _nftId) internal returns(address[2] memory){
        INonfungiblePositionManager nonfungiblePositionManager= INonfungiblePositionManager(_nft);
        (,,address token0,address token1,,,,uint128 liquidity,,,,)=nonfungiblePositionManager.positions(_nftId);
        //transferFrom nft to current contract
        IVaultFacet(diamond).setFuncWhiteList(_holder,bytes4(keccak256("transferFrom(address,address,uint256)")),true);
        IVault(_holder).invokeTransferNft(_nft,address(this), _nftId);
        IVaultFacet(diamond).setFuncBlackList(_holder,bytes4(keccak256("transferFrom(address,address,uint256)")),false);

        //decreaseLiquidity
        nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId:_nftId, 
            liquidity:liquidity,
            amount0Min:0, 
            amount1Min:0,
            deadline:block.timestamp      
        }));
        //collect interest
        nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId:_nftId,
            recipient:address(this),
            amount0Max:type(uint128).max,
            amount1Max:type(uint128).max
        }));

        //burn nft
        nonfungiblePositionManager.burn(_nftId); 
        address[2] memory tokens=[token0,token1];
        return tokens;
    }
    function mintNewNft(address _holder,address _nft,uint256 _nftId, uint24 _fee,int24[2] memory priceSection)  internal returns(uint256,uint128){
        address[2] memory  tokens=  burnOldNft(_holder,_nft,_nftId);
        uint256[2] memory amountDesireds=[uint256(0),0];
        amountDesireds[0]=IERC20(tokens[0]).balanceOf(address(this));
        amountDesireds[1]=IERC20(tokens[1]).balanceOf(address(this));
        IERC20(tokens[0]).approve(_nft,amountDesireds[0]);
        IERC20(tokens[1]).approve(_nft,amountDesireds[1]);
        INonfungiblePositionManager nonfungiblePositionManager= INonfungiblePositionManager(_nft);
        (uint256 tokenId,uint128 newLiquidity,,)=nonfungiblePositionManager.mint(INonfungiblePositionManager.MintParams({
            token0:tokens[0],
            token1:tokens[1],
            fee:_fee,
            tickLower:priceSection[0],
            tickUpper:priceSection[1],
            amount0Desired:amountDesireds[0],
            amount1Desired:amountDesireds[1],
            amount0Min:0,
            amount1Min:0,
            recipient:_holder,
            deadline:block.timestamp
        }));
        return (tokenId,newLiquidity);
    }  
    function setFuncBlackAndWhiteList(address _blacker,address _whiter,bool _type) internal{
         IVaultFacet vaultFacet= IVaultFacet(diamond);
         vaultFacet.setFuncBlackList(_blacker,bytes4(keccak256("setVaultType(address,uint256)")),_type);
         vaultFacet.setFuncWhiteList(_whiter,bytes4(keccak256("replacementLiquidity(address,uint8,uint24,int24,int24)")),_type);
         vaultFacet.setFuncWhiteList(_whiter,bytes4(keccak256("liquidateOrder(address,bool)")),_type);
    }
    //----setting------
    function setCollateralNft(address _nft,ILendFacet.CollateralNftType _type) external onlyOwner{
        ILendFacet(diamond).setCollateralNft(_nft,_type);
    }  
    function setLendFeePlatformRecipient(address _recipient) public onlyOwner {
         ILendFacet(diamond).setLendFeePlatformRecipient(_recipient);
    }
     function setDomainHash(string memory _name,string memory _version,address _contract) public onlyOwner{
        bytes32  DomainInfoTypeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        bytes32  _domainHash= keccak256(abi.encode(
              DomainInfoTypeHash,
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                block.chainid,
               _contract
        ));
        ILendFacet(diamond).setDomainHash(_domainHash);
    }
                 
}
