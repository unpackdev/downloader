// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Base64.sol";

struct Tick {
  string op;
  uint256 amt;
}

contract INS20 is IERC20, ERC721 {
  uint64 public maxSupply; // 21,000,000
  uint64 public mintLimit; // 1000
  uint64 public lastBlock;
  uint64 public mintedPer;

  // bytes32 public immutable hashPre;
  bytes32 public immutable hash;

  bool public nft2ft;
  // number of tickets minted
  uint128 private tickNumber;
  uint128 internal _totalSupply;

  address public proxy;

  // -------- IERC20 --------
  mapping(address => uint256) internal _balances;
  mapping(address => uint256) internal _insBalances;
  mapping(address => mapping(address => uint256)) private _allowances;
  string private _tick;

  // for svg
  mapping(uint256 => Tick) internal _tickets;

  constructor(
    string memory tick,
    uint64 maxSupply_,
    uint64 mintLimit_,
    address proxy_
  ) ERC721("ins-20", tick) {
    _tick = tick;
    // hashPre = keccak256(
    //   string.concat(
    //     '{"p":"ins-20","op":"mint","tick":"',
    //     bytes(tick),
    //     '","amt":"'
    //   )
    // );
    // hashTail = keccak256(bytes('"}'));
    hash = keccak256(
      string.concat(
        '{"p":"ins-20","op":"mint","tick":"',
        bytes(tick),
        '","amt":"1000"}'
      )
    );
    maxSupply = maxSupply_;
    mintLimit = mintLimit_;
    proxy = proxy_;
  }

  event Inscribe(address indexed from, address indexed to, string data);

  /// @dev Inscribe your first EVM Inscriptions
  /// @dev Use Flashbots for your txes https://docs.flashbots.net/flashbots-protect/quick-start#adding-flashbots-protect-rpc-manually
  function inscribe(bytes calldata data) public {
    require(keccak256(data) == hash, "Inscribe data is wrong.");
    require(tx.origin == msg.sender, "Contracts are not allowed");

    if (block.number > lastBlock) {
      lastBlock = uint64(block.number);
      mintedPer = 0;
    } else {
      require(
        mintedPer < 10,
        "Only 10 ticks per block. Using Flashbots can prevent failed txes."
      );
      unchecked {
        mintedPer++;
      }
    }

    // string memory d = string(data);
    // uint256 amt = extractAmt(d);
    // For lower gas
    uint256 amt = 1000;

    require(amt <= mintLimit, "Exceeded mint limit");
    require(_totalSupply + amt < maxSupply, "Exceeded max supply");
    _mint(msg.sender, tickNumber, amt);

    emit Inscribe(
      address(0),
      msg.sender,
      string(string.concat("data:text/plain;charset=utf-8", data))
    );
  }

  function _mint(address to, uint256 tokenId, uint256 amount) internal {
    _beforeTokenTransfer(address(0), to, tokenId);

    unchecked {
      _totalSupply += uint128(amount);
      _balances[to] += amount;
      _insBalances[msg.sender]++;
    }
    _owners[tokenId] = to;
    _tickets[tokenId] = Tick("mint", amount);

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  /* function extractAmt(string memory json) internal view returns (uint256) {
    // index of amt's value
    uint amtStart = 47;

    bytes memory jsonBytes = bytes(json);
    require(
      jsonBytes.length == 53,
      'Inscribe data is wrong.'
    );

    // verify pre hash
    bytes memory pre = new bytes(amtStart);
    for (uint256 i = 0; i < amtStart; i++) {
      pre[i] = jsonBytes[i];
    }
    require(
      keccak256(pre) == hashPre,
      'Inscribe data is wrong.'
    );

    // index of amt's value end
    uint256 end = amtStart;
    while (end < jsonBytes.length && jsonBytes[end] != '"') {
      end++;
    }

    // get the value of amt
    bytes memory amtBytes = new bytes(end - amtStart);
    for (uint i; i < end - amtStart; i++) {
      amtBytes[i] = jsonBytes[amtStart + i];
    }

    // verify tail hash
    bytes memory tail = new bytes(2);
    tail[0] = jsonBytes[jsonBytes.length - 2];
    tail[1] = jsonBytes[jsonBytes.length - 1];
    require(
      keccak256(tail) == hashTail,
      'Inscribe data is wrong.'
    );

    // convert to uint
    uint result = 0;
    for (uint i = 0; i < amtBytes.length; i++) {
      uint256 amt = uint256(uint8(amtBytes[i]));
      // ASCII
      if (amt < 48 || amt > 57) {
        revert("Non-numeric character encountered");
      }

      result = result * 10 + (amt - 48);
    }
    return result;
  } */

  // -------- IERC20 --------

  function symbol() public view virtual override returns (string memory) {
    return _tick;
  }

  function decimals() public view virtual returns (uint8) {
    return 1;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(
    address owner
  ) public view override(ERC721, IERC20) returns (uint256) {
    require(owner != address(0), "ERC20: address zero is not a valid owner");
    return nft2ft ? _balances[owner] : _insBalances[owner];
  }

  function allowance(
    address owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amountOrTokenID
  ) public override(ERC721, IERC20) {
    if (!nft2ft) {
      ERC721._approve(spender, amountOrTokenID);
    } else {
      address owner = msg.sender;
      _approve(owner, spender, amountOrTokenID);
    }
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override {
    if (!nft2ft) {
      ERC721.setApprovalForAll(operator,approved);
    }
  }

  // only for FT
  function transfer(
    address to,
    uint256 amount
  ) external override returns (bool) {
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
  ) public override(ERC721, IERC20) returns (bool) {
    require(from != address(0), "INS20: transfer from the zero address");
    require(to != address(0), "INS20: transfer to the zero address");

    if (!nft2ft) {
      require(
        _isApprovedOrOwner(_msgSender(), tokenIdOrAmount),
        "ERC721: caller is not token owner nor approved"
      );
      _transfer721(from, to, tokenIdOrAmount);
    } else {
      _spendAllowance(from, msg.sender, tokenIdOrAmount);
      _transfer20(from, to, tokenIdOrAmount);
    }

    return true;
  }

  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    if(nft2ft) emit Approval(owner, spender, amount);
  }

  function _transfer20(address from, address to, uint256 amount) internal {
    _beforeTokenTransfer(from, to, amount);
    // transfer like erc20
    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
    }
    _balances[to] += amount;

    string memory t = string(
      string.concat(
        '{"p":"ins-20","op":"transfer","tick":"INSC","amt":"',
        bytes(toString(amount)),
        '"}'
      )
    );
    emit Inscribe(
      from,
      to,
      string(string.concat("data:text/plain;charset=utf-8", bytes(t)))
    );
    _afterTokenTransfer(from, to, amount);
    if (nft2ft) emit Transfer(from, to, amount);
  }

  // -------- IERC721 --------

  // just for erc721 transfer
  function _transfer721(address from, address to, uint256 tokenId) internal {
    // transfer like erc721
    ERC721._transfer(from, to, tokenId);

    // transfer like erc20
    _transfer20(from, to, _tickets[tokenId].amt);
    _insBalances[from] -= 1;
    _insBalances[to] += 1;

    emit Transfer(from, to, tokenId);

    ERC721._approve(address(0), tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    require(
      !nft2ft,
      "Not support ERC721 any more."
    );
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override {
    require(
      !nft2ft,
      "Not support ERC721 any more."
    );
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: caller is not token owner nor approved"
    );
    _transfer721(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function toFT() public {
    require(!nft2ft && proxy == msg.sender, "Has done");
    nft2ft = true;
  }

  // metadata
  function tokenURI(
    uint256 tokenID
  ) public view virtual override returns (string memory) {
    require(
      !nft2ft,
      "Not support ERC721 any more."
    );
    string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="100" y="100" class="base">{</text><text x="130" y="130" class="base">"p":"ins-20",</text><text x="130" y="160" class="base">"op":"';

    bytes memory data;


    data = abi.encodePacked(
      output,
      bytes(_tickets[tokenID].op),
      '",</text><text x="130" y="190" class="base">"tick":"insc",</text><text x="130" y="220" class="base">"amt":'
    );
    data = abi.encodePacked(
      data,
      bytes(toString(_tickets[tokenID].amt)),
      '</text><text x="100" y="250" class="base">}</text></svg>'
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"description": "INS20 is a social experiment, a first attempt to practice inscription within the EVM.", "image": "data:image/svg+xml;base64,',
            Base64.encode(data),
            '"}'
          )
        )
      )
    );
    output = string(abi.encodePacked("data:application/json;base64,", json));
    return output;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC721) {
    if (from == address(0)) {
      tickNumber++;
    }
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {}

  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}
