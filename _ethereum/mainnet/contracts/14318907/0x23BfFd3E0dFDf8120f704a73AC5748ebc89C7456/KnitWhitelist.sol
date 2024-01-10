// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "./Ownable.sol";
import "./AccessControl.sol";

contract KnitWhitelist is Ownable, AccessControl {
    mapping(address => bool) whitelist;
    mapping(address => uint256) limits;
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bool public whitelistEnabled = false;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event AddedMaxLimit(address indexed account,uint256 limit);

    constructor () {
        _setupRole(WHITELIST_ROLE, msg.sender);
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function add(address _address) public {
      require(hasRole(WHITELIST_ROLE, msg.sender), "Caller is not valid");
      whitelist[_address] = true;
      emit AddedToWhitelist(_address);
    }

    function remove(address _address) public {
      require(hasRole(WHITELIST_ROLE, msg.sender), "Caller is not valid");
      whitelist[_address] = false;
      emit RemovedFromWhitelist(_address);
    }

    function setLimit(address _address,uint256 limit) public {
      require(hasRole(WHITELIST_ROLE, msg.sender), "Caller is not valid");
      limits[_address] = limit;
      emit AddedMaxLimit(_address,limit);
    }

    function setStatus(bool status) public {
      require(hasRole(WHITELIST_ROLE, msg.sender), "Caller is not valid");
      whitelistEnabled = status;
    }

    function getLimit(address _address) public view returns(uint256) {
        return limits[_address];
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function isValid(address _token, address _address, uint256 amount) public view returns(bool) {
      if(!whitelistEnabled || isWhitelisted(_address)){
        return true;
      } else {
        if(amount > limits[_token]){
          return false;
        } else {
          return true;
        }
      }
    }
}
