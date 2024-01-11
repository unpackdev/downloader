// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

pragma solidity ^0.8.7;

contract WizzyWiz is ERC721, Ownable, ReentrancyGuard {
  uint256 private s_tokenCounter;
  mapping(address => uint32) public mintList;
  string public baseExtension = ".json";
  uint private mintOpen = 0;

  struct SalesConfig {
    uint256 mintPrice;
    uint256 amountPerWallet;
    uint256 freeSupply;
    uint256 totalSupply;
  }

  SalesConfig public salesConfig;

  event SuccessfulMint(address user, uint amount, uint value);
  event Received(address user, uint amount);
  constructor(
    uint256 totalSupply_,
    uint256 freeSupply_,
    uint256 mintPrice_,
    uint256 amountPerWallet_
  ) ERC721("Wizzy Wizards", "WIZ") {
    s_tokenCounter = 0;
    salesConfig.totalSupply = totalSupply_;
    salesConfig.freeSupply = freeSupply_;
    salesConfig.mintPrice = mintPrice_;
    salesConfig.amountPerWallet = amountPerWallet_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function mintNFT(uint256 amount) public payable callerIsUser returns (uint256) {
    require(mintOpen == 1, "Mint not open yet");
    require(mintList[msg.sender] <= 2, "Minted max amount per wallet");
    uint256 mint_price = calculatePrice(amount);
    require(mint_price <= msg.value, "Not enough ether sent");
    _safeMint(msg.sender, s_tokenCounter);
    refundIfOver(mint_price);
    mintList[msg.sender] += uint32(amount);
    s_tokenCounter += amount;
    emit SuccessfulMint(msg.sender, amount, msg.value);
    return s_tokenCounter;
  }

  function mintStatus(uint value) public onlyOwner{
    mintOpen = value;
  }
  
  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function getTokenCounter() public view returns (uint256) {
    return s_tokenCounter;
  }

  // Determine how many the use will pay for
  function calculatePrice(uint256 amountMinting) public view returns (uint256) {
    if (s_tokenCounter + amountMinting <= salesConfig.freeSupply) {
      return 0;
    }
    if (
      s_tokenCounter + 1 <= salesConfig.freeSupply && s_tokenCounter + 2 > salesConfig.freeSupply
    ) {
      return 1 * salesConfig.mintPrice;
    } else {
      return amountMinting * salesConfig.mintPrice;
    }
  }

  function withdraw() external onlyOwner nonReentrant returns(bool) {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed");
    return success;
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
}

  // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    virtual
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }
}
