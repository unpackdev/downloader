// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Chests is ERC721URIStorage, VRFConsumerBase, Ownable {
    uint256 public tokenIds;
    uint256 public ethTracker;
    uint256 public hardCap = 500 ether;
    uint256 public endTime;
    uint256 public randomTicketNumber;
    uint256 public rollStatus; // 0: Not started rolling yet, 1: Progress in rolling, 2: Finished rolling
    
    string public baseURI;
    bool public gameOver;

    // ChainLink Variables
    bytes32 private keyHash;
    uint256 private fee;
    bytes32 private currentRequestId;

    /// @notice Event emitted when randomNumber arrived.
    event randomNumberArrived(bool arrived, bytes32 requestId, uint256 randomNumber);
    event Winner(address, uint256);

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Ethereum MainNet 
     * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * LINK token address:                0x514910771AF9Ca656af840dff83E8264EcF986CA
     * Key Hash:                          0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     * Fee :                              2 LINK (2000000000000000000 in wei)
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee,
        string memory _baseURI
    ) VRFConsumerBase(_vrfCoordinator, _link) ERC721("CHEST.GAME", "CHEST") {
        keyHash = _keyHash;
        fee = _fee;
        endTime = block.timestamp + 30 days;
        baseURI = _baseURI;
    }

    /**
     * @dev Public function to claim tickets.
     * @dev Anyone can buy as many tickets as they want. Tickets cost 0.1 eth each.
     * @dev Must not have hit hard cap of 500 eth.
     * @return tokenId
     */
    function claimTicket() public payable returns (uint256) {
        require(msg.value == 0.1 ether, "ChestGame: Chests go for 0.1 ETH each.");
        require(msg.value + ethTracker <= hardCap, "ChestGame: Chests have sold out.");
        require(!gameOver, "ChestGame: Game is over...");

        ethTracker += msg.value;
        tokenIds ++;

        _mint(msg.sender, tokenIds);

        return tokenIds;
    }

    /**
     * @dev Public function to request randomness and returns request Id. This function can be called by only owner.
     * @dev This function can be called when hard cap is reached or when endTime has passed, reverts otherwise.
     * @return requestID
     */
    function rollDice() public onlyOwner returns (bytes32) {
        require(rollStatus == 0, "ChestGame: Dice is already rolled or finished.");
        
        // If endTime is passed OR hard cap is reached...
        if(block.timestamp >= endTime || ethTracker >= hardCap) {
            require(LINK.balanceOf(address(this)) >= fee, "ChestGame: Not enough LINK to pay fee.");
            
            currentRequestId = requestRandomness(keyHash, fee);
            rollStatus = 1;
            
            (bool sent, ) = owner().call{value:address(this).balance / 2}("");
            require(sent, "ChestGame: Failed to send Ether.");
            
            emit randomNumberArrived(false, currentRequestId, randomTicketNumber);
            
            return currentRequestId;
        } else {
            revert();
        }
    }

    /**
     * @dev Callback function used by VRF Coordinator. This function sets new random number with unique request Id.
     * @param _requestId Request Id of randomness.
     * @param _randomness Random Number
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(currentRequestId == _requestId, "ChestGame: Request Id is not correct.");

        randomTicketNumber = (_randomness % tokenIds) + 1;

        rollStatus = 2;
        
        finalize();

        emit randomNumberArrived(true, _requestId, randomTicketNumber);
    }
    
    /**
     * @dev Internal function to finialize the tickets and choose a winner. 
     * @dev Sends all eth to the owner of random tokenId
     */
    function finalize() internal {
        require(randomTicketNumber > 0 && rollStatus == 2, "ChestGame: Rolling is not started or still in progress");
        uint256 _value = address(this).balance;
        (bool sent, ) = ownerOf(randomTicketNumber).call{value: _value}("");
        require(sent, "ChestGame: Failed to send Ether");
        gameOver = true;
        
        emit Winner(ownerOf(randomTicketNumber), _value);
    }
    
    /**
     * @dev Override function of the standard ERC721 implementation. This function returns the same JSON URI for all existing tokens.
     * @param tokenId The token Id requested. 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseURI;
    }
    
    /**
     * @dev Function to change the baseURI. This function can be called only by owner.
     * @param _uri The new base URI 
     */
    function changeBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    
    /**
     * @dev Function to withdraw ERC20 tokens. This function can be called only by owner.
     * @param _token The token address (ie. LINK)  
     */
    function withdrawERC20(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}
