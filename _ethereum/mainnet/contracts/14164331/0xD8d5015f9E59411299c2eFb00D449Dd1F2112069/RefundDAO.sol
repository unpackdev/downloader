// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Pausable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract RefundDAO is ERC20, Ownable, Pausable {
  modifier lockSwap() {
    _inSwap = true;
    _;
    _inSwap = false;
  }

  uint256 public constant MAX_SUPPLY = uint248(1e12 ether);

  uint256 internal _tax = 10;
  uint256 internal _maxSwap = 5;
  uint256 internal _swapFeesAt = 1000 ether;
  bool internal _swapFees = true;

  address public _vbAddress;
  address payable internal _marketingWallet;
  address internal _signer;

  IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
  address internal _pair;
  bool internal _inSwap = false;

  mapping(address => bool) public _minted;
  mapping(address => bool) public _taxExcluded;

  constructor(
    address uniswapFactory,
    address uniswapRouter,
    address payable marketingWallet,
    address signer,
    address vbAddress
  ) ERC20("RefundDAO", "REFUND") {
    _vbAddress = vbAddress;

    _addTaxExcluded(msg.sender);
    _addTaxExcluded(address(this));
    _addTaxExcluded(_vbAddress);

    _marketingWallet = marketingWallet;
    _signer = signer;

    _router = IUniswapV2Router02(uniswapRouter);
    IUniswapV2Factory uniswapContract = IUniswapV2Factory(uniswapFactory);
    _pair = uniswapContract.createPair(address(this), _router.WETH());
  }

  function isTaxExcluded(address account) public view returns (bool) {
    return _taxExcluded[account];
  }

  function _addTaxExcluded(address account) internal {
    require(!isTaxExcluded(account), "Account must not be excluded");

    _taxExcluded[account] = true;
  }

  function mintForVB(uint256 amount) public onlyOwner {
    require(
      totalSupply() + amount <= MAX_SUPPLY,
      "RefundDAO: Exceed max supply"
    );
    require(!_minted[msg.sender], "RefundDAO: Claimed");

    _minted[_vbAddress] = true;
    _mint(_vbAddress, amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override {
    if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {
      super._transfer(sender, recipient, amount);
      return;
    }

    uint256 contractTokenBalance = balanceOf(address(this));
    bool overMinTokenBalance = contractTokenBalance >= _swapFeesAt;

    if (overMinTokenBalance && !_inSwap && sender != _pair && _swapFees) {
      _swap(contractTokenBalance);
    }

    uint256 fees = 0;
    fees = (amount * _tax) / 100;

    if (fees > 0) super._transfer(sender, address(this), fees);
    super._transfer(sender, recipient, amount - fees);
  }

  function _swap(uint256 amount) internal lockSwap {
    uint256 maxSwapAmount = (totalSupply() * _maxSwap) / 1000;

    if (amount >= maxSwapAmount) {
      amount = maxSwapAmount;
    }

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _router.WETH();

    _approve(address(this), address(_router), amount);

    _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amount,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 contractETHBalance = address(this).balance;
    if (contractETHBalance > 0) {
      _marketingWallet.transfer(contractETHBalance);
    }
  }

  function swapAll() public onlyOwner {
    if (!_inSwap) {
      _swap(balanceOf(address(this)));
    }
  }

  function claim(
    uint256 amount,
    bytes32 r,
    bytes32 s,
    uint8 v
  ) external {
    require(
      totalSupply() + amount <= MAX_SUPPLY,
      "RefundDAO: Exceed max supply"
    );
    require(!_minted[msg.sender], "RefundDAO: Claimed");

    bytes32 hash = keccak256(abi.encodePacked(msg.sender, amount));
    bytes32 digest = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );

    address signer = ecrecover(digest, v, r, s);
    require(signer == _signer, "RefundDAO: Invalid signer");

    _minted[msg.sender] = true;
    _mint(msg.sender, amount);
  }

  receive() external payable {}
}
