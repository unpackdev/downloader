// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract A2Claim is Context, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    event WithdrawEth(address beneficiary, uint256 amount);
    event WithdrawToken(address token, address beneficiary, uint256 amount);
    event ClaimScheduled(uint256 start);
    event Claim(address indexed beneficiary, uint256 amount);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");                   // Admin can set claim start time
    bytes32 public constant QUOTE_SIGNER_ROLE = keccak256("QUOTE_SIGNER_ROLE");     // Quote signer can sign a quote to allow user claim some tokens
    uint256 private constant EXP = 1e18;

    IERC20 public token;                           // Token on sale
    mapping(address=>uint256) public claimed;      // Stores how many tokens already claimed by user
    uint256 public startTimestamp;                 // Timestamp when sale starts

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }


    constructor(address _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());   // DEFAULT_ADMIN_ROLE can grant other roles
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(QUOTE_SIGNER_ROLE, _msgSender());
        token = IERC20(_token);
    }


    function claim(uint256 amount, uint256 quote, bytes calldata quoteSignature) external nonReentrant {
        require(startTimestamp > 0 && startTimestamp <= block.timestamp, "!started");
        require(amount > 0, "zero claim");

        uint256 claimBalance = token.balanceOf(address(this));
        require(claimBalance >= amount, "no funds");

        uint256 newClaimed = claimed[_msgSender()].add(amount);
        require(newClaimed <= quote, "!enough quote");
        require(hasRole(QUOTE_SIGNER_ROLE, recoverSigner(_msgSender(), quote, quoteSignature)), "!valid signature");

        claimed[_msgSender()] = newClaimed;
        token.safeTransfer(_msgSender(), amount);
        emit Claim(_msgSender(), amount);
    }

    function setupClaim(uint256 _startTimestamp) external onlyAdmin {
        require(_startTimestamp > 0, "0 start time");
        startTimestamp = _startTimestamp;
        emit ClaimScheduled(startTimestamp);
    }

    function withdrawEth() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "0 balance");
        address payable beneficiary = payable(_msgSender());
        beneficiary.transfer(balance);
        emit WithdrawEth(beneficiary, balance);
    }

    function withdrawToken(address _token) external onlyAdmin {
        IERC20 tkn = IERC20(_token);
        uint256 tb = tkn.balanceOf(address(this));
        tkn.safeTransfer(_msgSender(), tb);
        emit WithdrawToken(_token, _msgSender(), tb);
    }

    function recoverSigner(address buyer, uint256 quote, bytes memory quoteSignature) public pure returns(address) {
        bytes32 messageHash = keccak256(abi.encode(buyer, quote));
        bytes32 ethHash = messageHash.toEthSignedMessageHash();
        return ethHash.recover(quoteSignature);
    }
}

