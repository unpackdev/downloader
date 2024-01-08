// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Ownable.sol";
import "./CockFightClub.sol";
import "./SafeMath.sol";

contract CFCFactory is Ownable {
    using SafeMath for uint256;
    uint256 private price = 33000000000000000; // 0.033 ether;
    CockFightClub public BallSacks;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

    constructor(CockFightClub _BallSacks) { BallSacks = _BallSacks; }

    function mint(uint256 _purchaseAmount) public payable {
        uint256 totalSupply = BallSacks.totalSupply();
        bool isCocksErect = BallSacks.isCocksErect();
        
        require(isCocksErect, "Sale is not active");
        require(
            _purchaseAmount > 0 && _purchaseAmount < MAX_TOKENS_PER_PURCHASE + 1,
            "You can not mint less than 1 cock, and at most 10 cocks"
        );
        require(totalSupply + _purchaseAmount < 6667, "All cocks are erect");
        require(
            msg.value >= price.mul(_purchaseAmount),
            "Ether value sent is not correct"
        );
        BallSacks.reserveTokens(msg.sender, _purchaseAmount);
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
      price = _newPrice;
    }

    function setContract(CockFightClub _contract) public onlyOwner {
      BallSacks = _contract;
    }

    function flipSaleStatus() public onlyOwner {
      BallSacks.flipSaleStatus();
    }

    function reserveTokens(address _to, uint256 _reserveAmount) public onlyOwner {
      BallSacks.reserveTokens(_to, _reserveAmount);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawSome(uint256 _some) public onlyOwner {
        require(_some < address(this).balance, "amount not available");
        payable(msg.sender).transfer(_some);
    }

    function renounceOwnership() public override onlyOwner {}

    function transferContractOwnerBack() public onlyOwner {
      BallSacks.transferOwnership(msg.sender);
    }
}

