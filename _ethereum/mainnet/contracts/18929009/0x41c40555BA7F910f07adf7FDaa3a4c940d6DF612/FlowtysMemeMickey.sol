//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./SafeERC20.sol";
import "./ERC721A.sol";

contract FlowtysMemeMickey is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
    bool public saleActive = false;
    IERC20 public INKToken = IERC20(0xB8BC04A8be09C4734e3B1a6169dcC0a4CD6d5efA);
    uint256 public constant TOKEN_LIMIT = 10000;
    uint256 public TOKEN_PRICE = 0.01 ether;
    uint256 public TOKEN_PRICE_INK;
    uint256 public maxPerMint = 50;

    constructor() ERC721A("FlowtysMemeMickey", "FLMCK", 50, TOKEN_LIMIT) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

  function mint(uint256 quantity) external payable callerIsUser nonReentrant saleIsActive {
      require(quantity <= maxPerMint, "Minting too much at once is not supported");

      uint256 ts = totalSupply();
      require(ts.add(quantity) <= TOKEN_LIMIT, "Purchase would exceed max tokens");
      require(msg.value == TOKEN_PRICE.mul(quantity), "Ether value sent is not the required price");

      _safeMint(msg.sender, quantity);
    }

  function mintInk(uint256 quantity)
    external
    callerIsUser
    nonReentrant
    saleIsActive
  {
    require(quantity <= maxPerMint, "Minting too much at once is not supported");

    uint256 ts = totalSupply();
    uint price = TOKEN_PRICE_INK * quantity;
    uint256 buyerINKBalance = INKToken.balanceOf(msg.sender);
    require(price <= buyerINKBalance, "Insufficient funds: Not enough $INK for sale price");
    require(ts.add(quantity) <= TOKEN_LIMIT, "Purchase would exceed max tokens");

    INKToken.transferFrom(msg.sender, address(this), price);

    _safeMint(msg.sender, quantity);
  }

  function setMintCost(uint256 newCost) public onlyOwner {
      require(newCost > 0, "price must be greater than zero");
      TOKEN_PRICE = newCost;
  }

  modifier saleIsActive() {
    require(saleActive, "The sale is not active");
    _;
  }

  function setTokenPriceInk(uint256 price) external onlyOwner {
      TOKEN_PRICE_INK = price;
  }

  function flipSaleActive() public onlyOwner {
      saleActive = !saleActive;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawAllINK() public onlyOwner {
    uint256 balance = INKToken.balanceOf(address(this));
    require(balance > 0, "No $INK within this contract");
    INKToken.transfer(msg.sender, balance);
  }

  // Just in case anyone sends us any random ERC20
  function withdrawErc20(address erc20Contract, uint256 _amount) public onlyOwner {
    uint256 erc20Balance = IERC20(erc20Contract).balanceOf(address(this));
    require(erc20Balance >= _amount, "Insufficient funds: not enough ERC20");
    IERC20(erc20Contract).transfer(msg.sender, _amount);
  }

    // INTERNAL

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}