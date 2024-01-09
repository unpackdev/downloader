pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract EthBridge is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 private _token;
    uint private _fee;
    uint private _stakingFee;
    uint private _minAmount;
    address private _stakingContractAddress;

    struct Transaction {
        string transactionType;
        uint timestamp;
        uint amount;
        uint fromChainId;
        uint toChainId;
    }

    mapping(address => Transaction[]) public transactionsByAddress;

    /**
     * Event for token release
     * @param beneficiary who got the tokens
     * @param amount amount of tokens released
     */
    event TokensReleased(address indexed beneficiary, uint amount);
    
    /**
     * Event for token deposit
     * @param depositor of the tokens
     * @param amount amount of tokens deposited
     */
    event TokensDeposited(address indexed depositor, uint amount);
    
    /**
     * Event for crowdsale being created
     */
    event LogBridgeContract(address _token);

    constructor (
        IERC20 token,
        uint fee,
        uint stakingFee,
        uint minAmount,
        address stakingContractAddress
    )  {
        require(address(token) != address(0), "Bridge: Token address cannot be zero address");

        _token = token;
        _fee = fee;
        _stakingFee = stakingFee;
        _minAmount = minAmount;
        _stakingContractAddress = stakingContractAddress;

        emit LogBridgeContract(address(token));
    }

    /**
     * @return the token being swapped.
     */
    function getToken() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the contract fee.
     */
    function getFee() public view returns (uint) {
        return _fee;
    }

    function getStakingFee() public view returns (uint) {
        return _stakingFee;
    }

    function getStakingContractAddress() public view returns (address) {
        return _stakingContractAddress;
    }

    function getAllTransactionsByAddress(address accountAddress) public view returns (Transaction[] memory) {
        return transactionsByAddress[accountAddress];
    }

    /**
     * @return the minimum amount.
     */
    function getMinimumAmount() public view returns (uint) {
        return _minAmount;
    }

    function setMinimumAmount(uint amount) public onlyOwner {
        _minAmount = amount;
    }

    function setFee(uint fee) public onlyOwner {
        _fee = fee;
    }

    function setStakingFee(uint stakingFee) public onlyOwner {
        _stakingFee = stakingFee;
    }

    function setStakingContractAddress(address stakingContractAddress) public onlyOwner {
        _stakingContractAddress = stakingContractAddress;
    }

    /**
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param _beneficiary Recipient of the tokens
     * @param _tokenAmount Number of tokens 
     */
    function releaseTokens(address _beneficiary, uint _tokenAmount, uint _fromChainId, uint _toChainId) public nonReentrant onlyOwner {
        require(_toChainId > 0, "Bridge: chain id cannot be less than 0");
        require(_fromChainId > 0, "Bridge: chain id cannot be less than 0");
        require(_tokenAmount >= _minAmount, "Bridge: deposit amount less than minimum amount");

        uint amount = (100 - _fee) * _tokenAmount;
        amount = amount / 100;

        uint feeAmount = _tokenAmount - amount;
        uint stakingAmount = (_stakingFee) * feeAmount;
        stakingAmount = stakingAmount / 100;

        _token.safeTransfer(_stakingContractAddress, stakingAmount);

        _token.safeTransfer(_beneficiary, amount);

        Transaction memory releaseTx = Transaction("release", block.timestamp, amount, _fromChainId, _toChainId);
        transactionsByAddress[_beneficiary].push(releaseTx);

        emit TokensReleased(_beneficiary, _tokenAmount);
    }

    function depositTokens(uint _tokenAmount, uint _fromChainId, uint _toChainId) public {
        require(_toChainId > 0, "Bridge: chain id cannot be less than 0");
        require(_fromChainId > 0, "Bridge: chain id cannot be less than 0");

        _token.safeTransferFrom(_msgSender(), address(this), _tokenAmount);

        Transaction memory depositTx = Transaction("deposit", block.timestamp, _tokenAmount, _fromChainId, _toChainId);
        transactionsByAddress[_msgSender()].push(depositTx);

        emit TokensDeposited(_msgSender(), _tokenAmount);
    }

    function withdrawTokens(uint _tokenAmount) public onlyOwner {
        _token.safeTransfer(_msgSender(), _tokenAmount);  
    }
}