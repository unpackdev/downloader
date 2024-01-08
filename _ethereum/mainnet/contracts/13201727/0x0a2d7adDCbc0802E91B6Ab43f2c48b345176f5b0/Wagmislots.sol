pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Wagmislots is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    uint256 public constant mintPrice = 50000000000000000;  // 0.05 ETH
    uint256 public constant maxPurchase = 10;
    uint256 public constant maxSupply = 21 ** 3;

    bool public saleIsActive = false;

    constructor() ERC721("Wagmislots", "WGMS") Ownable() {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmaRWk3Kg2o5SQH3f2uxPpfMLXKMCPrh1UEPtmueXKzgTb/";
    }

    function withdraw(address payable wallet, uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(amount <= balance, "Insufficient balance");
        wallet.transfer(amount);
    }

    function enableSale() public onlyOwner {
        saleIsActive = true;
    }

    function mint(uint256 purchasedTokens) public payable {
        require(saleIsActive, "Sale is not active yet");
        require(purchasedTokens > 0, "Number of tokens must be non-zero");
        require(purchasedTokens <= maxPurchase, "Cannot mint more than 10 tokens at a time");
        require(totalSupply().add(purchasedTokens) <= maxSupply, "Cannot exceed max supply");
        require(mintPrice.mul(purchasedTokens) <= msg.value, "Insufficient transaction value");

        for(uint256 i = 0; i < purchasedTokens; ++i) {
            _safeMint(msg.sender, totalSupply());
        }
    }
}
