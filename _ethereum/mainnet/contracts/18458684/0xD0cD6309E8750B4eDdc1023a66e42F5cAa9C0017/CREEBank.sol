// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";

error IncorrectSignature();
error DepositMoreCREE();
error RequireMoreCREELeft();

/// @custom:security-contact security@creebank.org
// Contract for CREEBank CREE Wallet, Version 1.0 
/*

https://creebank.org

_________________________________________ .__  _________   ________ ________   ________  ________   
\_   ___ \______   \_   _____/\_   _____/ |__|/   _____/  /  _____/ \_____  \  \_____  \ \______ \  
/    \  \/|       _/|    __)_  |    __)_  |  |\_____  \  /   \  ___  /   |   \  /   |   \ |    |  \ 
\     \___|    |   \|        \ |        \ |  |/        \ \    \_\  \/    |    \/    |    \|    `   \
 \______  /____|_  /_______  //_______  / |__/_______  /  \______  /\_______  /\_______  /_______  /
        \/       \/        \/         \/             \/          \/         \/         \/        \/ 

*/


contract CREEBank is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;


    IERC20 public theToken;
    IERC20 public usdtToken;

    uint256 public withdrawalFee;
    uint256 public claimFee;
    uint256 public transferFee;
    uint256 public MIN_DEPOSIT = 1 * 1e18;
    
    mapping(address => AccountInfo) public accounts;
    mapping(address => mapping(uint256 => IndividualDeposit)) public individualDeposits;
    mapping(address => uint256) public individualDepositCount;

    mapping(bytes32 => bool) public usedSignatures;

    uint256 public totalDeposited;
    uint256 public totalDepositers;
    uint256 public globalCREERewardedAndClaimed;
    uint256 public claimMilestone;

    uint256 public lastServerCheckin;

    address private signingAddress;

    bool public isBankOpen;     // true (you can transfer/claim rewards with CREEBank) | false (default: CREEBank is not open, you can only withdraw/deposit)

    struct IndividualDeposit {
        uint256 amount;
        uint256 timestamp;
    }

    struct AccountInfo {
        uint256 totalAmount;
        uint256 firstDepositTS;
        uint256 lastDepositTS;
        uint256 totalCREEWorthClaimed;
        bool safeMode;
        uint256[11] claimedRewards; // 0-10 types of rewards, for tracking and updates only
    }


    event Deposited(address indexed from, address indexed to, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event RewardClaimed(address indexed from, address indexed to, uint256 cree_amount, uint8 rewardType, uint256 amount);


    constructor(address _aSignerAddress, address _theTokenAddress, address _usdtAddress) Ownable(msg.sender) {
        signingAddress = _aSignerAddress;
        theToken = IERC20(_theTokenAddress);
        usdtToken = IERC20(_usdtAddress);
    }    

    function setFees(uint256 _withdrawalFee, uint256 _claimFee, uint256 _transferFee) external onlyOwner {
        withdrawalFee = _withdrawalFee;
        claimFee = _claimFee;
        transferFee = _transferFee;
    }

    function setMinimal(uint256 _MIN_DEPOSIT) external onlyOwner {
        MIN_DEPOSIT = _MIN_DEPOSIT;
    }

    function setClaimMilestone(uint256 _claimMilestone) external onlyOwner {
        claimMilestone = _claimMilestone;
    }

    function setTheTokenAddress(address _TokenAddress) external onlyOwner {
        theToken = IERC20(_TokenAddress);
    }

    function setUSDTAddress(address _usdtAddress) external onlyOwner {
        usdtToken = IERC20(_usdtAddress);
    }

    function flipBankOpen() external onlyOwner {
        isBankOpen = !isBankOpen;
    }    
    
    function setSigningAddress(address newSigningAddress) external onlyOwner {
        signingAddress = newSigningAddress;
    }

    function getSigningAddress() external view onlyOwner returns (address) {
        return signingAddress;
    }   

    function serverCheckin() external onlyOwner {
        lastServerCheckin = block.number;
    }    

    function depositTo(uint256 _amount, address _recipient) public nonReentrant {

        if (_amount < MIN_DEPOSIT) revert DepositMoreCREE();
        require(theToken.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to transfer CREE");

        // Ensure the sender has at least MIN_DEPOSIT CREE left after the deposit
        uint256 balanceAfter = theToken.balanceOf(msg.sender) - _amount;
        if (balanceAfter < MIN_DEPOSIT) revert RequireMoreCREELeft();
        
        require(theToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        if (accounts[_recipient].totalAmount == 0) {
            totalDepositers += 1;  // Increment totalDepositers as it's a new account/depositor at _recipient address
            accounts[_recipient].firstDepositTS = block.timestamp;
        }

        accounts[_recipient].lastDepositTS = block.timestamp;

        uint256 index = individualDepositCount[_recipient];
        individualDeposits[_recipient][index] = IndividualDeposit(_amount, block.timestamp);
        individualDepositCount[_recipient]++;

        accounts[_recipient].totalAmount += _amount;

        totalDeposited += _amount;
        emit Deposited(msg.sender, _recipient, _amount);
    }    

    function depositToSelf(uint256 _amount) external nonReentrant {
        depositTo(_amount, msg.sender);
    }

    function getAllIndividualDeposits(address userAddress) external view returns (IndividualDeposit[] memory) {
        uint256 count = individualDepositCount[userAddress];
        IndividualDeposit[] memory deposits = new IndividualDeposit[](count);
        for (uint256 i = 0; i < count; i++) {
            deposits[i] = individualDeposits[userAddress][i];
        }
        return deposits;
    }

    function getClaimedRewards(address walletAddress) external view returns (uint256[11] memory) {
        return accounts[walletAddress].claimedRewards;
    }


    // Unlike traditional banking systems, and most crypto exchanges...
    // CREEBank's "withdraw" function is open 24/7 for holders to withdraw.
    // "safeMode" for real customers to lock their own accounts if they want, in cases where they are hacked. Users must lock their own account withdrawals as soon as possible.
    // "safeMode" is also an off-chain option required for low/no fee withdrawal, online spending, rewards claiming etc.
    function withdraw(uint256 _amount) external payable nonReentrant {
        require(accounts[msg.sender].totalAmount >= _amount, "Insufficient balance"); // double check? redundant?

        require( (accounts[msg.sender].totalAmount - _amount) >= MIN_DEPOSIT , "Require more CREE left");

        require( !accounts[msg.sender].safeMode , "Account in safeMode!");
        
        // If a withdrawal fee is set, ensure the correct fee has been sent with the transaction
        if (withdrawalFee > 0) {
            require(msg.value >= withdrawalFee, "Insufficient ETH for withdrawal");
        }

        transferAndUpdateAccount(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    // "safeMode" withdrawal checks CREEBank before going through, this is enabled or disabled by the user through CREEBank portal.
    function withdrawFromCREEBank(bytes calldata signature, uint256 _amount, uint256 _timestamp, uint256 _dynamicFee) external payable nonReentrant {
        require(accounts[msg.sender].totalAmount >= _amount, "Insufficient balance"); // double check? redundant?

        require( (accounts[msg.sender].totalAmount - _amount) >= MIN_DEPOSIT , "Require more CREE left");

        // use liveFee if set, if not, use withdrawal fee, ensure the correct fee has been sent with the transaction
        if (_dynamicFee > 0) {
            require(msg.value >= _dynamicFee, "Insufficient ETH for withdrawal");
        }
        else {
            require(msg.value >= withdrawalFee, "Insufficient ETH for withdrawal");
        }

        require(verifySignatureForWithdraw(msg.sender, msg.sender, _amount, _timestamp, _dynamicFee, signature), "Withdrawal unverified or expired");

        bytes32 signatureHash = keccak256(abi.encodePacked(signature));
        require(!usedSignatures[signatureHash], "Claim has already been made");
        usedSignatures[signatureHash] = true;

        lastServerCheckin = block.number; 

        transferAndUpdateAccount(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    function verifySignatureForWithdraw(
        address sender,
        address _recipient,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _dynamicFee,
        bytes memory signature
    ) internal view returns(bool) {                
        // Check if _timestamp is within the last 1 hour
        if (_timestamp > block.number || (block.number - _timestamp) * 15 > 3600) {
            return false;
        }

        // String concatenation and conversion to hexadecimal
        string memory dataString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(_recipient)), 20),
                Strings.toString(_amount),
                Strings.toString(_timestamp),
                Strings.toString(_dynamicFee),
                Strings.toHexString(uint256(uint160(sender)), 20)
            )
        );

        // Hashing
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(dataString).length),
                dataString
            )
        );

        // Signature verification
        return signingAddress == ECDSA.recover(
            messageHash,
            signature
        );
    }    

    // safety feature that can only be enabled/disabled from CREEBank portal by user.
    function flipSafeMode(bytes calldata signature, address _recipient, uint256 _timestamp, uint256 _dynamicFee) external payable nonReentrant {

        // use liveFee if set
        if (_dynamicFee > 0) {
            require(msg.value >= _dynamicFee, "Insufficient ETH for action");
        }

        require(verifySignature(msg.sender, _recipient, _timestamp, _dynamicFee, signature), "Signature unverified or expired");

        bytes32 signatureHash = keccak256(abi.encodePacked(signature));
        require(!usedSignatures[signatureHash], "This safeMode action already used");
        usedSignatures[signatureHash] = true;

        lastServerCheckin = block.number; 

        accounts[_recipient].safeMode = !accounts[_recipient].safeMode;
    }        

    function verifySignature(
        address sender,
        address _recipient,
        uint256 _timestamp,
        uint256 _dynamicFee,
        bytes memory signature
    ) internal view returns(bool) {                
        // Check if _timestamp is within the last 1 hour
        if (_timestamp > block.number || (block.number - _timestamp) * 15 > 3600) {
            return false;
        }

        // String concatenation and conversion to hexadecimal
        string memory dataString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(_recipient)), 20),
                Strings.toString(_timestamp),
                Strings.toString(_dynamicFee),
                Strings.toHexString(uint256(uint160(sender)), 20)
            )
        );

        // Hashing
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(dataString).length),
                dataString
            )
        );

        // Signature verification
        return signingAddress == ECDSA.recover(
            messageHash,
            signature
        );
    }    

    // Like a bank account, users can choose to transfer to a target address from their CREE Wallet account
    function transferTo(uint256 _amount, address _recipient) external payable nonReentrant {
        require(isBankOpen, "CREEBank not open!");

        require(accounts[msg.sender].totalAmount >= _amount, "Insufficient balance"); // double check? redundant?
        if (accounts[msg.sender].totalAmount - _amount < MIN_DEPOSIT) revert RequireMoreCREELeft();
        
        if (transferFee > 0) {
            require(msg.value >= transferFee, "Insufficient ETH for transfer");
        }

        require( !accounts[msg.sender].safeMode , "Account in safeMode!");

        transferAndUpdateAccount(_recipient, _amount);

        emit Transferred(msg.sender, _recipient, _amount);
    }    

    // Like a bank account, users can choose to transfer to a target address from their CREE Wallet account
    function transferToFromCREEBank(bytes calldata signature, uint256 _amount, address _recipient, uint256 _timestamp, uint256 _dynamicFee) external payable nonReentrant {
        require(isBankOpen, "CREEBank not open!");

        require(accounts[msg.sender].totalAmount >= _amount, "Insufficient balance"); // double check? redundant?
        if (accounts[msg.sender].totalAmount - _amount < MIN_DEPOSIT) revert RequireMoreCREELeft();

        if (_dynamicFee > 0) {
            require(msg.value >= _dynamicFee, "Insufficient ETH for transfer");
        }
        else {
            require(msg.value >= transferFee, "Insufficient ETH for transfer");
        }


        require(verifySignatureForWithdraw(msg.sender, _recipient, _amount, _timestamp, _dynamicFee, signature), "Withdrawal unverified or expired");

        bytes32 signatureHash = keccak256(abi.encodePacked(signature));
        require(!usedSignatures[signatureHash], "Claim has already been made");
        usedSignatures[signatureHash] = true;

        lastServerCheckin = block.number; 

        transferAndUpdateAccount(_recipient, _amount);

        emit Transferred(msg.sender, _recipient, _amount);
    }        

    // modular code for withdraw() and transferTo()
    // should never fail, but if it ever does, the system can check & renumerate
    function transferAndUpdateAccount(address _recipient, uint256 _amount) internal {

        uint256 originalAmount = _amount;

        accounts[msg.sender].totalAmount -= _amount;
        if (accounts[msg.sender].totalAmount <= 0) {
            totalDepositers -= 1;  // Decrement totalDepositers as the depositor has withdrawn all tokens
        }

        totalDeposited -= _amount; // throws error and reverts if negative

        if (individualDepositCount[msg.sender] > 0) {
            int256 i = int256(individualDepositCount[msg.sender] - 1);  // Start at the last deposit
            while (i >= 0 && _amount > 0) {
                IndividualDeposit storage aDeposit = individualDeposits[msg.sender][uint256(i)];
                if (aDeposit.amount > 0) {
                    uint256 amountToWithdraw = aDeposit.amount > _amount ? _amount : aDeposit.amount;
                    aDeposit.amount -= amountToWithdraw;
                    _amount -= amountToWithdraw;

                    if (aDeposit.amount == 0) {
                        deleteDeposit(msg.sender, uint256(i));
                    }
                }
                i--;  // Decrement i to process the next older deposit
            }
        }

        // Proceed with the transfer (reentrancy in mind)
        require(theToken.transfer(_recipient, originalAmount), "Transfer failed");
    }

    function deleteDeposit(address user, uint256 index) internal {
        require(index < individualDepositCount[user], "Invalid index");

        // If it's not the last one, swap it with the last one
        if (index != individualDepositCount[user] - 1) {
            individualDeposits[user][index] = individualDeposits[user][individualDepositCount[user] - 1];
        }

        // Delete the last one and decrement the count
        delete individualDeposits[user][individualDepositCount[user] - 1];
        individualDepositCount[user]--;
    }    


    function verifySignatureForClaim(
        address sender,
        uint256 _creeWorthToClaim,
        uint8 _rewardType,
        uint256 _amountToClaim,
        uint256 _timestamp,
        uint256 _dynamicFee,
        bytes memory signature
    ) internal view returns(bool) {                
        // Check if _timestamp is within the last 1 hour
        if (_timestamp > block.number || (block.number - _timestamp) * 15 > 3600) {
            return false;
        }

        // String concatenation and conversion to hexadecimal
        string memory dataString = string(
            abi.encodePacked(
                Strings.toString(_creeWorthToClaim),
                Strings.toString(_rewardType),
                Strings.toString(_amountToClaim),
                Strings.toString(_timestamp),
                Strings.toString(_dynamicFee),
                Strings.toHexString(uint256(uint160(sender)), 20)
            )
        );

        // Hashing
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(dataString).length),
                dataString
            )
        );

        // Signature verification
        return signingAddress == ECDSA.recover(
            messageHash,
            signature
        );
    }

    // this function checks CREEBank before going through
    function claimRewardsFromCREEBank(bytes calldata signature, address _recipient, uint256 _creeWorthToClaim, uint8 _rewardType, uint256 _amountToClaim, uint256 _timestamp, uint256 _dynamicFee) external payable nonReentrant {
        // use liveFee if set, if not, use claim fee, ensure the correct fee has been sent with the transaction
        if (_dynamicFee > 0) {
            require(msg.value >= _dynamicFee, "Insufficient ETH for claim");
        }
        else {
            require(msg.value >= claimFee, "Insufficient ETH for claim");
        }

        require(verifySignatureForClaim(msg.sender, _creeWorthToClaim, _rewardType, _amountToClaim, _timestamp, _dynamicFee, signature), "Claim unverified or expired");

        bytes32 signatureHash = keccak256(abi.encodePacked(signature));
        require(!usedSignatures[signatureHash], "Claim has already been made");
        usedSignatures[signatureHash] = true;

        lastServerCheckin = block.number;

        updateAndTransferRewards(_creeWorthToClaim, _rewardType, _amountToClaim, _recipient);        
    }

    // this function transfers and log rewards, it does not calculate rewards.
    // rewards are calculated by CREEBank and/or calculateRewards()
    function updateAndTransferRewards(uint256 _creeWorthToClaim, uint8 _rewardType, uint256 _amount, address _recipient) internal {
        require(isBankOpen, "CREEBank not open!");

        // Reward and bonus hack protection
        require(claimMilestone > globalCREERewardedAndClaimed + _creeWorthToClaim, "claimMilestone reached. Contact support or try again later!");
        
        accounts[msg.sender].claimedRewards[_rewardType] += _amount;        
        accounts[msg.sender].totalCREEWorthClaimed += _creeWorthToClaim;
        globalCREERewardedAndClaimed += _creeWorthToClaim;        

        if (_rewardType == 0) {
            // Transfer ETH
            if (address(this).balance >= _amount) {
                payable(_recipient).transfer(_amount);
            }
            else {
                require(theToken.transfer(_recipient, _creeWorthToClaim), "CREE transfer failed");
            }
        } else if (_rewardType == 1) {
            // Transfer USDT
            if (usdtToken.balanceOf(address(this)) >= _amount) {
                usdtToken.safeTransfer(_recipient, _amount);
            }
            else {
                require(theToken.transfer(_recipient, _creeWorthToClaim), "CREE transfer failed");
            }
        } else if (_rewardType == 3) {
            // Transfer CREE
            require(theToken.transfer(_recipient, _amount), "CREE transfer failed");
        } else if (_rewardType == 2) {
            // We're not using WBTC because we want our users to receive the real BTC, and not its securities held on Ethereum.
            // 1. Our webservers call BTC scripts to transfer all real BTC rewards, directly to the user's BTC account set
            // 2. After which it will call this contract and update its BTC claimed rewards, accounts[msg.sender].claimedRewards[_rewardTypeBTC] += X BTC;
            // 3. If user choose to claim CREE by coming here to this point, then CREEBank will not update this contract again.
            require(theToken.transfer(_recipient, _creeWorthToClaim), "CREE transfer failed");

        }

        emit RewardClaimed(msg.sender, _recipient, _creeWorthToClaim, _rewardType, _amount);
    }


    // this function can only be called from CREEBank.org, in cases of BTC withdrawals on CREEBank.org, or other withdrawals
    // only updates records, no transfers
    // usually sent by server scripts or admins
    // once added, cannot be undone
    function addClaimedRewardsFromCREEBank(bytes calldata signature, address _user, address _recipient, uint256 _creeWorthClaimed, uint8 _rewardType, uint256 _claimedAmount, uint256 _timestamp) external nonReentrant {

        if(!verifySignatureForClaimUpdates(msg.sender, _user, _creeWorthClaimed, _rewardType, _claimedAmount, _timestamp, signature)) revert IncorrectSignature();
        lastServerCheckin = block.number;

        bytes32 signatureHash = keccak256(abi.encodePacked(signature));
        require(!usedSignatures[signatureHash], "Signature has already been used");
        usedSignatures[signatureHash] = true;        

        accounts[_user].claimedRewards[_rewardType] += _claimedAmount;
        accounts[_user].totalCREEWorthClaimed += _creeWorthClaimed;
        globalCREERewardedAndClaimed += _creeWorthClaimed;

        emit RewardClaimed(_user, _recipient, _creeWorthClaimed, _rewardType, _claimedAmount);
    }


    function verifySignatureForClaimUpdates(
        address sender,
        address _user,
        uint256 _creeWorthClaimed,
        uint8 _rewardType,
        uint256 _claimedAmount,
        uint256 _timestamp,
        bytes memory signature
    ) internal view returns(bool) {                
        /*
        if (_timestamp < block.timestamp - 1 hours || _timestamp > block.timestamp) {
            return false;
        }
        */
        // Check if _timestamp is within the last 1 hour
        if (_timestamp > block.number || (block.number - _timestamp) * 15 > 3600) {
            return false;
        }

        // String concatenation and conversion to hexadecimal
        string memory dataString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(_user)), 20),
                Strings.toString(_creeWorthClaimed),
                Strings.toString(_rewardType),
                Strings.toString(_claimedAmount),
                Strings.toString(_timestamp),
                Strings.toHexString(uint256(uint160(sender)), 20)
            )
        );

        // Hashing
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(dataString).length),
                dataString
            )
        );

        // Signature verification
        return signingAddress == ECDSA.recover(
            messageHash,
            signature
        );
    }    


    // convenient functions for UI and public view. Do not use these functions in contract code, use the code within instead to save gas.
    function tokensInContract() external view returns(uint) {
        return theToken.balanceOf(address(this));
    }

    function usdtInContract() external view returns(uint) {
        return usdtToken.balanceOf(address(this));
    }    

    function ethInContract() external view returns(uint) {
        return address(this).balance;
    }    


    // Requires to use safeTransfer for Tether
    function withdrawAllUSDT() external onlyOwner {
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        usdtToken.safeTransfer(msg.sender, usdtBalance);
    }

    function withdrawSomeUSDT(uint256 amount) external onlyOwner {
        require(usdtToken.balanceOf(address(this)) >= amount, "Not enough tokens available to withdraw");
        usdtToken.safeTransfer(msg.sender, amount);
    }        

    function withdrawEth() external onlyOwner {
        require(address(this).balance > 0, "No ETH available to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }    

    function withdrawSomeEth(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Not enough ETH available to withdraw");
        payable(msg.sender).transfer(amount);
    }        

    function withdrawTokensInContract(uint256 amount) external onlyOwner {
        require(theToken.balanceOf(address(this)) >= amount, "Not enough CREE available to withdraw");
        theToken.safeTransfer(msg.sender, amount);
    }    

    // SECURITY and PROTECTION of funds transferred.
    // These functions allows the contract to receive Ether, withdraw and send tokens, so investments and capital will not be locked or lost forever.
    // Situations include users who directly send Ether to the CREEBank.
    receive() external payable {
    }

    // Handle unmatched function calls
    fallback() external payable {
    }        

}