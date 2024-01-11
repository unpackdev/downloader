// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "LinkTokenInterface.sol";
import "VRFConsumerBase.sol";
import "Ownable.sol";
import "ERC721.sol";
import "ERC721URIStorage.sol";
import "EthUsPriceConversion.sol";
import "State.sol";

contract MyStorage is ERC721URIStorage, VRFConsumerBase, Ownable {

    // Ethereum US Dollar Price Conversion
    EthUsPriceConversion immutable ethUsConvert;

    // enum State open, end, closed the funding. 
    State immutable state;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 immutable keyHash;

    // owner of this contract who deploy it.
    address immutable s_owner;

    // VRF Link fee  
    uint256 fee;

    // Minimum Entry Fee to fund
    uint32 minimumEntreeFee;
    
    // users who send fund to this contract
    address payable[] users;

    // To keep track of the balance of each address
    mapping (address => uint256) balanceOfUsers;

    //counter for NFT Token created
    uint256 tokenCounter;

    // check if it is created NFT token or Eth withdraw
    bool isNftToken;
 
    enum Breed{PUG, SHIBA_INU, ST_BERNARD}
    // add other things
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => string) public requestIdToTokenURI;
    mapping(uint256 => Breed) public tokenIdToBreed;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    event RequestedCollectible(bytes32 indexed requestId); 
    event ReturnedCollectible(bytes32 indexed requestId, uint256 randomNumber);

    event Withdraw2(uint256 num);
    event ReturnedWithdraw(bytes32 indexed requestId);
    event RequestWithdraw(bytes32 indexed requestId);

    /*
     * @notice Constructor inherits VRFConsumerBase
     *
     * @param _priceFeedAddress
     * @param _minimumEntreeFee
     * @param _vrfCoordinator - coordinator
     * @param _LinkToken
     * @param _keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     * @param _fee - Link token fee for requesting random number.
     * @param _nftName - NFT token name
     * @param _symbol - NFT symbol
     */
    constructor(
        address _priceFeedAddress,
        uint32 _minimumEntreeFee,
        address _VRFCoordinator, 
        address _LinkToken, 
        bytes32 _keyhash,
        uint256 _fee,
        string memory _nftName,
        string memory _symbol
    )
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721(_nftName, _symbol) payable
    {
        minimumEntreeFee = _minimumEntreeFee;
        ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, minimumEntreeFee);
        state = new State();
        s_owner = msg.sender;
        tokenCounter = 0;
        isNftToken = false;
        keyHash = _keyhash;
        fee = _fee;
    }

    /**
     * @notice Get the current Ethereum market price in Wei
     */
    function getETHprice() external view returns (uint256) {
       return ethUsConvert.getETHprice();
    }

    /**
     * @notice Get the current Ethereum market price in US Dollar
     */
    function getETHpriceUSD() external view returns (uint256) {
        return ethUsConvert.getETHpriceUSD();
    }

    /**
     * @notice Get the minimum funding amount which is $50
     */
    function getEntranceFee() external view returns (uint256) {
        return ethUsConvert.getEntranceFee();
    }

    /**
     * @notice Get current funding state.
     */
    function getCurrentState() external view returns (string memory) {
        return state.getCurrentState();
    }

    /**
     * @notice Get the total amount that users funding in this account.
     */
    function getUsersTotalAmount() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get the balance of the user.
     * @param - user address
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balanceOfUsers[user];
    }


    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function start() external onlyOwner {
        state.start();
    }

    /**
     * @notice End the state.
     */
    function end() external onlyOwner {    
        state.end();
    }

    /**
     * @notice Close the state.
     */  
    function closed() external onlyOwner {
        state.closed();
    }
    
    /**
     * @notice User can enter the fund.  Minimum $50 value of ETH.
     */
    function send() external payable {
        // $50 minimum
        require(state.getCurrentStateType() == state.getOpenState(), "Can't fund yet.  Funding is not opened yet.");
        require(msg.value >= ethUsConvert.getEntranceFee(), "Not enough ETH! Minimum $50 value of ETH require!");
        users.push(payable(msg.sender));
        balanceOfUsers[msg.sender] += msg.value;
    }

    /**
     * @notice Owner withdraw the fund.
     */
    function wdraw() external onlyOwner {

        require(
            state.getCurrentStateType() == state.getEndState(),
            "Funding must be ended before withdraw!"
        );
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestWithdraw(requestId);
    }

    /** 
     * @notice Owner withdraw the funding.
     */
    function wdraw2() external onlyOwner {
        require(
            state.getCurrentStateType() == state.getEndState(),
            "Funding must be ended before withdraw!"
        );
        payable(s_owner).transfer(address(this).balance);
        reset();
        uint256 num = 12347;
        emit Withdraw2(num);
    }

    /**
     * @notice Set the new Link fee for randonness
     */
    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    /**
     * @notice Set the minimum entry fee to fund in this contract
     * 
     */
     function setMinimumEntryFee(uint32 newMinEntryFee) external onlyOwner {
         minimumEntreeFee = newMinEntryFee;
     }

   
    /*
     * @notice Create a new NFT Token.
     */
    function createCollectible(string memory tokenURI) external returns (bytes32){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        requestIdToTokenURI[requestId] = tokenURI;
        isNftToken = true;
        emit RequestedCollectible(requestId);
    }

    /*
     * Callback function for random number
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        if(isNftToken) {
            tokenCounter = tokenCounter + 1;
            address dogOwner = requestIdToSender[requestId];
            string memory tokenURI = requestIdToTokenURI[requestId];
            uint256 newItemId = tokenCounter;
            _safeMint(dogOwner, newItemId);
            _setTokenURI(newItemId, tokenURI);
            Breed breed = Breed(randomNumber % 3); 
            tokenIdToBreed[newItemId] = breed;
            requestIdToTokenId[requestId] = newItemId;
            
            isNftToken = false;
            emit ReturnedCollectible(requestId, randomNumber);
        }
        else { //ETH withdraw
            payable(s_owner).transfer(address(this).balance);
            reset();
            emit ReturnedWithdraw(requestId);
        }
    }

    /*
     * Reset the memory.  Clear the container. 
     */
    function reset() internal {
        for (uint256 index = 0; index < users.length; index++) {
            address user = users[index];
            balanceOfUsers[user] = 0;
        }
        users = new address payable[](0);
        state.setStateType(state.getClosedState());
    }

    /**
     * Set the token URI
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @notice Get the count of NFT token created so far
     */
    function getNFTtokenCount() external view returns (uint256) {
        return tokenCounter;
    }
    
}
