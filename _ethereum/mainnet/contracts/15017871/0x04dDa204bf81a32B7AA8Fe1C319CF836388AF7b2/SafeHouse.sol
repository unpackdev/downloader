// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "./ERC20.sol";
import "./AggregatorV3Interface.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./Assets.sol";
import "./Admin.sol";


/** 
* @author Formation.Fi.
* @notice Implementation of the contract SafeHouse.
*/

contract SafeHouse is  Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;
    uint256 public constant  FACTOR_DECIMALS   = 1e8;
    uint256 public constant stableDecimals = 1e18;
    uint256 public maxWithdrawalStatic = 1000000 * 1e18;
    uint256 public maxWithdrawalDynamic =  1000000 * 1e18; 
    uint256 public  tolerance;
    mapping(address => bool) public vaultsList;
    Assets public assets;
    Admin public admin;
    constructor( address _assets, address _admin) payable {
        require(
            _assets != address(0),
            "Formation.Fi: zero address"
        );
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        assets = Assets(_assets);

        admin = Admin(_admin);
    }
   

    modifier onlyManager() {
        address _manager = admin.manager();
        require(msg.sender == _manager, "Formation.Fi: no manager");
        _;
    }


     /**
     * @dev Setter functions.
     */
     function setMaxWithdrawalStatic( uint256 _maxWithdrawalStatic) external onlyOwner {
     maxWithdrawalStatic = _maxWithdrawalStatic;
     }
    
    function setMaxWithdrawalDynamic( uint256 _maxWithdrawalDynamic) external onlyOwner {
     maxWithdrawalDynamic = _maxWithdrawalDynamic;
     }

    function setTolerance( uint256 _tolerance) external  onlyOwner {
     tolerance = _tolerance;
    }

    function setAdmin(address _admin) external onlyOwner {
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        
        admin = Admin(_admin);
    } 

    /**
     * @dev Add a vault address the manager.
     * @param  _vault vault'address.
     */
    function addVault( address _vault) external onlyOwner {
        require(
            _vault != address(0),
            "Formation.Fi: zero address"
        );
        vaultsList[_vault] = true; 
     }

    /**
     * @dev Remove a vault address the manager.
     * @param  _vault vault'address.
     */
    function removeVault( address _vault) external onlyOwner {
        require(
            vaultsList[_vault]== true,
            "Formation.Fi: no vault"
        );
        vaultsList[_vault] = false; 
     }
    
     /**
     * @dev Send an asset to the contract by the manager.
     * @param _asset asset'address.
     * @param _amount amount to send.
     */
    function sendAsset( address _asset, uint256 _amount) 
        external whenNotPaused onlyManager payable {
        uint256 _index =  assets.getIndex(_asset);
        uint256 _price;
        uint256 _decimals;
        address _oracle;
        ( , _oracle, _price, _decimals ) = assets.assets(_index);
        _price = uint256(getLatestPrice( _asset, _oracle, _price));
        maxWithdrawalDynamic = Math.min(maxWithdrawalDynamic + (_amount * _price) /FACTOR_DECIMALS,
        maxWithdrawalStatic);


        if ( _asset == address(0)) {
          require (_amount == msg.value, "Formation.Fi: wrong amount");
        }
        else {
            uint256 _scale;
            _scale = Math.max((stableDecimals/ 10 ** _decimals), 1);
            IERC20 asset = IERC20(_asset);
            asset.safeTransferFrom(msg.sender, address(this), _amount/_scale); 
        }
        
    }

    /**
     * @dev Withdraw an asset from the contract by the manager.
     * @param _asset asset'address.
     * @param _amount amount to send.
     */
    function withdrawAsset( address _asset, uint256 _amount) external whenNotPaused onlyManager {
        uint256 _index =  assets.getIndex(_asset);
        uint256 _price;
        uint256 _decimals;
        address _oracle;
        ( , _oracle, _price, _decimals ) = assets.assets(_index);
        _price= uint256(getLatestPrice( _asset, _oracle, _price));
        uint256 _delta = (_amount * _price)  / FACTOR_DECIMALS  ;
        require ( Math.min(maxWithdrawalDynamic, maxWithdrawalStatic) >= _delta , "Formation.Fi: maximum withdrawal");
        maxWithdrawalDynamic = maxWithdrawalDynamic  - _delta  + (_delta * tolerance)/FACTOR_DECIMALS;
         if ( _asset == address(0)) {
         payable(msg.sender).transfer(_amount);
        }
        else {
        uint256 _scale;
        _scale = Math.max((stableDecimals/ 10 **_decimals), 1);
        IERC20 asset = IERC20(_asset);
        asset.safeTransfer(msg.sender, _amount/_scale);   
        } 

    }

    /**
     * @dev Get the asset's price.
     * @param _asset asset'address.
     * @param _oracle oracle'address.
     * @param _price asset'price.
     * @return price
     */

    function getLatestPrice( address _asset, address _oracle, uint256 _price) public view returns (uint256) {
        require (assets.isWhitelist(_asset) ==true, "Formation.Fi: not asset");
        if (_oracle == address(0)) {
            return _price;
        }
        else {
        AggregatorV3Interface  priceFeed = AggregatorV3Interface(_oracle);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price);
        }   
    }

     /**
     * @dev Send an asset to the vault.
     * @param _asset asset'address.
     * @param _vault vault'address.
     * @param _amount to send.
     */
    function sendToVault( address _asset, address _vault,  uint256 _amount) external
        whenNotPaused onlyManager {
        require (_vault !=address(0) , "Formation.Fi: zero address");
        require (vaultsList[_vault] == true , "Formation.Fi: no vault");
        uint256 _index =  assets.getIndex(_asset);
        uint256 _decimals;
        ( , , , _decimals ) = assets.assets(_index);
        if ( _asset == address(0)){
           require (_amount <= address(this).balance , 
           "Formation.Fi: balance limit");
           payable (_vault).transfer(_amount);
        }
        else{
            uint256 _scale;
            _scale = Math.max((stableDecimals/ 10 ** _decimals), 1);
            IERC20 asset = IERC20(_asset);
           require ((_amount/_scale) <= asset.balanceOf(address(this)) , "Formation.Fi: balance limit");
           asset.transfer(_vault, _amount/_scale);   
        
        }
    }


    fallback() external payable {
     
    }

     receive() external payable {
       
    }


    
       

}
