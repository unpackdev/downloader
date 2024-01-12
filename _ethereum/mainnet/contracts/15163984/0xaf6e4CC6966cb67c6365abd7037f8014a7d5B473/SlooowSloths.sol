
  // SPDX-License-Identifier: MIT

  pragma solidity ^0.8.0;

  import "./ERC721A.sol";
  import "./Ownable.sol";
  import "./ReentrancyGuard.sol";

  contract SlooowSloths is ERC721A, Ownable, ReentrancyGuard {
      bool public pause;
      string public baseURI;
      uint public price;
      uint public transactionLimit = 10;
      uint public walletLimit = 50;
      uint public freeMints = 500;
      uint public supply = 2500;

      constructor() ERC721A("SlooowSloths", "SLOTH"){}
  
      function claim(uint amount) external contractProtection {
          require(pause, "Minting Paused");
          require(amount < transactionLimit + 1, "Transaction Limit Reached");
          require(totalSupply() + amount < freeMints + 1, "Free Mints Claimed");
          require(_numberMinted(msg.sender) + amount < walletLimit + 1, "Wallet Limit Reached");
          _safeMint(msg.sender, amount);
      }
    
      function mint(uint amount) external payable contractProtection {
          require(pause, "Minting Paused");
          require(amount < transactionLimit + 1, "Transaction Limit Reached");
          require(totalSupply() + amount < supply + 1, "Supply Limit Reached");
          require(msg.value >= amount * price, "Bad Ether");

          _safeMint(msg.sender, amount);
      }

      function devMint(uint amount, address recipient) external onlyOwner {
          require(totalSupply() + amount < supply + 1, "Supply Limit Reached");

          _safeMint(recipient, amount);
      }

      function _baseURI() internal view virtual override returns (string memory) {
          return baseURI;
      }

      function setBaseURI(string calldata baseURI_) external onlyOwner {
          baseURI = baseURI_;
      }

      function setPrice(uint price_) external onlyOwner {
          price = price_;
      }

      function pauseable() external onlyOwner {
          pause = !pause;
      }

      function withdraw() external nonReentrant onlyOwner {
          (bool success,) = msg.sender.call{value: address(this).balance}("");
          require(success, "Withdraw Unsuccesful");
      }

      modifier contractProtection() {
          require(tx.origin == msg.sender, "Sender Is Contract");
          _;
      }
  }
