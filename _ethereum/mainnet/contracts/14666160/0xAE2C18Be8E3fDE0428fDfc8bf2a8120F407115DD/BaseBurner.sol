// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IBurner.sol";
import "./Ownable.sol";
import "./IERC20.sol";

abstract contract BaseBurner is IBurner, Ownable {
    /**
     * @notice The receiver address that will receive the targetToken after burn function is run
     */
    address public receiver;

    /**
     * @notice Burnable tokens mapped to targetTokens
     */
    mapping(address => address) burnableTokens;

    /**
     * @notice Emitted when the receiver is set
     */
    event receiverSet(address oldReceiver, address newReceiver);
    /**
     * @notice Emitted when a token's state in whitelistedToken mapping is set
     */
    event addedBurnableToken(address burnableToken, address targetToken);

    /**
     * @notice Emitted when token is withdrawn from this contract
     */
    event tokenWithdrawn(address token, address to, uint256 amount);

    modifier onlyBurnableToken(address token) {
        require(
            burnableTokens[token] != address(0),
            "token is not whitelisted, please call addBurnableTokens"
        );
        _;
    }

    constructor(address _receiver) {
        receiver = _receiver;
        emit receiverSet(address(0), receiver);
    }

    /* Admin functions */

    /*
     * @notice withdraw tokens from this address to `to` address
     * @param token The token to be withdrawn
     * @param to The receiver of this token withdrawal
     */
    function withdraw(address token, address to) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, balance);
        emit tokenWithdrawn(token, to, balance);
    }

    /*
     * @notice set the receiver of targetToken for this contract
     * @param _receiver The receiver address
     */
    function setReceiver(address _receiver) external onlyOwner {
        address oldReceiver = receiver;
        receiver = _receiver;
        emit receiverSet(oldReceiver, _receiver);
    }

    /*
     * @notice set the burnableTokens of this contract, burnableTokens will be burned for the mapping result
     * @notice set the mapping result as address(0) to unset a token as burnable
     * @param burnableTokens An array of token addresses that are allowed to be burned by this contract
     * @param targetTokens An array of token addresses that are the resultant token received after burning the burnableToken
     */
    function addBurnableTokens(
        address[] calldata _burnableTokens,
        address[] calldata _targetTokens
    ) external virtual {
        require(
            _burnableTokens.length == _targetTokens.length,
            "array length mismatch"
        );
        for (uint256 i = 0; i < _burnableTokens.length; i++) {
            burnableTokens[_burnableTokens[i]] = _targetTokens[i];
            emit addedBurnableToken(_burnableTokens[i], _targetTokens[i]);
        }
    }
}
