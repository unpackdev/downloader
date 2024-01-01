// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IOwnable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IVaultFacet.sol";
import "./IPlatformFacet.sol";
import "./ILendFacet.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IDiamond.sol";
import "./IPaymasterFacet.sol";
contract Manager is  Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable{
    address public diamond; 
    event TransferOwnership(address _newOwner);
    modifier onlyOwner() {
        require(
            msg.sender == IOwnable(diamond).owner(),
            "Quoter:only owner"
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
    //-----------write--------------------
    function setPayer(address _payer) external onlyOwner{
       IPaymasterFacet(diamond).setPayer(_payer);
    }
    function setWethAndEth(address _weth,address _eth) external onlyOwner{
       IPlatformFacet(diamond).setWeth(_weth);
       IPlatformFacet(diamond).setEth(_eth);   
    }

    function setModules(address[] memory _modules,bool[] memory _status) external onlyOwner{
       IPlatformFacet(diamond).setModules(_modules, _status);
    }


   function setProtocols(address _module,string[] memory _protocols,address[] memory _protocolAddrs) external onlyOwner{
        IPlatformFacet(diamond).setProtocols(_module, _protocols,_protocolAddrs);
   } 

   function setTokens(address[] memory _tokens,uint256[] memory _tokenTypes) external onlyOwner{
        IPlatformFacet(diamond).setTokens(_tokens, _tokenTypes);
   }

   function setDBControlWhitelist(address[] memory _modules,bool[] memory _status) external onlyOwner{
        IOwnable(diamond).setDBControlWhitelist(_modules,_status);
   }

   function transferOwnership(address _newOwner) external onlyOwner{
        require(_newOwner != address(0),"invalid address");
        IOwnable(diamond).transferOwnership(_newOwner);
        emit TransferOwnership(_newOwner);
   }
   function getSelector(string memory _func) internal pure returns(bytes4){
         return bytes4(keccak256(bytes(_func)));
   }

   function diamondCut(address _facetAddress,string[] memory _addSelectors,string[] memory _removeSelectors,address _init,bytes memory _calldata)  external onlyOwner{  
         bytes4[] memory addSelectors=new  bytes4[](_addSelectors.length);
         bytes4[] memory removeSelectors=new  bytes4[](_removeSelectors.length);
         for(uint i;i<_addSelectors.length;i++){
             addSelectors[i]=getSelector(_addSelectors[i]);
         }
         for(uint i;i<_removeSelectors.length;i++){
             removeSelectors[i]=getSelector(_removeSelectors[i]);
         }
         IDiamond.FacetCut[] memory  _diamondCut=new IDiamond.FacetCut[](1);   
         _diamondCut[0]= IDiamond.FacetCut({
             facetAddress:_facetAddress,
             addSelectors:addSelectors,
             removeSelectors:removeSelectors
         }); 
         IDiamondCut(diamond).diamondCut(_diamondCut, _init, _calldata);
   }

   function deleteFacetAllSelector(address _facetAddress) external onlyOwner{
       bytes4[] memory removeSelectors=IDiamondLoupe(diamond).facetFunctionSelectors(_facetAddress);
       require(removeSelectors.length >0,"facetAddress not exist");
       bytes4[] memory addSelectors=new  bytes4[](0);
       IDiamond.FacetCut[] memory  _diamondCut=new IDiamond.FacetCut[](1);   
         _diamondCut[0]= IDiamond.FacetCut({
             facetAddress:_facetAddress,
             addSelectors:addSelectors,
             removeSelectors:removeSelectors
         }); 
         IDiamondCut(diamond).diamondCut(_diamondCut, address(0),new bytes(0));
   }
   //--------------view---------------------

    function multiCall(
        address[] calldata targets,
        bytes[] calldata data
    ) external view returns (bytes[] memory) {
        require(targets.length == data.length, "target length != data length");

        bytes[] memory results = new bytes[](data.length);

        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].staticcall(data[i]);
            require(success, "call failed");
            results[i] = result;
        }
        return results;
    }


    function facets() external view returns (IDiamondLoupe.Facet[] memory facets_){
         return IDiamondLoupe(diamond).facets();
     }  
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_){
         return IDiamondLoupe(diamond).facetFunctionSelectors(_facet);
    }

    function facetAddresses() external view returns (address[] memory facetAddresses_){
         return IDiamondLoupe(diamond).facetAddresses();
    }

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_){
         return IDiamondLoupe(diamond).facetAddress(_functionSelector);
    }

     function getDBControlWhitelist(address _module) external view returns(bool){
         return  IOwnable(diamond).getDBControlWhitelist(_module);
     }
    //-----------
    function getVaultAllPosition(address _vault,uint16[] memory _positionTypes) external view returns(IVaultFacet.Position[] memory positions,uint256[] memory amounts,uint256[] memory decimals){
             positions=IVaultFacet(diamond).getVaultAllPosition(_vault,_positionTypes);
             amounts=new uint256[](positions.length);
             decimals=new uint256[](positions.length);
             for(uint256 i;i<positions.length;i++){
                 amounts[i]=IERC20(positions[i].component).balanceOf(_vault);
                 decimals[i]=IERC20Metadata(positions[i].component).decimals();
             }

    }
    function getVaultProtocolPosition(address _vault,uint16 _positionType) external view returns(IVaultFacet.Position[] memory positions,uint256[] memory amounts,uint256[] memory decimals){
             positions=IVaultFacet(diamond).getVaultProtocolPosition(_vault,_positionType);
             amounts=new uint256[](positions.length);
             decimals=new uint256[](positions.length);
             for(uint256 i;i<positions.length;i++){
                 amounts[i]=IERC20(positions[i].component).balanceOf(_vault);
                 decimals[i]=IERC20Metadata(positions[i].component).decimals();
             }
    }

    //---------------
    function getVaultMasterToken(address _vault) external view returns(address){
        return IVaultFacet(diamond).getVaultMasterToken(_vault);
    }  
    function getVaultLock(address _vault) external view returns(bool){
         return IVaultFacet(diamond).getVaultLock(_vault);
    }
 
    function getVaulTime(address _vault) external view returns(uint256){
         return IVaultFacet(diamond).getVaulTime(_vault);
    }   
    function getVaultAllModules(address _vault) external view returns(address[] memory){
         return IVaultFacet(diamond).getVaultAllModules(_vault);
    }
    function getVaultModuleStatus(address _vault,address _module) external view returns(bool){
         return IVaultFacet(diamond).getVaultModuleStatus(_vault,_module);
    }
    function getVaultAllTokens(address _vault) external view returns(address[] memory){
          return IVaultFacet(diamond).getVaultAllTokens(_vault);  
    }
    function getVaultTokenType(address _vault,address _token) external view returns(uint256){
         return IVaultFacet(diamond).getVaultTokenType(_vault,_token);  
    }
    function getVaultAllProtocol(address _vault) external view returns(address[] memory){
         return IVaultFacet(diamond).getVaultAllProtocol(_vault);   
    }

    function getVaultProtocolStatus(address _vault,address  _protocol) external view returns(bool){
         return IVaultFacet(diamond).getVaultProtocolStatus(_vault,_protocol);   
    }


    function getVaultPosition(address _vault,address _component, uint256 _positionType) external view returns(IVaultFacet.Position memory position){
        return IVaultFacet(diamond).getVaultPosition(_vault,_component,_positionType);
    }
    //---------------
    function getAllModules() external view returns(address[] memory){
         return IPlatformFacet(diamond).getAllModules();
    }
    function getModuleStatus(address _module) external view returns(bool){
         return IPlatformFacet(diamond).getModuleStatus(_module);
    }
    function getProtocols()  external view returns(IPlatformFacet.ProtocolAndA[] memory){
        return IPlatformFacet(diamond).getProtocols();
    }
    function getModuleToProtocolA(address _module,string memory _protocol) external view returns(address){
        return  IPlatformFacet(diamond).getModuleToProtocolA(_module,_protocol);
    }
    function getTokens()  external view returns(address[] memory){
        return  IPlatformFacet(diamond).getTokens();
    }
    function getTokenType(address _token) external view returns(uint256){
         return  IPlatformFacet(diamond).getTokenType(_token);
    }
    function getIsVault(address _vault) external view returns(bool){
         return IPlatformFacet(diamond).getIsVault(_vault);
    }
    function getWeth() external view returns(address){
         return IPlatformFacet(diamond).getWeth();
    }
    function getVaultImplementation() external view returns(address){
         return IPlatformFacet(diamond).getVaultImplementation();
    }
    function getDomainHash() external view returns(bytes32){
         return ILendFacet(diamond).getDomainHash();
    }
    function getLendFeePlatformRecipient() external view returns(address){
         return ILendFacet(diamond).getLendFeePlatformRecipient();
    }

    function getLoanerLendInfos(address _loaner) external view returns(address[] memory){
         return ILendFacet(diamond).getLoanerLendInfo(_loaner);
    }

    function getDebtorLendInfo(address _debtor) external view returns(ILendFacet.LendInfo memory){
         return  ILendFacet(diamond).getDebtorLendInfo(_debtor);
    }
    //
    function getVaultType(address _vault) external view returns(uint256){
          return IVaultFacet(diamond).getVaultType(_vault);
    }
    function getSourceType(address _vault) external view returns(uint256){
         return IVaultFacet(diamond).getSourceType(_vault);
    }
    //    
    function getBorrowerStakeInfo(address _borrower) external view returns(ILendFacet.StakeInfo memory){
        return ILendFacet(diamond).getBorrowerStakeInfo(_borrower);
    }
    function getBorrowers(address _lender) external view returns(address[] memory) {
        return ILendFacet(diamond).getBorrowers(_lender);
    }

}