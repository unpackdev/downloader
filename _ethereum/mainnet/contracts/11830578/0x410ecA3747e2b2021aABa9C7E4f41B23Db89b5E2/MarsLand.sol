pragma solidity 0.6.0;

import "./SafeMath.sol";

import "./ERC20.sol";

contract MarsLand is ERC20 {
  using SafeMath for uint256;
  mapping (address => bool) private _claims;
  uint256 internal _numberOfCliams;
  uint256 internal constant TOTAL_SURFACE_AREA_KM2 = 144798500;
  constructor() public ERC20('Mars Land', 'MARSX') {
     uint256 _amount = TOTAL_SURFACE_AREA_KM2.div(100);
    _mint(msg.sender, _amount.mul(10 ** uint(decimals())));
    _numberOfCliams = 0;
  }
  function maxSupply() public view returns (uint256) {
    return TOTAL_SURFACE_AREA_KM2.div(2).mul(10 ** uint(decimals()));
  }
  function claim() public {
    require(_claims[msg.sender] == false, "Already claimed.");
    uint256 _amount = getCurrentMintAmount();
    require(_amount > 0, "No token available.");
    uint256 _maxSupply = TOTAL_SURFACE_AREA_KM2.div(2).mul(10 ** uint(decimals()));
    require(totalSupply() <= _maxSupply, "Supply exceeded.");
    _claims[msg.sender] = true;
    _mint(msg.sender, _amount * 10 ** uint(decimals()));
    _numberOfCliams = _numberOfCliams.add(1);
  }
  function getCurrentMintAmount() public view returns (uint256) {
    return _getCurrentMintAmount();
  }
  function hasClaimed(address account) public view returns (bool) {
    return _claims[account] == true;
  }
  function _getCurrentMintAmount() internal view returns (uint256) {
    if(maxSupply() <= totalSupply()) {
       return 0;
    }
    uint256  _count = _numberOfCliams.div(10);
    if(_count < 1000) {
      return 1000 - _count;
    }
    return 1;
  }
}
