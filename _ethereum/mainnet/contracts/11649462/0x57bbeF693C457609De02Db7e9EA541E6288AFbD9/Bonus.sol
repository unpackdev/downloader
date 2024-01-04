/*
Original work taken from https://gist.github.com/rstormsf/7cfb0c6b7a835c0c67b4a394b4fd9383
Has been amended to use openzepplin Ownable and now only supports one grant per address for simplicity.
*/
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Bonus is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    event BonusClaimed(address indexed recipient);

    ERC20 private baseToken;

    // Tokens the user must hold some of
    ERC20 private token1;
    ERC20 private token2;

    uint256 private bonusAmount;

    bool private allowMultipleClaims = false;
    
    mapping (address => bool) private claimed;

    constructor(ERC20 _baseToken, ERC20 _token1, ERC20 _token2, uint256 _bonusAmount) public {
        require(address(_baseToken) != address(0));
        require(address(_token1) != address(0));
        require(address(_token2) != address(0));
        require(_bonusAmount > 0);
        baseToken = _baseToken;
        token1 = _token1;
        token2 = _token2;
        bonusAmount = _bonusAmount;
    }
    
    function claim() external {
        require(allowMultipleClaims || claimed[msg.sender] != true, "Address already claimed bonus.");
        
        uint256 token1Balance = token1.balanceOf(msg.sender);
        uint256 token2Balance = token2.balanceOf(msg.sender);

        require(token1Balance + token2Balance > 0, "Must hold some Token1 or Token2");

        claimed[msg.sender] = true;
        require(baseToken.transfer(msg.sender, bonusAmount));

        emit BonusClaimed(msg.sender);
    }

    function getBonusAmount() public view returns (uint256) {
        return bonusAmount;
    }

    function setBonusAmount(uint256 _bonusAmount) external onlyOwner
    {
        bonusAmount = _bonusAmount;
    }
    
    function setToken1(ERC20 _token1) external onlyOwner
    {
        token1 = _token1;
    }

    function setToken2(ERC20 _token2) external onlyOwner
    {
        token2 = _token2;
    }

    function setBaseToken(ERC20 _baseToken) external onlyOwner
    {
        baseToken = _baseToken;
    }

    function setAllowMultipleClaims(bool _allowMultipleClaims) external onlyOwner
    {
        allowMultipleClaims = _allowMultipleClaims;
    }
}