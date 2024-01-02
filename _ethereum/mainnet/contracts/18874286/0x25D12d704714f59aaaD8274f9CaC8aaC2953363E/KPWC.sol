// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721.sol";
import "./IERC20.sol";

import "./Base64.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

struct Tick {
  string op;
  uint256 amt;
}

struct Rules {
  uint256 supply;
  uint256 limit;
  uint256 freePerWallet;
  uint256 price;
}

contract KPWC is IERC20Fix, ERC721, Ownable, ReentrancyGuard {
  bool public nft2ft;

  uint128 private tickNumber;
  uint128 internal _totalSupply;

  Rules public rules;

  // -------- IERC20 --------
  mapping(address => uint256) internal _balances;
  mapping(address => uint256) internal _insBalances;

  mapping(address => mapping(address => uint256)) private _allowances;
  string private _tick;

  // for svg
  mapping(uint256 => Tick) internal _tickets;

  constructor(string memory tick) ERC721("kpwc-20", tick) {
    _tick = tick;
  }

  event Inscribe(address indexed from, address indexed to, string data);

  function inscribe(uint256 amt) public payable {
    require(amt <= rules.limit, "Exceeded mint limit");
    require(_totalSupply + amt < rules.supply, "Exceeded max supply");
    require(amt % 1000 == 0, "Amount must be a multiple of 1000");
    require(tx.origin == msg.sender, "Contracts are not allowed");

    uint256 _paidQuantity = _calculatePaidQuantity(msg.sender, amt, rules.freePerWallet);

    require(_paidQuantity == 0 || msg.value >= rules.price * _paidQuantity, "Invalid ether value");

    _mint(msg.sender, amt);

    emit Inscribe(
      address(0),
      msg.sender,
      string.concat(
        "data:text/plain;charset=utf-8",
        '{"p":"erc-20","op":"mint","tick":"',
        _tick,
        '","amt":',
        Strings.toString(amt),
        "}"
      )
    );
  }

  function setRules(Rules calldata _rules) external onlyOwner {
    rules = _rules;
  }

  function _mint(address to, uint256 amount) internal override {
    _beforeTokenTransfer(address(0), to, tickNumber);

    unchecked {
      _totalSupply += uint128(amount);
      _balances[to] += amount;
      _insBalances[msg.sender]++;
    }

    _owners[tickNumber] = to;
    _tickets[tickNumber] = Tick("mint", amount);

    emit Transfer(address(0), to, tickNumber);

    _afterTokenTransfer(address(0), to, tickNumber);
  }

  function _calculatePaidQuantity(
    address _owner,
    uint256 _quantity,
    uint256 _freeQuantity
  ) internal view returns (uint256) {
    uint256 _alreadyMinted = _balances[_owner];
    uint256 _freeQuantityLeft = _alreadyMinted >= _freeQuantity ? 0 : _freeQuantity - _alreadyMinted;

    return _freeQuantityLeft >= _quantity ? 0 : _quantity - _freeQuantityLeft;
  }

  function withdraw() external onlyOwner nonReentrant {
    payable(msg.sender).transfer(address(this).balance);
  }

  // -------- IERC20 --------

  function symbol() public view virtual override returns (string memory) {
    return _tick;
  }

  function decimals() public view virtual returns (uint8) {
    return 0;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view override(ERC721, IERC20Fix) returns (uint256) {
    require(owner != address(0), "ERC20: address zero is not a valid owner");
    return nft2ft ? _balances[owner] : _insBalances[owner];
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amountOrTokenID) public virtual override(ERC721, IERC20Fix) {
    if (!nft2ft) {
      ERC721._approve(spender, amountOrTokenID);
    } else {
      address owner = msg.sender;
      _approve(owner, spender, amountOrTokenID);
    }
  }

  function setApprovalForAll(address operator, bool approved) public override {
    if (!nft2ft) {
      ERC721.setApprovalForAll(operator, approved);
    }
  }

  // only for FT
  function transfer(address to, uint256 amount) external override returns (bool) {
    if (nft2ft) {
      require(to != address(0), "ERC20: transfer to the zero address");
      _transfer20(msg.sender, to, amount);
    }
    return nft2ft;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenIdOrAmount
  ) public override(ERC721, IERC20Fix) returns (bool) {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    if (!nft2ft) {
      require(_isApprovedOrOwner(_msgSender(), tokenIdOrAmount), "ERC721: caller is not token owner nor approved");
      _transfer721(from, to, tokenIdOrAmount);
    } else {
      _spendAllowance(from, msg.sender, tokenIdOrAmount);
      _transfer20(from, to, tokenIdOrAmount);
    }

    return true;
  }

  function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    if (nft2ft) emit Approval(owner, spender, amount);
  }

  function _transfer20(address from, address to, uint256 amount) internal {
    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
    }
    _balances[to] += amount;

    string memory t = string(
      string.concat('{"p":"erc-20","op":"transfer","tick":",', _tick, '","amt":"', Strings.toString(amount), '"}')
    );

    emit Inscribe(from, to, string(string.concat("data:text/plain;charset=utf-8", t)));
    _afterTokenTransfer(from, to, amount);

    if (nft2ft) emit Transfer(from, to, amount);
  }

  // -------- IERC721 --------

  function _transfer721(address from, address to, uint256 tokenId) internal {
    ERC721._transfer(from, to, tokenId);

    _transfer20(from, to, _tickets[tokenId].amt);
    _insBalances[from] -= 1;
    _insBalances[to] += 1;

    emit Transfer(from, to, tokenId);

    ERC721._approve(address(0), tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    require(!nft2ft, "Not support ERC721 any more.");
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
    require(!nft2ft, "Not support ERC721 any more.");
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
    _transfer721(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function toFT() public onlyOwner {
    require(!nft2ft, "Has done");
    nft2ft = true;
  }

  // metadata
  function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
    require(!nft2ft, "Not support ERC721 any more.");
    string
      memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="100" y="100" class="base">{</text><text x="130" y="130" class="base">"p":"erc-20",</text><text x="130" y="160" class="base">"op":"';

    bytes memory data;

    data = abi.encodePacked(
      output,
      _tickets[tokenID].op,
      '",</text><text x="130" y="190" class="base">"tick":"',
      _tick,
      '",</text><text x="130" y="220" class="base">"amt":'
    );
    data = abi.encodePacked(
      data,
      Strings.toString(_tickets[tokenID].amt),
      '</text><text x="100" y="250" class="base">}</text></svg>'
    );

    string memory json = Base64.encode(
      bytes(string(abi.encodePacked('{"image": "data:image/svg+xml;base64,', Base64.encode(data), '"}')))
    );
    output = string(abi.encodePacked("data:application/json;base64,", json));
    return output;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    if (from == address(0)) {
      tickNumber = tickNumber + 1;
    }
  }
}
