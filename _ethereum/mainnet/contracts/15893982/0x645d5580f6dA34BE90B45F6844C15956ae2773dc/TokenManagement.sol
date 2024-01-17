// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./IERC20.sol";

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

contract TokenManagement is Ownable {
    mapping(address => bool) public activeTokens;
    address[] private contracts;
    mapping(bytes32 => bool) transactions;

    event TransferToPolygon(address sender, address token, uint256 value);
    event TransferFromPolygon(
        address reciver,
        address token,
        uint256 value,
        bytes32 transactionId
    );
    event ActiveToken(address token);
    event PauseToken(address token);

    constructor(address DEFE) {
        contracts.push(DEFE);
        activeTokens[DEFE] = true;
    }

    function transferToPolygon(address token, uint256 amount) external {
        require(amount > 0, "transferToPolygon: amount can not be 0");
        require(activeTokens[token], "transferToPolygon: token not support");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit TransferToPolygon(msg.sender, token, amount);
    }

    function transferFromPolygon(
        bytes32 transactionId,
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(!transactions[transactionId], "repeat transactionId ");
        require(activeTokens[token], "transferFromPolygon: token not support");
        IERC20(token).transfer(to, amount);
        transactions[transactionId] = true;
        emit TransferFromPolygon(to, token, amount, transactionId);
    }

    function activeToken(address token) external onlyOwner {
        require(!activeTokens[token], "AddToken: token already supported");
        contracts.push(token);
        activeTokens[token] = true;
        emit ActiveToken(token);
    }

    function pauseToken(address token) external onlyOwner {
        require(activeTokens[token], "PauseToken: token not active");
        activeTokens[token] = false;
        emit PauseToken(token);
    }

    function claimToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function supportTokens() public view returns (address[] memory) {
        return contracts;
    }
}
