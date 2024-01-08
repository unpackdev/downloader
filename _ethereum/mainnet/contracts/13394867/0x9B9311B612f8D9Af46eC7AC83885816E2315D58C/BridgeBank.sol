// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./EthBank.sol";
import "./BridgeBankPausable.sol";
import "./Ownable.sol";
import "./LockTimer.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";
/**
 * @title BridgeBank
 * @dev Bank contract which coordinates asset-related functionality.
 *      EthBank manages the locking and unlocking of ETH/ERC20 token assets
 *      based on eth.
 **/

contract BridgeBank is Initializable, EthBank, BridgeBankPausable, Ownable, LockTimer{
    using SafeERC20 for BridgeToken;
    
    address public operator;
    
    /*
     * @dev: Constructor, sets operator
     */
    function initialize(
        address _operatorAddress
    ) public payable initializer {
        operator = _operatorAddress;
        owner = msg.sender;
        lockBurnNonce = 0;
        _paused = false;
    }

    /*
     * @dev: Modifier to restrict access to operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be BridgeBank operator.");
        _;
    }
    /*
     * @dev: Change to new Operator
     *
     */
    function changeOperator(address _newOperator)
        public
        isOwner
    {
        operator = _newOperator;
    }

    /*
     * @dev: Fallback function allows anyone to send funds to the bank directly
     * 
     */
    fallback () external payable { }

    /**
     * @dev Pauses all functions.
     * Set timestamp for current pause
     */
    function pause() public isOwner {
        _pause();

        _setPausedAt();
    }


    /**
     * @dev Unpauses all functions.
     */
    function unpause() public isOwner {
        _unpause();
    }
    
    /*
     * @dev: Locks received ETH/ERC20 funds.
     *
     * @param _recipient: representation of destination address.
     * @param _token: token address in origin chain (0x0 if ethereum)
     * @param _amount: value of deposit
     */
    function lock(
        address _recipient,
        address _token,
        uint256 _amount,
        string memory _chainName
    ) public payable availableNonce whenNotPaused {
        string memory symbol;

        // ETH deposit
        if (msg.value > 0) {
            require(
                _token == address(0),
                "Ethereum deposits require the 'token' address to be the null address"
            );
            require(
                msg.value == _amount,
                "The transactions value must be equal the specified amount (in wei)"
            );
            symbol = "ETH";

            lockFunds(
            payable(msg.sender),
            _recipient,
            _token,
            symbol,
            _amount,
            _chainName
            );

        }// ERC20 deposit
        else {
            
            uint beforeLock = BridgeToken(_token).balanceOf(address(this));

            BridgeToken(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );

            uint afterLock = BridgeToken(_token).balanceOf(address(this));

            // Set symbol to the ERC20 token's symbol
            symbol = BridgeToken(_token).symbol();

            lockFunds(
            payable(msg.sender),
            _recipient,
            _token,
            symbol,
            afterLock - beforeLock,
            _chainName
            );
        }
    }

    /*
     * @dev: Unlocks ETH and ERC20 tokens held on the contract.
     *
     * @param _recipient: recipient's is an evry address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function unlock(
        address payable _recipient,
        address tokenAddress,
        string memory _symbol,
        uint256 _amount,
        bytes32 _interchainTX
    ) public onlyOperator whenNotPaused {

        require(
            unlockCompleted[_interchainTX].isUnlocked == false,
            "Transactions has been processed before"
        );

        // Check if it is ETH
        if (tokenAddress == address(0)) {
            address thisadd = address(this);
            require(
                thisadd.balance >= _amount,
                "Insufficient ethereum balance for delivery."
            );
        } else {
            require(
                BridgeToken(tokenAddress).balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 token balance for delivery."
            );
        }
        unlockFunds(_recipient, tokenAddress, _symbol, _amount, _interchainTX);
    }

    function emergencyWithdraw(
        address tokenAddress,
        uint256 _amount
    ) public onlyOperator whenPaused isAbleToWithdraw{

        // Check if it is ETH
        if (tokenAddress == address(0)) {
            address thisadd = address(this);
            require(
                thisadd.balance >= _amount,
                "Insufficient ethereum balance for delivery."
            );
            payable(msg.sender).transfer(_amount);
        } else {
            require(
                BridgeToken(tokenAddress).balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 token balance for delivery."
            );
            BridgeToken(tokenAddress).safeTransfer(owner, _amount);
        }
        
    }

    /*
     * @dev: refund ETH and ERC20 tokens held on the contract.
     *
     * @param _recipient: recipient's is an evry address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function refund(
        address payable _recipient,
        address _tokenAddress,
        string memory _symbol,
        uint256 _amount,
        uint256 _nonce
    ) public onlyOperator whenNotPaused {
        require(
            refundCompleted[_nonce].isRefunded == false,
            "This refunds has been processed before"
        );
        require(
            refundCompleted[_nonce].tokenAddress == _tokenAddress,
            "This refunds has been processed before"
        );
        require(
            refundCompleted[_nonce].sender == _recipient,
            "This refunds has been processed before"
        );


        // Check if it is ETH
        if (_tokenAddress == address(0)) {
            address thisadd = address(this);
            require(
                thisadd.balance >= _amount,
                "Insufficient ethereum balance for delivery."
            );
        } else {
            require(
                BridgeToken(_tokenAddress).balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 token balance for delivery."
            );
        }
        refunds(_recipient, _tokenAddress, _symbol, _amount, _nonce);
    }




    // This function check the mapping to see if the transaction  is unlockeds
    function checkIsUnlocked(bytes32 _interchainTX) public view
        returns (bool)
    {
        UnlockData memory _unlock = unlockCompleted[_interchainTX];
        return _unlock.isUnlocked;

    }

    function checkIsRefunded(uint256 _id) public view
        returns (bool)
    {
        RefundData memory _refund = refundCompleted[_id];
        return _refund.isRefunded;
    }

    function setEmergencyWithdrawDelayTime(uint delayInSecs) public isOwner{
        _setDelayTime(delayInSecs);
    }

    function getDelayTime() public view returns (uint256){
        return _getDelayTime();
    }
    
    function getPausedAt() public view returns (uint256){
        return _getPausedAt();
    }
}
