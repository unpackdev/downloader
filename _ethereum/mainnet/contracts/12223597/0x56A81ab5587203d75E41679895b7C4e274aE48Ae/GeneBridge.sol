pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Manageable.sol";

contract GeneBridge is Manageable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct TokenInfo {
        address tokenAddr;
        uint256 fee;
        uint256 min;
        uint256 max;
        bool pause;
    }

    event CrossIn(address indexed sender, address indexed receiver, address indexed token, uint256 amount, uint256 receipts);
    event TokenAdded(TokenInfo[] tokens);
    event TokenRemoved(address[] tokens);
    event TokenPaused(address[] tokens);
    event TokenUnPaused(address[] tokens);

    mapping(address => TokenInfo) public _allowTokens;

    constructor(TokenInfo[] memory tokens) public {
        addOperator(msg.sender);
        setTokens(tokens);
    }

    function crossIn(address token, address receiver, uint256 amount) external whenNotPaused {
        TokenInfo storage tokenInfo = _allowTokens[token];

        require(tokenInfo.tokenAddr != address(0), 'GENE-BRIDGE: unsupported token');
        require(!tokenInfo.pause, 'GENE-BRIDGE: paused');
        require(amount >= tokenInfo.min && (tokenInfo.max == 0 || amount <= tokenInfo.max), 'GENE-BRIDGE: amount error');

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 receipts = amount.sub(tokenInfo.fee);

        emit CrossIn(msg.sender, receiver, token, amount, receipts);
    }

    function setTokens(TokenInfo[] memory tokens) public onlyOperator {
        address addr;
        for (uint256 i = 0; i < tokens.length; i ++) {
            addr = tokens[i].tokenAddr;

            // already exists
            if (_allowTokens[addr].tokenAddr != address(0)) {
                delete _allowTokens[addr];
            }
            _allowTokens[addr] = tokens[i];
        }

        emit TokenAdded(tokens);
    }

    function removeTokens(address[] calldata tokens) external onlyOperator {
        for (uint256 i = 0; i < tokens.length; i ++) {
            delete _allowTokens[tokens[i]];
        }

        emit TokenRemoved(tokens);
    }
}
