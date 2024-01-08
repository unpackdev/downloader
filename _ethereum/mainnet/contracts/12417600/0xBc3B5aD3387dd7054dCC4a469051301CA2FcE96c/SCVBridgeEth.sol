// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ApproveAndCallFallBack.sol";


contract SCVBridgeEth is ApproveAndCallFallBack, AccessControl {
    using SafeERC20 for IERC20;

    // if we use ERC20 event people would just transfer tokens directly
    event ReceivedToken(address indexed from, uint256 amount);

    address private _token;     // token address
    address private _receiver;  // token receiver, default to this contract
    uint256 private _epoch;     // custom epoch
    uint256 private _quotaPerDay;   // quota
    mapping(uint256 => uint256) private _receivedTokens; // date to limit mapping

    bytes32 public ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(uint256 epoch_, uint256 quotaPerDay_, address token_) {
        _epoch = epoch_;
        _quotaPerDay = quotaPerDay_;
        _token = token_;
        _receiver = address(this);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "ADMIN_ROLE required");
        _;
    }

    function receiver() public view returns (address) {
        return _receiver;
    }

    // returns token address
    function token() public view returns (address) {
        return _token;
    }

    // returns daily limit
    function quota() public view returns (uint256) {
        return _quotaPerDay;
    }

    // days since custom epoch
    function daysSinceEpoch() public view returns (uint256) {
        return (block.timestamp - _epoch) / (3600 * 24);
    }

    // remaining quota for today
    function remainingQuota() public view returns (uint256) {
        uint256 got = _receivedTokens[daysSinceEpoch()];
        if (got >= _quotaPerDay) {
            return 0;
        } else {
            return _quotaPerDay - got;
        }
    }

    // total received tokens by date
    function receivedForDate(uint256 dateSinceEpoch) public view returns (uint256) {
        return _receivedTokens[dateSinceEpoch];
    }

    // transfer token to address
    function withdrawTo(address to, uint256 amount) public onlyAdmin {
        IERC20(_token).safeTransfer(to, amount);
    }

    // update limit per day
    function updateQuota(uint256 newLimit) public onlyAdmin {
        _quotaPerDay = newLimit;
    }

    function updateReceiver(address newReceiver) public onlyAdmin {
        _receiver = newReceiver;
    }

    // callback for 'ApproveAndCallFallBack' interface
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public override {
        require(tokens > 0, "Amount should > 0");
        require(token == _token, "Wrong token");
        uint256 day = daysSinceEpoch();
        require(_receivedTokens[day] + tokens <= _quotaPerDay, "Transfer exceeds daily quota");
        IERC20(token).safeTransferFrom(from, _receiver, tokens);
        _receivedTokens[day] += tokens;

        emit ReceivedToken(from, tokens);
    }
}
