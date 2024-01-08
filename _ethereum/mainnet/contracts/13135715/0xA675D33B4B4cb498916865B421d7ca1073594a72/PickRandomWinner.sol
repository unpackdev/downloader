// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.6;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract PickRandomWinner is VRFConsumerBase, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32; 

    struct Document {
        string urlHash; 
		uint256 totalSigners; 
		uint256 result; 
    }
    
    mapping(string => bytes32) private users; 
    mapping(bytes32 => Document) private userDocumentInfo; 
    mapping(string => uint256) private requestStatus; 

    event RequestWinner(string urlHash, bytes signature);
    event ReturnWinner(string urlHash, uint256 result);
    event WithdrawAmount(uint256 amount);
    
    bytes32 private privKeyHash; 
	uint256 private privFee;
    address private privSignedVerifier; 
    uint256 private userChargePrice = 0.05 ether; 
    address payable private privWithdrawWallet; 

    uint256 private constant PICK_IN_PROGRESS = 909090; 
    uint256 private constant PICK_COMPLETED = 909091; 
    uint256 private constant NO_RESULT = 909092; 
    
    constructor(bytes32 keyHash, uint256 fee, address coordinator, address linkToken, address signedVerifier, address payable withdrawWallet) VRFConsumerBase(coordinator, linkToken) {
		privKeyHash = keyHash; 
		privFee = fee; 
        privSignedVerifier = signedVerifier;  
        privWithdrawWallet = withdrawWallet; 
	}    

    function getPrice() public view returns(uint256) {
        return userChargePrice;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        userChargePrice = newPrice;
    }

    function withdrawEthFromContract() public payable onlyOwner {
        uint256 accountBalance = address(this).balance; 
        emit WithdrawAmount(accountBalance);
        require(privWithdrawWallet.send(accountBalance), "Error widthrawing ETH from contract");
    }

    function getSignVerifier() public view onlyOwner returns(address) {
        return privSignedVerifier; 
    }

    function setSignVerifier(address verifier) external onlyOwner {
        privSignedVerifier = verifier;
    }

    function requestWinnerSigningHash(string memory urlHash, uint256 totalSigners) public view returns (bytes32) {
        return keccak256(abi.encodePacked(urlHash, totalSigners));
    }

    function verify(bytes memory signature, string memory urlHash, uint256 totalSigners) internal view returns (bool) {
        bytes32 signingHash = requestWinnerSigningHash(urlHash, totalSigners).toEthSignedMessageHash();

        address recoveredSig = ECDSA.recover(signingHash, signature);

        if(recoveredSig == privSignedVerifier) {
            return true;
        }

        return false;
    }

    // Check if the contract has enough Link
    // Fetch the current user
    //  - Check if the requested document has a winner already
    //  - If document doesn't have a winner => request a random number for that document based on # of signers
    function requestWinner(bytes memory signature, string memory urlHash, uint256 totalSigners) public payable {
        require(msg.value >= userChargePrice, "Ether sent not correct");
        require(verify(signature, urlHash, totalSigners) == true, "Verification for signer failed");
        require(users[urlHash] == 0, "Winner already chosen!");
		require(LINK.balanceOf(address(this)) >= privFee, "Not enough Link!"); 

        bytes32 requestId = requestRandomness(privKeyHash, privFee); 

        users[urlHash] = requestId; 
        userDocumentInfo[users[urlHash]] = Document(urlHash, totalSigners, NO_RESULT);

        requestStatus[urlHash] = PICK_IN_PROGRESS;

        emit RequestWinner(urlHash, signature);
    }

    // Chainlinks callback function 
    // Iterate through the users documents and find the corresponding requestId
    //  - set it to the random value returned by chainlink
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        Document storage currentDocument = userDocumentInfo[requestId]; 

        uint256 randomValue = randomness.mod(currentDocument.totalSigners).add(1);

        currentDocument.result = randomValue; 

        requestStatus[currentDocument.urlHash] = PICK_COMPLETED; 

        emit ReturnWinner(currentDocument.urlHash, randomValue);
	}

    function getDocumentWinner(string memory urlHash) public view returns (Document memory) {
        require(users[urlHash] != 0, "Winner request not made!");
        require(requestStatus[urlHash] == PICK_COMPLETED, "Winner request in progress!");

        return userDocumentInfo[users[urlHash]];
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}