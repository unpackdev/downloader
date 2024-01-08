// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./BridgeToken.sol";
import "./SafeERC20.sol";

/*
 *  @title: EvrnetBank
 *  @dev: Eth bank which locks ETH/ERC20/ERC721 token deposits, and unlocks
 *        ETH/ERC20/ERC721 tokens once the prophecy has been successfully processed.
 */
contract EthBank {
    using SafeERC20 for BridgeToken;

    uint256 public lockBurnNonce;
    struct RefundData {
        bool isRefunded;
        uint256 nonce;
        address sender;
        address tokenAddress;
        uint256 amount;
    }
    struct UnlockData {
        bool isUnlocked;
        address operator;
        address recipient;
        address tokenAddress;
        uint256 amount;
    }
    // Mapping and check if the refunds transaction is completed
    mapping(uint256 => RefundData) internal refundCompleted;
    // Mapping and check if the unlock transaction is completed
    mapping(bytes32 => UnlockData) internal unlockCompleted;

    // For erc20
    /*
     * @dev: Event declarations
     */
    event LogLock(
        address _from,
        address _to,
        address _token,
        string _symbol,
        uint256 _value,
        uint256 _nonce,
        string _chainName
    );

    event LogUnlock(
        address _to,
        address _token,
        string _symbol,
        uint256 _value,
        bytes32 _interchainTX
    );

    event LogRefund(
        address _to,
        address _token,
        string _symbol,
        uint256 _value,
        uint256 _nonce
    );

    /*
     * @dev: Modifier declarations
     */

    modifier availableNonce() {
        require(lockBurnNonce + 1 > lockBurnNonce, "No available nonces.");
        _;
    }
    /*
     * @dev: Gets the amount of locked/funded tokens by address.
     *
     * @param _symbol: The asset's symbol.
     */
    function getLockedFunds(address _token) public view returns (uint256) {

        if (_token == address(0)) {
            return address(this).balance;
        }
        return BridgeToken(_token).balanceOf(address(this));
    }

    /*
     * @dev: Creates a new Evrynet deposit with a unique id.
     *
     * @param _sender: The sender's ethereum address.
     * @param _recipient: The intended recipient's evrnet address.
     * @param _token: The currency type, either erc20 or ethereum.
     * @param _amount: The amount of erc20 tokens/ ethereum (in wei) to be itemized.
     */
    function lockFunds(
        address payable _sender,
        address _recipient,
        address _token,
        string memory _symbol,
        uint256 _amount,
        string memory _chainName
    ) internal {
        lockBurnNonce++;

        refundCompleted[lockBurnNonce] = RefundData(
            false,
            lockBurnNonce,
            _sender,
            _token,
            _amount
        );

        emit LogLock(
            _sender,
            _recipient,
            _token,
            _symbol,
            _amount,
            lockBurnNonce,
            _chainName
        );
    }
    /*
     * @dev: Unlocks funds held on contract and sends them to the
     *       intended recipient
     *
     * @param _recipient: recipient's Evrynet address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function unlockFunds(
        address payable _recipient,
        address _token,
        string memory _symbol,
        uint256 _amount,
        bytes32 _interchainTX
    ) internal {
        // Transfer funds to intended recipient
        if (_token == address(0)) {
            _recipient.transfer(_amount);
        } else {
            BridgeToken(_token).safeTransfer(_recipient, _amount);
        }
        unlockCompleted[_interchainTX] = UnlockData(
            true,
            address(this),
            _recipient,
            _token,
            _amount
        );

        emit LogUnlock(_recipient, _token, _symbol, _amount, _interchainTX);
    }

    /*
     * @dev: Unlocks funds held on contract and sends them to the
     *       intended recipient
     *
     * @param _recipient: recipient's Evrynet address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function refunds(
        address payable _recipient,
        address _tokenAddress,
        string memory _symbol,
        uint256 _amount,
        uint256 _nonce
    ) internal {
        // Transfer funds to intended recipient
        if (_tokenAddress == address(0)) {
            _recipient.transfer(_amount);
        } else {
            BridgeToken(_tokenAddress).safeTransfer(_recipient, _amount);
        }
        refundCompleted[_nonce].isRefunded = true;
        emit LogRefund(_recipient, _tokenAddress, _symbol, _amount, _nonce);

    }   
}
