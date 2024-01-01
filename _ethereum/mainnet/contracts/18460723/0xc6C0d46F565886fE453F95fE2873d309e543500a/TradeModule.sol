// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ModuleBase.sol";
import "./IExchangeAdapter.sol";
import "./ITradeModule.sol";
import "./IOwnable.sol";
import "./Invoke.sol";
contract TradeModule is ModuleBase,ITradeModule, Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable{
    using Invoke for IVault; 
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

    //trade  
    function trade(
        address _vault,
        TradeInfo[] memory _tradeInfos  
    ) external nonReentrant onlyVault(_vault){
        IPlatformFacet platformFacet=IPlatformFacet(diamond);
        IVaultFacet vaultFacet=IVaultFacet(diamond);
        for(uint256 i;i<_tradeInfos.length;i++){
            address IPlatformAdapter = platformFacet.getModuleToProtocolA(address(this),_tradeInfos[i].protocol); 
            //check protocol in platform  
            require(IPlatformAdapter !=address(0),"TradeModule:protocol must be platform allowed");
            //check protocol in vault
            require(vaultFacet.getVaultProtocolStatus(address(_vault),IPlatformAdapter),"TradeModule:protocol must be vault allowed"); 
             
            //check asset in platform
            uint256 sendAssetType=platformFacet.getTokenType(_tradeInfos[i].sendAsset);
            uint256 receiveAssetType= platformFacet.getTokenType(_tradeInfos[i].receiveAsset);
            require(sendAssetType !=0 && receiveAssetType!=0 && sendAssetType== _tradeInfos[i].positionType && receiveAssetType == _tradeInfos[i].positionType,"TradeModule:asset must be platform allowed");
                
            //check asset in vault
            sendAssetType=vaultFacet.getVaultTokenType(_vault, _tradeInfos[i].sendAsset);
            receiveAssetType=vaultFacet.getVaultTokenType(_vault, _tradeInfos[i].receiveAsset);
            require(sendAssetType !=0 && receiveAssetType!=0 && sendAssetType== _tradeInfos[i].positionType && receiveAssetType == _tradeInfos[i].positionType,"TradeModule:asset must be vault allowed");
            //excute
            excute(_vault,IPlatformAdapter,_tradeInfos[i]);
        }
        emit Trade(_vault,_tradeInfos);
    }

    //excute
    function excute(address _vault,address _adapter,TradeInfo memory tradeInfo) internal {
           IVault vault=IVault(_vault);
           IPlatformFacet platformFacet=IPlatformFacet(diamond);
           address eth=platformFacet.getEth();
           //
            address sendAsset=tradeInfo.sendAsset==eth? platformFacet.getWeth():tradeInfo.sendAsset;
            address receiveAsset=tradeInfo.receiveAsset==eth? platformFacet.getWeth():tradeInfo.receiveAsset;
            if(tradeInfo.amountIn == 0){
                if(tradeInfo.sendAsset==eth){
                    tradeInfo.amountIn=_vault.balance;
                }else{
                    tradeInfo.amountIn=IERC20(sendAsset).balanceOf(_vault);
                }    
            }

            if(tradeInfo.approveAmount == 0){
                if(tradeInfo.sendAsset==eth){
                    tradeInfo.approveAmount=_vault.balance;
                }else{
                    tradeInfo.approveAmount=IERC20(sendAsset).balanceOf(_vault);
                }                    
            }
            IExchangeAdapter.AdapterCalldata memory adapterCalldata   = IExchangeAdapter(_adapter).getAdapterCallData(
            _vault, sendAsset, receiveAsset,tradeInfo.adapterType,tradeInfo.amountIn,tradeInfo.amountLimit, tradeInfo.adapterData); 
            //call                 
            if(tradeInfo.sendAsset !=eth ){
              vault.invokeApprove(tradeInfo.sendAsset, adapterCalldata.spender,tradeInfo.approveAmount);
            }
            vault.execute(adapterCalldata.target, adapterCalldata.value, adapterCalldata.data);       
            //update position
            updatePosition(_vault,tradeInfo.sendAsset,tradeInfo.positionType,0);
            updatePosition(_vault,tradeInfo.receiveAsset,tradeInfo.positionType,0);
    }

}