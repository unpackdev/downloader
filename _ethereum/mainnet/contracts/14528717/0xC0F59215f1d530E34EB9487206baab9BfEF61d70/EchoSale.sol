// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./IEchoSale.sol";
import "./IIncarnateEcho.sol";

contract EchoSale is Ownable, IEchoSale {
  uint256 public mintCount;
  uint256 mintMaximum = 10_000;

  mapping(address => bool) public earlyAccess;

  address private _echo;

  uint earlyMintStart;
  uint earlyMintEnd;
  uint256 earlyMintPrice;

  uint mintStart;
  uint mintEnd;
  uint256 mintPrice;

  function earlyMint(uint256 quantity) payable public {
    require(earlyMintStart > 0, 'Early mint is not enabled');
    require(earlyMintPrice > 0, 'Early mint is not enabled');
    require(_echo != address(0), 'Early mint is not enabled');

    require(earlyMintStart <= block.timestamp, 'Early mint has not started yet');
    require(block.timestamp <= earlyMintEnd, 'Early mint has ended');
    require(hasEarlyAccess(), 'You need to have early access to use early mint');

    uint256 remaining = getRemaining(block.timestamp);
    require(quantity > 0, 'Quantity needs to be at least one');
    require(remaining > 0, 'Sold out');
    require(quantity <= 10, 'The maximum quantity is 10');
    require(quantity <= remaining, 'Not enough tokens available');
    require(msg.value >= earlyMintPrice * quantity, 'The message value is not enough');

    IIncarnateEcho(_echo).mint(msg.sender, quantity);
    payable(owner()).transfer(msg.value);

    delete earlyAccess[msg.sender];
    mintCount += quantity;
    
    emit Remaining(mintMaximum - mintCount);
  }

  function hasEarlyAccess() view public returns (bool hasAccess) {
    return earlyAccess[msg.sender] == true;
  }

  function getEarlyAccessInformation() view public returns (bool hasAccess, uint start, uint end, uint256 price) {
    require(earlyMintStart > 0, 'Early mint is not enabled');
    require(earlyMintPrice > 0, 'Early mint is not enabled');
    require(_echo != address(0), 'Early mint is not enabled');

    return (hasEarlyAccess(), earlyMintStart, earlyMintEnd, earlyMintPrice);
  }

  function addEarlyAccess(address address1, address address2, address address3, address address4, address address5) onlyOwner public {
    if (address1 != address(0)) {
      earlyAccess[address1] = true;
    }
    if (address2 != address(0)) {
      earlyAccess[address2] = true;
    }
    if (address3 != address(0)) {
      earlyAccess[address3] = true;
    }
    if (address4 != address(0)) {
      earlyAccess[address4] = true;
    }
    if (address5 != address(0)) {
      earlyAccess[address5] = true;
    }
  }

  function removeEarlyAccess(address address1, address address2, address address3, address address4, address address5) onlyOwner public {
    if (address1 != address(0)) {
      delete earlyAccess[address1];
    }
    if (address2 != address(0)) {
      delete earlyAccess[address2];
    }
    if (address3 != address(0)) {
      delete earlyAccess[address3];
    }
    if (address4 != address(0)) {
      delete earlyAccess[address4];
    }
    if (address5 != address(0)) {
      delete earlyAccess[address5];
    }
  }

  function enableEarlyMint(uint start, uint end, uint256 price) onlyOwner public {
    earlyMintStart = start;
    earlyMintEnd = end;
    earlyMintPrice = price;
  }

  function mint(uint256 quantity) payable public {
    uint256 remaining = getRemaining(block.timestamp);

    require(mintStart <= block.timestamp, 'Mint has not started yet');
    require(block.timestamp <= mintEnd, 'Mint has ended');
    require(quantity > 0, 'Quantity needs to be at least one');
    require(remaining > 0, 'Sold out');
    require(quantity <= 10, 'The maximum quantity is 10');
    require(quantity <= remaining, 'Not enough tokens available');
    require(msg.value >= mintPrice * quantity, 'The message value is not enough');

    IIncarnateEcho(_echo).mint(msg.sender, quantity);
    payable(owner()).transfer(msg.value);
    mintCount += quantity;

    emit Remaining(mintMaximum - mintCount);
  }

  function mintFor(address to, uint256 quantity) public onlyOwner {
    uint256 remaining = getRemaining(block.timestamp);

    require(quantity > 0, 'Quantity needs to be at least one');
    require(quantity <= remaining, 'Not enough tokens available');

    IIncarnateEcho(_echo).mint(to, quantity);
    mintCount += quantity;

    emit Remaining(mintMaximum - mintCount);
  }

  function getRemaining(uint time) view private returns (uint256 remaining) {
    if (mintCount < mintMaximum) {
      remaining = mintMaximum - mintCount;
    } else {
      remaining = 0;
    }

    if (mintEnd < time) {
      remaining = 0;
    }
    return remaining;
  }

  function getMintInformation(uint time) view public returns (uint start, uint end, uint256 price, uint256 remaining) {
    require(_echo != address(0), 'Mint is not enabled');
    require(mintStart > 0, 'Mint is not enabled');
    require(mintPrice > 0, 'Mint is not enabled');

    if (time < block.timestamp) {
      time = block.timestamp;
    }

    return (mintStart, mintEnd, mintPrice, getRemaining(time));
  }

  function enableMint(uint start, uint end, uint256 price) onlyOwner public {
    mintStart = start;
    mintEnd = end;
    mintPrice = price;
  }

  function setEcho(address echo) onlyOwner public {
    _echo = echo;
  }

  function Echo() view public returns (address) {
    return _echo;
  }

  function setMintMaximum(uint256 max) onlyOwner public {
    mintMaximum = max;
  }

  function MintMaximum() view public returns (uint256) {
    return mintMaximum;
  }
}
