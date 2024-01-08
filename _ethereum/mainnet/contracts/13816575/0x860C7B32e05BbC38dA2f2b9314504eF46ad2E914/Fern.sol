//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Fern is Context, IERC20, IERC20Metadata, Ownable {
  using SafeMath for uint256;

  uint256 public constant EMISSION_PER_DAY = 30 * (10 ** 18);

  uint256 public emissionStart;
  uint256 public emissionEnd;
  mapping(address => bool) public allowedAddress;

  mapping(uint256 => uint256) private _lastClaim;
  address private _nftAddress;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;

  constructor(string memory tokenName, string memory tokenSymbol)
  {
    _name = tokenName;
    _symbol = tokenSymbol;
    _mint(msg.sender, 91240875 * 10 ** decimals());// 20% is for community activity, commiter and developers
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public view override returns (uint8) {
    return 18;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    if (!allowedAddress[msg.sender]) {
      uint256 currentAllowance = _allowances[sender][_msgSender()];
      require(currentAllowance >= amount, "exceeds allowance");
      unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
      }
    }
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "zero address");
    require(recipient != address(0), "zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "zero address");
    require(spender != address(0), "zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

  function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

  function burn(uint256 amount) public {
      _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public virtual {
      uint256 currentAllowance = allowance(account, _msgSender());
      require(currentAllowance >= amount, "exceeds allowance");
      unchecked {
          _approve(account, _msgSender(), currentAllowance - amount);
      }
      _burn(account, amount);
  }

  function setEmissionStart() public onlyOwner {
    require(emissionStart == 0);
    require(emissionEnd == 0);

    emissionStart = block.timestamp;
    emissionEnd = emissionStart + (86400 * 365 * 10);
  }

  function setNftAddress(address nftAddress) public onlyOwner {
    require(_nftAddress == address(0));

    _nftAddress = nftAddress;
  }

  function setAllowedAddress(address nftAddress, bool allowed) public onlyOwner {
    allowedAddress[nftAddress] = allowed;
  }

  function lastClaim(uint256 tokenId) public view returns (uint256) {
    require(IERC721Enumerable(_nftAddress).ownerOf(tokenId) != address(0));

    uint256 lastClaimed = uint256(_lastClaim[tokenId]) != 0 ? uint256(_lastClaim[tokenId]) : emissionStart;
    return lastClaimed;
  }

  function accumulated(uint256 tokenId) public view returns (uint256) {
    require(emissionStart != 0);
    require(IERC721Enumerable(_nftAddress).ownerOf(tokenId) != address(0));

    uint256 lastClaimed = lastClaim(tokenId);

    if (lastClaimed >= emissionEnd) return 0;

    uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd;
    uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(EMISSION_PER_DAY).div(86400);

    return totalAccumulated;
  }

  function claim(uint256[] memory tokenIds) public returns (uint256) {
    require(emissionStart != 0, "not yet");

    uint256 totalClaimQty = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      require(tokenIds[i] <= IERC721Enumerable(_nftAddress).totalSupply(), "invalid");
      for (uint j = i + 1; j < tokenIds.length; j++) {
        require(tokenIds[i] != tokenIds[j], "duplicate");
      }

      uint tokenId = tokenIds[i];
      require(IERC721Enumerable(_nftAddress).ownerOf(tokenId) == msg.sender, "invalid");

      uint256 claimQty = accumulated(tokenId);
      if (claimQty != 0) {
        totalClaimQty = totalClaimQty.add(claimQty);
        _lastClaim[tokenId] = block.timestamp;
      }
    }

    require(totalClaimQty != 0, "zero");
    _mint(msg.sender, totalClaimQty);
    return totalClaimQty;
  }  
}