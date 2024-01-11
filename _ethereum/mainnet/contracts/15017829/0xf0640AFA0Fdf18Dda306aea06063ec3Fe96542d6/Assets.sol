// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Pausable.sol";
import "./SafeERC20.sol";
import "./Admin.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract Assets.
*/

contract Assets is  Pausable {
    using SafeERC20 for IERC20;
    struct Asset{
        address  token;
        address oracle;
        uint256 price;
        uint256 decimals;   
    }

    uint256 public index;
    Asset[] public  assets;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public indexAsset;
    Admin public admin;
    constructor(address _admin) {
         require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
         admin = Admin(_admin);
    }


    modifier onlyManager() {
        address _manager = admin.manager();
        require(msg.sender == _manager, "Formation.Fi: no manager");
        _;
    }

    modifier onlyManagerOrOwner() {
        address _manager = admin.manager();
        require( (msg.sender == _manager) || ( msg.sender == owner()),
        "Formation.Fi: no manager or owner");
        _;
    }

    /**
     * @dev Getter functions .
     */
    function isWhitelist( address _token) external view  returns (bool) {
        return whitelist[_token];
    }
    function getIndex( address _token) external view  returns (uint256) {
        return indexAsset[_token];
    }


     /**
     * @dev Setter functions .
     */
    function setAdmin(address _admin) external onlyOwner {
        require(
            _admin != address(0),
            "Formation.Fi: zero address"
        );
        
        admin = Admin(_admin);
    } 


    /**
     * @dev Add an asset .
     * @param  _token The address of the asset.
     * @param  _oracle The address of the oracle.
     * @param  _price The price in the case where the oracle doesn't exist.
     */
    function addAsset( address _token, address _oracle, uint256 _price) 
        external onlyOwner {
        require ( whitelist[_token] == false, "Formation.Fi: Token exists");
        if (_oracle == address(0)){
           require(_price != 0, "zero price");
        }
        else {
        require(_price == 0, "not zero price");
        }
        uint8 _decimals = 0;
        if (_token!=address(0)){
        _decimals = ERC20(_token).decimals();
        }
        Asset memory _asset = Asset(_token, _oracle, _price, _decimals);
        indexAsset[_token] = index;
        assets.push(_asset);
        index = index +1;
        whitelist[_token] = true;
    }
    
     /**
     * @dev Remove an asset .
     * @param  _token The address of the asset.
     */
    function removeAsset( address _token) external onlyManagerOrOwner {
        require ( whitelist[_token] == true, "Formation.Fi: no Token");
        whitelist[_token] = false;
    }

    /**
     * @dev update the asset's oracle .
     * @param  _token The address of the asset.
     * @param  _oracle The new oracle's address.
     */
    function updateOracle( address _token, address _oracle) external onlyOwner {
        require ( whitelist[_token] == true, "Formation.Fi: no token");
        uint256 _index = indexAsset[_token];
        assets[_index].oracle = _oracle;
    }

    /**
     * @dev update the asset's price .
     * @param  _token The address of the asset.
     * @param  _price The new price's address.
     */
    function updatePrice( address _token, uint256 _price) external onlyOwner {
        require ( whitelist[_token] == true, "Formation.Fi: no token");
        require ( _price != 0, "Formation.Fi: zero price");
        uint256 _index = indexAsset[_token];
        require (assets[_index].oracle == address(0), " no zero address");
        assets[_index].price = _price;
    }
    
}
