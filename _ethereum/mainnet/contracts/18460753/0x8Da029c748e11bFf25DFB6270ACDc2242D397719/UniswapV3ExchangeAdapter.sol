// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IExchangeAdapter.sol";
import "./IOwnable.sol";
import "./IPlatformFacet.sol";
import "./IUniswapV3Router.sol";
import "./BytesLib.sol";

contract UniswapV3ExchangeAdapter is IExchangeAdapter,Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable {   
    address public diamond;
    address public router;
    using BytesLib for bytes;
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

    function initialize(address _diamond,address _router) public initializer {
        __UUPSUpgradeable_init();
        diamond=_diamond;
        router = _router;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function getAdapterCallData(       
        address _vault,
        address _sendAsset,
        address _receiveAsset,
        uint256 _adapterType,     
        uint256 _amountIn,
        uint256 _amountLimit,
        bytes memory _data)  
        external
        view
        returns (  AdapterCalldata memory _adapterCalldata )      
    { 
      ( bytes memory path,uint160 sqrtPriceLimitX96,bool isEth)=  abi.decode(_data,(bytes,uint160,bool));
       validData(_adapterType,_sendAsset,_receiveAsset,path);
       _adapterCalldata.spender=router;
       _adapterCalldata.target=router;
       {
        if(_adapterType==1){
            _adapterCalldata.value=isEth ? _amountIn :0 ;
            _adapterCalldata.data=exactInputSingle(_sendAsset,_receiveAsset,path.toUint24(20),_vault,_amountIn,_amountLimit,sqrtPriceLimitX96);
        }  
        else if(_adapterType==2){
            _adapterCalldata.value=isEth ? _amountLimit :0 ;
           _adapterCalldata.data=exactOutput(path,_vault,_amountIn,_amountLimit);
        } 
        else if(_adapterType ==3){
            _adapterCalldata.value=isEth ? _amountLimit :0 ;
            _adapterCalldata.data=exactOutputSingle(_sendAsset,_receiveAsset,path.toUint24(20),_vault,_amountIn,_amountLimit,sqrtPriceLimitX96);
        }
        else{
            _adapterCalldata.value=isEth ? _amountIn :0 ;
            _adapterCalldata.data=exactInput(path,_vault,_amountIn,_amountLimit);
        }
       }
    }

    function  validData(uint256 _adapterType,address _sendAsset, address _receiveAsset,bytes memory path) internal view{
       IPlatformFacet platformFacet=IPlatformFacet(diamond);
       uint256 len=path.length-20;
       address tokenIn=_adapterType==2?path.toAddress(len) :path.toAddress(0);  
       address tokenOut=_adapterType==2?path.toAddress(0): path.toAddress(len) ;
       require(tokenIn==_sendAsset,"UniswapV3ExchangeAdapter:sendAsset must be same as path[0]");
       require(tokenOut==_receiveAsset,"UniswapV2ExchangeAdapter:receiveAsset must be same as path[laset]");   

       for(uint i=23;i<len;i++){
            tokenIn=path.toAddress(i);
            require(platformFacet.getTokenType(tokenIn)!=0,"UniswapV3ExchangeAdapter:token must be platform allowed");       
            i+=23;
       }
    }
   /**
   
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
   
    */
    function exactInputSingle(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint160 _sqrtPriceLimitX96
        ) internal view returns(bytes memory _calldata){
       _calldata = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))",
            IUniswapV3Router.ExactInputSingleParams(
                _tokenIn,
                _tokenOut,   
                _fee,
                _recipient,
                block.timestamp,
                _amountIn,
                _amountOutMinimum,
                _sqrtPriceLimitX96
            )

        );
    }
    /**
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
     */
    function exactInput(
        bytes memory _path,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal view returns(bytes memory _calldata){
        _calldata = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))",
            IUniswapV3Router.ExactInputParams( 
                 _path,
                 _recipient,                      
                 block.timestamp,
                 _amountIn,
                 _amountOutMinimum
            )
        );
    }
    /**
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
     */
    function exactOutputSingle(
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint160 _sqrtPriceLimitX96
    ) internal view returns(bytes memory _calldata){
       _calldata = abi.encodeWithSignature(
            "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))",
            IUniswapV3Router.ExactOutputSingleParams(
                _tokenIn,   
                _tokenOut,
                _fee,
                _recipient,
                block.timestamp,
                _amountOut,
                _amountInMaximum,
                _sqrtPriceLimitX96
            )
        );
    }
    /**
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
     */
    function exactOutput(
        bytes memory _path,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum        
    ) internal view returns(bytes memory _calldata){
        _calldata = abi.encodeWithSignature(
            "exactOutput((bytes,address,uint256,uint256,uint256))",
             IUniswapV3Router.ExactOutputParams(
                _path,
                _recipient,
                block.timestamp,
                _amountOut,
                _amountInMaximum
            )
        );
    }
}