// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
//import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract swapContract is AccessControl
{
    using SafeMath for uint256;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public tokenAddress;
    address public feeAddress;

    uint128 public numOfThisBlockchain;
    mapping(uint128 => bool) public existingOtherBlockchain;
    mapping(uint128 => uint128) public feeAmountOfBlockchain;

    mapping(bytes32 => bool) public processedTransactions;

    event TransferFromOtherBlockchain(address user, uint256 amount, uint256 amountWithoutFee, bytes32 originalTxHash);
    event TransferToOtherBlockchain(uint128 blockchain, address user, uint256 amount, string newAddress);
    
    modifier onlyOwner() {
        require(
            hasRole(OWNER_ROLE, _msgSender()),
            "Caller is not an owner role"
        );
        _;
    }

    modifier onlyOwnerAndManager() {
        require(
            hasRole(OWNER_ROLE, _msgSender()) || hasRole(MANAGER_ROLE, _msgSender()),
            "Caller is not an owner or manager role"
        );
        _;
    }

    constructor(
        IERC20 _tokenAddress,
        address _feeAddress,
        uint128 _numOfThisBlockchain,
        uint128 [] memory _numsOfOtherBlockchains)
    {
        tokenAddress = _tokenAddress;
        feeAddress = _feeAddress;
        for (uint i = 0; i < _numsOfOtherBlockchains.length; i++ ) {
            require(
                _numsOfOtherBlockchains[i] != _numOfThisBlockchain,
                "swapContract: Number of this blockchain is in array of other blockchains"
            );
            existingOtherBlockchain[_numsOfOtherBlockchains[i]] = true;
        }
        
        numOfThisBlockchain = _numOfThisBlockchain;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    function getOtherBlockchainAvailableByNum(uint128 blockchain) external view returns (bool)
    {
        return existingOtherBlockchain[blockchain];
    }

    function transferToOtherBlockchain(uint128 blockchain, uint256 amount, string memory newAddress) external
    {
        require(
            bytes(newAddress).length > 0,
            "swapContract: No destination address provided"
        );
        require(
            existingOtherBlockchain[blockchain] && blockchain != numOfThisBlockchain,
            "swapContract: Wrong choose of blockchain"
        );
        require(
            amount >= feeAmountOfBlockchain[blockchain],
            "swapContract: Not enough amount of tokens"
        );
        address sender = _msgSender();
        require(
            tokenAddress.balanceOf(sender) >= amount,
            "swapContract: Not enough balance"
        );
        tokenAddress.transferFrom(sender, address(this), amount);
        emit TransferToOtherBlockchain(blockchain, sender, amount, newAddress);
    }

    function transferToUserWithoutFee(address user, uint256 amount) external onlyOwner
    {
        tokenAddress.transfer(user, amount);
        emit TransferFromOtherBlockchain(user, amount, amount, bytes32(0));
    }

    /* function transferToUserWithFee(address user, uint256 amountToUser, uint256 feeAmount) external onlyOwner
    {
        tokenAddress.transfer(user, amountToUser);
        tokenAddress.transfer(feeAddress, feeAmount);
        emit TransferFromOtherBlockchain(user, amountToUser);
    } */

    function transferToUserWithFee(
        address user,
        uint256 amountWithFee,
        bytes32 originalTxHash
    )
        external
        onlyOwner
    {
        require(!isProcessedTransaction(originalTxHash), "swapContract: Transaction already processed");
        processedTransactions[originalTxHash] = true;
        uint256 fee = feeAmountOfBlockchain[numOfThisBlockchain];
        uint256 amountWithoutFee = amountWithFee.sub(fee);
        tokenAddress.transfer(user, amountWithoutFee);
        tokenAddress.transfer(feeAddress, fee);
        emit TransferFromOtherBlockchain(user, amountWithFee, amountWithoutFee, originalTxHash);
    }

    function removeOtherBlockchain(
        uint128 numOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = false;
    }

    function addOtherBlockchain(
        uint128 numOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            numOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            !existingOtherBlockchain[numOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );
        existingOtherBlockchain[numOfOtherBlockchain] = true;
    }

    function changeOtherBlockchain(
        uint128 oldNumOfOtherBlockchain,
        uint128 newNumOfOtherBlockchain
    )
        external
        onlyOwner
    {
        require(
            oldNumOfOtherBlockchain != newNumOfOtherBlockchain,
            "swapContract: Cannot change blockchains with same number"
        );
        require(
            newNumOfOtherBlockchain != numOfThisBlockchain,
            "swapContract: Cannot add this blockchain to array of other blockchains"
        );
        require(
            existingOtherBlockchain[oldNumOfOtherBlockchain],
            "swapContract: This blockchain was not added"
        );
        require(
            !existingOtherBlockchain[newNumOfOtherBlockchain],
            "swapContract: This blockchain is already added"
        );
        
        existingOtherBlockchain[oldNumOfOtherBlockchain] = false;
        existingOtherBlockchain[newNumOfOtherBlockchain] = true;
    }

    function changeFeeAddress(address newFeeAddress) external onlyOwner
    {
        feeAddress = newFeeAddress;
    }

    function transferOwnerAndSetManager(address newOwner, address newManager) external onlyOwner {
        require(newOwner != address(0x0), "swapContract: Owner cannot be zero address");
        require(newManager != address(0x0), "swapContract: Owner cannot be zero address");
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(OWNER_ROLE, newOwner);
        _setupRole(MANAGER_ROLE, newManager);
        renounceRole(OWNER_ROLE, _msgSender());
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setFeeAmountOfBlockchain(uint128 blockchainNum, uint128 feeAmount) external onlyOwnerAndManager
    {
        feeAmountOfBlockchain[blockchainNum] = feeAmount;
    }

    function isProcessedTransaction(bytes32 originalTxHash) public view returns (bool processed) {
        return processedTransactions[originalTxHash];
    }
}