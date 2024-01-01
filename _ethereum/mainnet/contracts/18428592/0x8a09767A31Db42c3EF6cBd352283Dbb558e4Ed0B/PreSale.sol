//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Address.sol";
import "./ERC20.sol";

contract UniverseXPreSale  {

    uint256 public constant START_SALE=1698255000; // Oct 25, 2023 17:30
    uint256 public END_SALE=1698427800; // Oct 27, 2023 17:30
    uint256 constant public FEE=7;
    uint8 constant public BOX_COUNT=4;
    
    uint256 totalSoldTokens = 0;

    mapping(address => uint256) _sold;
    mapping(address => uint256) _claimed;
    IERC20 private _token;
    
    uint256[BOX_COUNT] private _boxTokens=[7000 ether,15000 ether,35000 ether, 80000 ether];
    uint256[BOX_COUNT] private _boxPrice=[0.05 ether,0.1 ether,0.2 ether, 0.4 ether];

    address[2] private _sellers=[
      0xA49804eFef31dF1d1781644875750B2565784e3d,
      0xce30CFA16478A6ef118Fd48b6eF7f5d9C021C31d
    ];

    address private _flushAddress = 0xc46b48737D2cA939F2a0B3fCc298912312716CD4;
    address private _owner;

    event BoxSold(address indexed user, uint8 boxId, uint8 amount);
    event Claimed(address indexed user, uint256 amount);
    
    
    /**
     * @dev Constructor function.
     */
    constructor(address token) {
        _token=IERC20(token);
        _owner=tx.origin;
    }
    
    function setSaleEnd(uint256 date) external {
        require(msg.sender == _owner, "Not authorized");
        require(date > START_SALE, "Wrong date");
        require(date < END_SALE, "Wrong date");
        END_SALE=date;
    }

    function forClaim(address user) external view returns(uint256){
        return _sold[user] - _claimed[user];
    }
    function forClaimTotal() external view returns(uint256){
        return _token.balanceOf(address(this)) - totalSoldTokens;

    }
    function getBNBAmount(uint8 boxId, uint8 amount) external view returns(uint256){
      return _boxPrice[ boxId ] * amount;
    }

    function buy(uint8 boxId, uint8 amount, address referrer)external payable{
      require( amount > 0, "Illegal amount");
      require(block.timestamp >= START_SALE, "Too early");
      require(block.timestamp <= END_SALE, "Too late");
      require( boxId < BOX_COUNT, "Illegal box ID");
      require( _boxTokens[ boxId ] * amount + totalSoldTokens <= _token.balanceOf(address(this)), "Not enough tokens");
      require( _boxPrice[ boxId ] * amount == msg.value, "Not exact value");

      uint256 value=msg.value;
      _sold[msg.sender] += _boxTokens[ boxId ] * amount;
      totalSoldTokens += _boxTokens[ boxId ] * amount;
      if (referrer != address(0) && referrer != msg.sender){
          Address.sendValue( payable(referrer), msg.value / 10);
          value=value * 9 / 10;
        }
      Address.sendValue( payable(_sellers[0]), value/2);
      Address.sendValue( payable(_sellers[1]), value/2);
      emit BoxSold(msg.sender, boxId, amount);
    }

    function claim() external {
        require(block.timestamp > END_SALE, "Too early");
        require( _sold[msg.sender] > _claimed[msg.sender], "No enough tokens");
        if (totalSoldTokens < _token.balanceOf(address(this))){
            _token.transfer(_flushAddress, _token.balanceOf(address(this)) - totalSoldTokens);
            totalSoldTokens=_token.balanceOf(address(this));
        }
        
        uint256 amount=_sold[msg.sender] - _claimed[msg.sender];
        _claimed[msg.sender]=_sold[msg.sender];
        _token.transfer(msg.sender,amount);
        emit Claimed(msg.sender, amount);
    }
}