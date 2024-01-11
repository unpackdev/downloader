pragma solidity 0.8.7;
import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";



contract DumbNFT is ERC721A, VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface COORDINATOR;
    address constant vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 constant keyHash = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92; //500 GWEI hash
    uint32 private callbackGasLimit = 1000000;
    uint16 constant requestConfirmations = 3;
    uint64 immutable s_subscriptionId;

    enum SaleState {
        Disabled,
        Enable
    }

    /////////////////////////////TURN CLAIMED PRIVATE AFTER TESTING///////////////////////////////////////////
    mapping(uint256=>bool) public claimed;

    SaleState public saleState = SaleState.Disabled;
    
    bool public revealAll;
    uint32 public numWords;
    uint256 public price;
    uint256 public winnerAmountPerNFT;
    uint256 public s_requestId;
    uint256 public devSplit = 30;
    uint256 public gameNumber;
    uint256 public gameStartingTokenID;
    uint256[] public random;
    uint256[] public randomPermenant;
    uint256[] public emergencyRandom;
    string public unRevealUri;
    string public revealUri;
    
    address payable devWallet;


  
    event SaleStateChanged(uint256 previousState, uint256 nextState, uint256 timestamp);
    event GameComplete(uint256[] random, uint256 gameId, uint32 numWords, uint256 numMints, uint256 mintStart);
    event Revealed(bool revealAll);
    event UnClaimedNFTs(uint256[] remainingUnclaimed, uint256 timestamp);
    event PriceChange(uint256 mintPrice,uint256 timestamp);
    event NewMint(uint256 supply,uint256 timestamp);


    constructor(uint64 subscriptionId) ERC721A("DumbNFT", "DNFT") VRFConsumerBaseV2(vrfCoordinator) {
        //Chainlink
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;

        setDevWallet(payable(owner()));
        
        //Defaults
        revealAll = false;
        price = 10000000000000000;
        gameNumber = 1;
        gameStartingTokenID = 0;
       
    }


    modifier whenSaleIsActive() {
        require(saleState != SaleState.Disabled, "Sale is not active");
        _;
    }
    modifier whenRevealIsEnabled() {
        require(revealAll, "Reveal is not yet enabled");
        _;
    }
    // Modifier for winner
    modifier onlyWinner(uint256 tokenId_) {
        require(ownerOf(tokenId_) == msg.sender, "Are you trolling ? You don't even own this NFT... lol");
        require(claimed[tokenId_] == false, "lol...come on man you already...begging you lol");
        require(_verifyWinningToken(tokenId_), "You lost or you already claimed. Don't try this again lol... please...");
        
        _;
    }


    //++++++++
    // Public functions
    //++++++++
    function mint(uint256 amount) external payable whenSaleIsActive {
        
        require(price * amount == msg.value, "Value sent is not correct");
        
        _safeMint(msg.sender, amount);

        emit NewMint(totalSupply(), block.timestamp);

    }

    function withdrawETHWinner(uint256 tokenId_) external whenRevealIsEnabled onlyWinner(tokenId_) {
        require(msg.sender != address(0), "Cannot recover ETH to the 0 address");
        payable(msg.sender).transfer(winnerAmountPerNFT);
        claimed[tokenId_] = true;
        _mintForCommunity(msg.sender);
        _removeWinningTokenOnceClaimed(tokenId_);
        emit UnClaimedNFTs(random, block.timestamp);
    }



    //++++++++
    // Owner functions
    //++++++++

    function setDevSplit(uint256 devSplit_) public onlyOwner {
        devSplit = devSplit_;
    }

    function setDevWallet(address payable devWallet_) public onlyOwner{
        devWallet = payable(devWallet_);
    }

    function setSaleState(uint256 _state) external onlyOwner {
        uint256 prevState = uint256(saleState);
        saleState = SaleState(_state);
        emit SaleStateChanged(prevState, _state, block.timestamp);
    }


    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        price = _mintPrice;
        emit PriceChange(price,block.timestamp);
    }

    function getRandom() external onlyOwner {
        _setNumWords();
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function getRandom(uint32 emergancyNumWords_) external onlyOwner{
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            emergancyNumWords_
        );
    }
    
    function setRevealUri(string calldata uri_) external onlyOwner {
        revealUri = uri_;
    }

    function setUnRevealUri(string calldata uri_) external onlyOwner {
        unRevealUri = uri_;
    }


    function toggleRevealAll() external onlyOwner {
        revealAll = !revealAll;
        emit Revealed(revealAll);
        if(revealAll == true){
            _endGame();
            emit UnClaimedNFTs(random, block.timestamp);
        }
        //if we are going back to unrevealed state (aka start a new game), must set random to empty array to start from scratch
        else{
            
            delete random;
            delete randomPermenant;
        }
    }
    
    function setCallbackGasLimit(uint32 gasLim_) public onlyOwner(){
        callbackGasLimit = gasLim_;
    }

    //++++++++
    // Internal functions
    //++++++++

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Un-paid mint winners
    function _mintForCommunity(address to_) private {
        _safeMint(to_, 1);
        emit NewMint(totalSupply(), block.timestamp);
    }

    function _endGame() private {
        delete randomPermenant;
        randomPermenant = random;
        uint256 numMints = totalSupply() - gameStartingTokenID;
        emit GameComplete(random, gameNumber, numWords, numMints, gameStartingTokenID);

        //Prep values for next game
        gameNumber+=1;
        gameStartingTokenID = totalSupply();
        _devWithdraw();
        winnerAmountPerNFT = _calculateWinnersSplit();
    }

    
    function _devWithdraw() private {
        uint256 balance = address(this).balance;
        balance = balance * devSplit /100;
        devWallet.transfer(balance);
    }


    //calculates percent of winnings per single winning NFT
    function _calculateWinnersSplit() internal view returns(uint256){
        uint256 balance = address(this).balance;
        balance = balance / random.length;
        return balance;
    }

    function _verifyWinningToken(uint256 tokenId_) internal view virtual returns (bool){
        for (uint256 i = 0; i < random.length; i++){
            if (tokenId_ == random[i]){
                return true;
            }
        }
        return false;
    }

    // removes winning token from random to ensure winners dont claim twice
    // in addition resets random 1 by 1, so we don't have to delete values later on
    // will still have to scrub values if any left
    function _removeWinningTokenOnceClaimed(uint256 tokenId_) private {
        for (uint256 i = 0; i < random.length; i++){
            if (tokenId_ == random[i]){
                random[i] = random[random.length -1];
                random.pop();
            }
        }
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        random = randomWords;
        _filterRandoms();
    }

    function _filterRandoms() private {
        uint256 currGameNumMints = totalSupply() - gameStartingTokenID; 
        if(gameNumber == 1){
            for(uint256 i = 0; i < random.length; i++){
                random[i] = (random[i] % totalSupply()) + 1;
            }
        }
        else{
            for(uint256 i = 0; i < random.length; i++){
                random[i] = (random[i] % currGameNumMints) + gameStartingTokenID;
            }
        }
    }

    function _setNumWords() private {
        //capping winners to always be a max of 500
        if((((totalSupply() - gameStartingTokenID)* 5)/ 100) > 500){
            numWords = 500;
        }
        else{
            numWords = uint32(((totalSupply() - gameStartingTokenID)* 5)/ 100);
        }
    }

    function _verifyWinnerbyTokenId(uint256 tokenId_,uint256[] memory random_) internal view virtual returns (bool){
        for (uint256 i = 0; i < random_.length; i++){
            if (tokenId_ == random_[i]){
                return true;
            }
        }
        return false;
    }

    function _verifyWinnerforTokenUri(uint256 tokenId_) internal view returns(bool){
        bool winner;
        for (uint256 i=0; i<=gameNumber; i++){
            if(gameStartingTokenID < tokenId_ && tokenId_ < (totalSupply() - gameStartingTokenID)){
                return _verifyWinnerbyTokenId(tokenId_, randomPermenant);
            }
        }
        return winner;
    }

    //++++++++
    // Emergency functions
    //++++++++
    
    //run once round is done
    function resetEmergencyRandom() public onlyOwner {
        delete emergencyRandom;
    }
    //in case we need to run multiple getRandom() to reach the 5% number of winners
    function appendToEmergencyRandom() public onlyOwner{
        for(uint256 i=0; i<random.length;i++){
            emergencyRandom.push(random[i]);
        }
    }
    function switchBackEmergencyRandomWithRandom() public onlyOwner{
        delete random;
        for(uint256 i=0; i<emergencyRandom.length;i++){
            random.push(emergencyRandom[i]);
        }
        numWords = uint32(random.length);
    }

    //++++++++
    // Override functions
    //++++++++
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(tokenId <= totalSupply(), "This token is greater than maxSupply");

        if (revealAll == true) {
            if(_verifyWinnerforTokenUri(tokenId) == true){
                return string(abi.encodePacked(revealUri, "Winner", ".json")); 
            }
            else{
                return string(abi.encodePacked(revealUri, "Loser", ".json")); 
            }
        } else {
            return unRevealUri;
        }
    }

}