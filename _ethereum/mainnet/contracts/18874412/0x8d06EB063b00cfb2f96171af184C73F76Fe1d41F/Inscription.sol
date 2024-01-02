// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./Base64.sol";

struct Tick {
  string op;
  uint256 amt;
}

contract INS20 is IERC20, ERC721 {
  uint64 public maxSupply; // 21,000,000
  uint64 public initialBlockNum;
  uint64 public amtDifficulty; // initial 10
  uint64 public blockDifficulty; // initial 1000
  uint64 public totalSupplyDifficulty; // initial 10,0000

  uint64 public lastBlock;
  uint64 public mintedPer; // 100 per block
  uint64 public perTxLimitAmount;
  uint64 public perWalletLimitAmount;

  // bytes32 public immutable hashPre;
  // bytes32 public immutable hash;

  bool public nft2ft;
  // number of tickets minted
  uint128 private tickNumber;
  uint128 internal _totalSupply;
  
  uint256 internal totalVotesAmount;

  address public proxy;

  // -------- IERC20 --------
  mapping(address => uint256) internal _balances;       // erc20 amount
  mapping(address => uint256) internal _insBalances;    // nft amount
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(uint256 => bool) internal _voted;
  string private _tick;

  // for svg
  mapping(uint256 => Tick) internal _tickets;

  constructor(
    string memory tick,
    uint64 maxSupply_,
    uint64 perWalletLimitAmount_,
    uint64 perTxLimitAmount_,
    address proxy_,
    uint64 initialBlockNum_,
    uint64 amtDifficulty_,
    uint64 blockDifficulty_,
    uint64 totalSupplyDifficulty_
  ) ERC721("fair-ins20", tick) {
    _tick = tick;
    
    maxSupply = maxSupply_;
    perWalletLimitAmount = perWalletLimitAmount_;
    perTxLimitAmount = perTxLimitAmount_;
    proxy = proxy_;
    initialBlockNum = initialBlockNum_;
    amtDifficulty = amtDifficulty_;
    blockDifficulty = blockDifficulty_;
    totalSupplyDifficulty = totalSupplyDifficulty_;
  }

  event Inscribe(address indexed from, address indexed to, string data);

  /// @dev Inscribe your first EVM Inscriptions
  /// @dev Use Flashbots for your txes https://docs.flashbots.net/flashbots-protect/quick-start#adding-flashbots-protect-rpc-manually
  function inscribe(uint256 amount) public {
    require(amount > 0, "Amount must be greater than zero");
    require(amount <= perTxLimitAmount, "Exceeded per tx limit");
    require(
      _balances[msg.sender] + amount <= perWalletLimitAmount,
      "Exceeded per wallet limit"
    );

    require(_totalSupply + amount <= maxSupply, "Exceeded max supply");
    
    require(tx.origin == msg.sender, "Contracts are not allowed");

    require(mintingAlgo(uint64(block.number), amount), "Minting algo failed");

    if (block.number > lastBlock) {
      lastBlock = uint64(block.number);
      mintedPer = 0;
    } else {
      require(
        mintedPer < 100,
        "Only 100 ticks per block. Using Flashbots can prevent failed txes."
      );
      unchecked {
        mintedPer++;
      }
    }

    string memory data = string.concat(
        '{"p":"ins-20","op":"mint","tick":"',
        _tick,
        '","amt":"',
        Strings.toString(amount),
        '"}'
      );

    _mint(msg.sender, tickNumber, amount);

    emit Inscribe(
      address(0),
      msg.sender,
      string(string.concat("data:text/plain;charset=utf-8", data))
    );
  }

  function mintingAlgo(uint64 currentBlockNum, uint256 amount) public view returns (bool) {
    uint256 random = uint256(keccak256(abi.encodePacked(currentBlockNum, amount, msg.sender, _totalSupply + 1)));

    uint256 decreasingFactor = currentBlockNum > initialBlockNum ? currentBlockNum - initialBlockNum : 1;
    // amtDifficulty = 10
    // blockDifficulty = 1000
    // totalSupplyDifficulty = 100000
    uint256 difficulty = 
      Math.sqrt(amount / amtDifficulty + 1) + 
      Math.sqrt(decreasingFactor / blockDifficulty) + 
      Math.sqrt(_totalSupply / totalSupplyDifficulty);

    return random % difficulty == 0;
  }

  function voteForFT(uint256[] calldata tokenIds) public {
    require(!nft2ft, "Has done");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_owners[tokenIds[i]] == msg.sender, "Not owner");
      require(!_voted[tokenIds[i]], "Has voted");
      _voted[tokenIds[i]] = true;
      totalVotesAmount += _tickets[tokenIds[i]].amt;
    }

    if (totalVotesAmount > maxSupply / 2) {
      nft2ft = true;
    }
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
      ERC721.approve(spender, amountOrTokenID);
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

    string memory t = string.concat(
        '{"p":"ins-20","op":"transfer","tick":"FAIR","amt":"',
        Strings.toString(amount),
        '"}'
      );
    emit Inscribe(
      from,
      to,
      string(string.concat("data:text/plain;charset=utf-8", t))
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

  function setInitBlockNum(uint64 initialBlockNum_) public {
    require(proxy == msg.sender, "Sender is not proxy");
    initialBlockNum = initialBlockNum_;
  }

  function setDifficulty(uint64 amtDifficulty_, uint64 blockDifficulty_, uint64 totalSupplyDifficulty_) public {
    require(proxy == msg.sender, "Sender is not proxy");
    amtDifficulty = amtDifficulty_;
    blockDifficulty = blockDifficulty_;
    totalSupplyDifficulty = totalSupplyDifficulty_;
  }

  function setProxy(address proxy_) public {
    require(proxy == msg.sender, "Sender is not proxy");
    proxy = proxy_;
  }

  function totalVotedAmount() public view returns (uint256) {
    return totalVotesAmount;
  }

  // metadata
  function tokenURI(
    uint256 tokenID
  ) public view virtual override returns (string memory) {
    require(
      !nft2ft,
      "Not support ERC721 any more."
    );
    string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <style>.base { fill: green; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="100" y="100" class="base">{</text><text x="130" y="130" class="base">"p":"ins-20",</text><text x="130" y="160" class="base">"op":"';

    bytes memory data;


    data = abi.encodePacked(
      output,
      bytes(_tickets[tokenID].op),
      '",</text><text x="130" y="190" class="base">"tick":"fair",</text><text x="130" y="220" class="base">"amt":'
    );
    data = abi.encodePacked(
      data,
      bytes(Strings.toString(_tickets[tokenID].amt)),
      '</text><text x="100" y="250" class="base">}</text></svg>'
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"description": "FAIR-INS20 is a social experiment and a fair distribution of INS20.", "image": "data:image/svg+xml;base64,',
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

}