// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

import "./RandomNumber.sol";
import "./ChainLink.sol";

abstract contract MillionDollarUtils is Aggregator, Ownable, RandomNumber {}
contract MillionDollarMint is ERC721Enumerable, MillionDollarUtils {

    bool public saleIsActive = false;
    uint256 public constant PRICE = 0.075 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 10;

    bool public IS_DRAWN = false;
    address public winner;

    modifier soldOut {
      require(totalSupply() == 10000, "Collection not sold out");
      _;
    }

    constructor() ERC721("MDM Ticket", "MDM") {}

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint16 amount) public payable {
        uint256 ts = totalSupply();
        uint256 tsAmount = ts + amount;

        require(saleIsActive, "Sale not active");
        require(amount <= MAX_PUBLIC_MINT, "Max 10 per txn");
        require(tsAmount < 10000, "More than total supply");

        uint256 price = amount * PRICE;

        if (tsAmount <= 1000) {
          price = 0 ether;
        } else if(tsAmount > 1000 && tsAmount <= 1009) {
          price = (tsAmount - 1000) * PRICE;
        } 
        
        if(tsAmount > 1000) {
          require(msg.value >= price, "Not enough ether sent");
        }

        for (uint256 i; i < amount ; i++) {
            _safeMint(msg.sender, ts + i);
        }

        if (msg.value > price) {
          (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
          require(success, "Transfer failed");
        }
    }

    receive() external payable {}

    // NOTE: Get the chain link latest price from: https://docs.chain.link/docs/get-the-latest-price/
    function previewEthValue(int256 _ethprice) public view returns(int256){
      int256 latestPrice = _ethprice;

      int256 ethValue = ((1_000_000 * 10 ** 10) / latestPrice) * 10 ** 16; 

      return ethValue;
    }

    // NOTE: Cannot draw a winner until collection is sold out
    function drawWinner() public onlyOwner soldOut{
      uint256 tokenWinner = randomResult;
      int256 latestPrice = getLatestPrice();

      int256 ethValue = ((1_000_000 * 10 ** 10) / latestPrice) * 10 ** 16; 

      address addressWinner = ownerOf(tokenWinner);

      (bool success, ) = payable(addressWinner).call{value: uint256(ethValue) }("");
      require(success, "Transfer failed");

      IS_DRAWN = true;
      winner = addressWinner;
    }

    // NOTE: Cannot withdraw until collection is sold out and winner has been paid
    function withdrawAll() public onlyOwner soldOut {
      require(IS_DRAWN, "Collection winner not drawn yet");

      (bool success, ) =  payable(msg.sender).call{value: address(this).balance}("");
      require(success, "Transfer failed");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return "ipfs://QmVSymhzQAaY5FSEf8aVkKrTPYfXLzCYiUWq2woxsSmrvm";
    }
}