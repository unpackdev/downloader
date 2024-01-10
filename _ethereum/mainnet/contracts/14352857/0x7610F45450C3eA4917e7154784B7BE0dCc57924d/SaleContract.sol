pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IWorldOfFreight {
    function mintItems(address to, uint256 amount) external;
}

contract SaleContract is Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_MINT = 500;
    uint256 public constant MINT_PRICE = 80000000000000000; //WEI // 0.08 ETH
    IWorldOfFreight public nftContract;

    constructor(address _nftAddress) {
        nftContract = IWorldOfFreight(_nftAddress);
    }

    function mint(uint256 _amount) public payable {
        require(msg.value >= _amount * MINT_PRICE, "Not enough funds");
        require(_amount <= MAX_MINT, "Sorry max 500 per transaction");
        nftContract.mintItems(msg.sender, _amount);
    }

    function withdrawAmount(address payable to, uint256 amount)
        public
        onlyOwner
    {
        to.transfer(amount);
    }
}
