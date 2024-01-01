// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IExchangeAdapter.sol";
import "./IOwnable.sol";
import "./IPlatformFacet.sol";
contract UniswapV2ExchangeAdapter is IExchangeAdapter,Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    address public diamond;
    address public router;
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
        returns (
           AdapterCalldata memory _adapterCalldata
        )
    {
        (address[] memory path) = abi.decode(_data, (address[]));   
        require(path[0] == _sendAsset, "UniswapV2ExchangeAdapter:sendAsset must be same as path[0]" );   
        require(path[path.length - 1] == _receiveAsset, "UniswapV2ExchangeAdapter:receiveAsset must be same as path[laset]");
        for (uint256 i; i < path.length; i++) {
             if(i==0 || i == path.length -1){
                continue;
             }   
             require( IPlatformFacet(diamond).getTokenType(path[i])!=0,"UniswapV2ExchangeAdapter:token must be platform allowed");     
        }
        _adapterCalldata.spender = router;
        _adapterCalldata.target = router;

        if (_adapterType == 1) {
            _adapterCalldata.data = swapTokensForExactTokens(_amountIn,_amountLimit, path,_vault );      
        } else if (_adapterType == 2) {
             _adapterCalldata.data = swapExactETHForTokens(_amountLimit, path, _vault);
            _adapterCalldata.value = _amountIn;
        } else if (_adapterType == 3) {
             _adapterCalldata.data = swapTokensForExactETH(_amountIn,_amountLimit,path,_vault);
        } else if (_adapterType == 4) {
             _adapterCalldata.data = swapExactTokensForETH(_amountIn,_amountLimit,path,_vault);
        } else if (_adapterType == 5) {
             _adapterCalldata.data = swapETHForExactTokens(_amountIn, path, _vault);
             _adapterCalldata.value =_amountLimit;
        } else {
             _adapterCalldata.data = swapExactTokensForTokens(_amountIn,_amountLimit,path,_vault);
        }
    }

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _to
    ) internal view returns (bytes memory _calldata) {
        _calldata = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            block.timestamp
        );
    }

    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path,
        address _to
    ) internal view returns (bytes memory _calldata) {
        _calldata = abi.encodeWithSignature(
            "swapTokensForExactTokens(uint256,uint256,address[],address,uint256)",
            _amountOut,
            _amountInMax,
            _path,
            _to,
            block.timestamp
        );
    }

    //swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] memory _path,
        address _to
    ) internal view returns (bytes memory _calldata) {
        _calldata = abi.encodeWithSignature(
            "swapExactETHForTokens(uint256,address[],address,uint256)",
            _amountOutMin,
            _path,
            _to,
            block.timestamp
        );
    }

    //swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    function swapTokensForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path,
        address _to
    ) internal view returns (bytes memory _calldata) {
        _calldata = abi.encodeWithSignature(
            "swapTokensForExactETH(uint256,uint256,address[],address,uint256)",
            _amountOut,
            _amountInMax,
            _path,
            _to,
            block.timestamp
        );
    }

    // swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _to
    ) internal view returns (bytes memory _calldata) {
        _calldata = abi.encodeWithSignature(
            "swapExactTokensForETH(uint256,uint256,address[],address,uint256)",
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            block.timestamp
        );
    }
    // swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    function swapETHForExactTokens(
        uint _amountOut,
        address[] memory _path,
        address _to
    ) internal view returns (bytes memory _calldata) {
        _calldata = abi.encodeWithSignature(
            "swapETHForExactTokens(uint256,address[],address,uint256)",
            _amountOut,
            _path,
            _to,
            block.timestamp
        );
    }
}
