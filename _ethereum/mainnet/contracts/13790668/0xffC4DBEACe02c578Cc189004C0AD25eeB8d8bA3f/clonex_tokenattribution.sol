// SPDX-License-Identifier: MIT

/*
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Website Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
*/

pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";
 
contract CloneXRandomizer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
     
    event seedGenerated(uint256 seed);
    
    bool notAccessible = true; // In order to avoid sniping, we only authorize the ERC-721 contract to read the numbers at first
    address authorizedContract; // The ERC-721 contract address
    address authorizedCaller = 0x12eA19217C65F36385bB030D00525c1034E2F0Af;
    
     
    // Rinkeby
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 2 LINK (Varies by network)
    }
    
    string[] private tokenAttribution;
    
    function setTokenAttribution(string[] memory tokenIds) public {
        require(msg.sender == authorizedCaller, "Not authorized");
        for(uint256 i = 0; i < tokenIds.length; i++) {
            tokenAttribution.push(tokenIds[i]);  
        }
    }
    
    function clearAttribution() public {
        require(msg.sender == authorizedCaller, "Not authorized");
        string[] memory clearedVariable;
        tokenAttribution = clearedVariable;
    }
    
    function toggleVisibility() public {
        require(msg.sender == authorizedCaller, "Not authorized");
        notAccessible = !notAccessible;
    }
    
    function authorizeContract(address contractAddr) public {
        require(msg.sender == authorizedCaller, "Not authorized");
        authorizedContract = contractAddr;
    }
   
    function getTokenId(uint256 tokenId) public view returns(string memory) {
        if(notAccessible) require(msg.sender == authorizedContract, "Not authorized");
        return tokenAttribution[tokenId-1];
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(msg.sender == authorizedCaller, "Not authorized");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit seedGenerated(randomness);
    }
    
    function withdrawFunds() public {
        require(msg.sender == authorizedCaller, "Not authorized");
		payable(msg.sender).transfer(LINK.balanceOf(address(this)));
	}
}