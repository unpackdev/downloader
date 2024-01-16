pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IWorldOfFreight {
    function mintItems(address to, uint256 amount) external;
}

interface IWofToken {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function transfer(address to, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        returns (uint256);
}

contract SaleContract is Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_MINT = 500;
    uint256 public MINT_PRICE_WOF = 50000000000000000000000; //50 000 WOF
    uint256 public constant MINT_PRICE = 80000000000000000; //WEI // 0.08 ETH
    IWorldOfFreight public nftContract;
    IWofToken public wofToken;

    constructor(address _nftAddress, address _tokenAddress) {
        nftContract = IWorldOfFreight(_nftAddress);
        wofToken = IWofToken(_tokenAddress);
    }

    function setWoFMintPrice(uint256 _amount) public onlyOwner {
        MINT_PRICE_WOF = _amount;
    }

    function mint(uint256 _amount) public payable {
        require(msg.value >= _amount * MINT_PRICE, "Not enough funds");
        require(_amount <= MAX_MINT, "Sorry max 500 per transaction");
        nftContract.mintItems(msg.sender, _amount);
    }

    function mintWithWof(uint256 _amount) public {
        require(
            wofToken.allowance(msg.sender, address(this)) >=
                _amount * MINT_PRICE_WOF,
            "Transaction cost exceeds allowance"
        );
        wofToken.transferFrom(msg.sender, address(this), _amount);
        nftContract.mintItems(msg.sender, _amount);
    }

    function withdrawAmount(address payable to, uint256 amount)
        public
        onlyOwner
    {
        to.transfer(amount);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        wofToken.transfer(_to, _amount);
    }
}
