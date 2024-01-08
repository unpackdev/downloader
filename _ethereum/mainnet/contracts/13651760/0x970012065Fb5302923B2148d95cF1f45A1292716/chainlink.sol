// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

contract ChainlinkVRF is VRFConsumerBase, Ownable {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    mapping (uint => uint256) public chainlinkResults;
    mapping (uint => uint256[]) internal randomResults; 
    mapping (uint => uint256) public blockNumberResults;
    mapping (uint => bool) public nonceCalculated; 
    uint public nonce;

    event fulfillComplete(uint256 _randomNumber, bytes32 _requestedId, uint _nonce);

    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
        return requestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        nonce++;
        chainlinkResults[nonce] = randomness;
        blockNumberResults[nonce]=block.number;
        emit fulfillComplete(randomness, requestId, nonce);
    }
    
    /**
    * @notice calculate 10 numbers.
    * @param useCurrNonce if for current nonce, then _nonce is ignored
    * @param _nonce specified nonce to calculate for if not using current nonce
    */

    function calculateNumbers(bool useCurrNonce, uint _nonce) public onlyOwner{
        uint randomNumber;
        uint currNonce;
        if(useCurrNonce){
            require(nonce > 0, "have not ran VRF");
            randomNumber = chainlinkResults[nonce];
            currNonce = nonce;
        }
        else{
            require(_nonce > 0 && _nonce <= nonce, "invalid nonce");
            randomNumber = chainlinkResults[_nonce];
            currNonce = _nonce;
        }
        require(!nonceCalculated[currNonce], "nonce already used for calculation");
        
        uint currentIndex = 0;
        uint modulus = 100000;
        uint target;

        uint256[] memory numbersArray = new uint256[](10);
        
        while(currentIndex < 10){
            target = (uint256(keccak256(abi.encode(randomNumber, currentIndex))) % modulus)+1;
            numbersArray[currentIndex] = target;
            currentIndex++;
        }
       
        randomResults[currNonce] = numbersArray;
        nonceCalculated[currNonce] = true;
    }

    function getArrayByNonce(uint _nonce) public view returns(uint256[] memory){
        return randomResults[_nonce];
    }

    function viewLinkBalance() public view returns(uint256){
        return LINK.balanceOf(address(this));
    }
    
    
    function setFee(uint _newFee) external onlyOwner{
        fee = _newFee;
    }
    
    function setKeyHash(bytes32 _newHash) external onlyOwner{
        keyHash = _newHash;
    }

    function withdrawLink() onlyOwner external {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
}