// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract ERC20Claim is Context, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    event WithdrawEth(address beneficiary, uint256 amount);
    event WithdrawToken(address indexed token, address beneficiary, uint256 id, uint256 amount);
    event DistributionScheduled(address indexed token, uint256 start);
    event Claim(address indexed token, address indexed beneficiary, uint256 amount);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");                   // Admin can set claim start time
    bytes32 public constant QUOTE_SIGNER_ROLE = keccak256("QUOTE_SIGNER_ROLE");     // Quote signer can sign a quote to allow user claim some tokens
    uint256 private constant EXP = 1e18;

    struct TokenDistribution {
        uint256 startTimestamp;                 // Timestamp when users can start claiming
        mapping(address=>uint256) claimed;      // Stores how many tokens already claimed by user
    }
    mapping(IERC20=>TokenDistribution) public distributions;


    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }


    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());   // DEFAULT_ADMIN_ROLE can grant other roles
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(QUOTE_SIGNER_ROLE, _msgSender());
    }


    function claim(IERC20 token, uint256 amount, uint256 quote, bytes calldata quoteSignature) external nonReentrant {
        TokenDistribution storage distribution = distributions[token];
        require(distribution.startTimestamp > 0, '!found');
        require(distribution.startTimestamp <= block.timestamp, "!started");
        require(amount > 0, "zero claim");

        uint256 claimBalance = token.balanceOf(address(this));
        require(claimBalance >= amount, "no funds");

        uint256 newClaimed = distribution.claimed[_msgSender()].add(amount);
        require(newClaimed <= quote, "!enough quote");
        require(hasRole(QUOTE_SIGNER_ROLE, recoverSigner(address(token), _msgSender(), quote, quoteSignature)), "!valid signature");

        distribution.claimed[_msgSender()] = newClaimed;
        token.safeTransfer(_msgSender(), amount);
        emit Claim(address(token), _msgSender(), amount);
    }

    function setupClaim(IERC20 token, uint256 _startTimestamp) external onlyAdmin {
        require(address(token) != address(0), "0 token");
        require(_startTimestamp > 0, "0 start time");
        TokenDistribution storage distribution = distributions[token];
        distribution.startTimestamp = _startTimestamp;
        emit DistributionScheduled(address(token), _startTimestamp);
    }

    function withdrawEth() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "0 balance");
        address payable beneficiary = payable(_msgSender());
        beneficiary.transfer(balance);
        emit WithdrawEth(beneficiary, balance);
    }

    function withdrawERC20(IERC20 token) external onlyAdmin {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), balance);
        emit WithdrawToken(address(token), _msgSender(), 0, balance);
    }

    function withdrawERC721(IERC721 token, uint256 id) external onlyAdmin {
        token.transferFrom(address(this), _msgSender(), id);
        emit WithdrawToken(address(token), _msgSender(), id, 1);
    }

    function withdrawERC1155(IERC1155 token, uint256 id, uint256 amount, bytes calldata data) external onlyAdmin {
        token.safeTransferFrom(address(this), _msgSender(), id, amount, data);
        emit WithdrawToken(address(token), _msgSender(), id, amount);
    }

    function recoverSigner(address token, address buyer, uint256 quote, bytes memory quoteSignature) public pure returns(address) {
        bytes32 messageHash = keccak256(abi.encode(token, buyer, quote));
        bytes32 ethHash = messageHash.toEthSignedMessageHash();
        return ethHash.recover(quoteSignature);
    }
}

