// SPDX-License-Identifier: MIT
// HS to HNS Bridge Project

pragma solidity ^0.8.20;

interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}
interface IERC721Errors {
    error ERC721InvalidOwner(address owner);
    error ERC721NonexistentToken(uint256 tokenId);
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
    error ERC721InvalidSender(address sender);
    error ERC721InvalidReceiver(address receiver);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidOperator(address operator);
}
interface IERC1155Errors {
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);
    error ERC1155InvalidSender(address sender);
    error ERC1155InvalidReceiver(address receiver);
    error ERC1155MissingApprovalForAll(address operator, address owner);
    error ERC1155InvalidApprover(address approver);
    error ERC1155InvalidOperator(address operator);
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }
}

// HS to HNS Bridge Project

contract HandShake is ERC20, Ownable {
    address payable public treasuryAddress;
    uint256 public maxSupply = 2000000000 * 10**18; // 2 billion tokens total circulation
    uint256 public treasuryBalance = 500000000 * 10**18; // 500 million tokens for treasury and liqidity pool allocation
    uint256 public claimableAmount = 1500000000 * 10**18; // 1.5 billion tokens claimable allocation
    uint256 public claimAmount = 2000 * 10**18; // 2000 HS tokens per claim on launch
    uint256 public claimFee = 0.0005 ether; // 0.0005 ETH fee per claim on launch

    event Claim(address indexed claimer, uint256 amount);
    event ClaimAmountUpdated(uint256 newClaimAmount);
    event ClaimFeeUpdated(uint256 newClaimFee);

    constructor() ERC20("HS", "HS") Ownable(msg.sender) {
        _mint(address(this), maxSupply); // Mint total supply to contract
        _transfer(address(this), msg.sender, treasuryBalance); // Transfer treasury allocation to treasury contract owner
        treasuryAddress = payable(msg.sender);
    }

    modifier onlyTreasury() {
        require(msg.sender == treasuryAddress, "Not the treasury address");
        _;
    }

    modifier canClaim() {
        require(claimableAmount > 0, "No more tokens available for claim");
        require(balanceOf(address(this)) >= claimAmount, "Insufficient balance in contract");
        _;
    }

    function claim() external payable canClaim {
        require(msg.value == claimFee, "Incorrect claim fee");
        _transfer(address(this), msg.sender, claimAmount);
        claimableAmount -= claimAmount;
        treasuryAddress.transfer(msg.value);
        emit Claim(msg.sender, claimAmount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        treasuryAddress.transfer(amount);
    }

    // Allows treasury the ability to modify the HS claim amount per claim

    function updateClaimAmount(uint256 newClaimAmount) external onlyOwner {
        require(newClaimAmount > 0, "Claim amount must be greater than zero");
        claimAmount = newClaimAmount;
        emit ClaimAmountUpdated(newClaimAmount);
    }

    // Allows treasury the ability to modify ETH claim fee for HS claims

    function updateClaimFee(uint256 newClaimFee) external onlyOwner {
        claimFee = newClaimFee;
        emit ClaimFeeUpdated(newClaimFee);
    }
}