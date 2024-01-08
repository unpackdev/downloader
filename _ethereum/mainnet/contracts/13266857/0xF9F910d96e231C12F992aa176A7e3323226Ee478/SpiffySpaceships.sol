// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract SpiffySpaceships is ERC721, Ownable, ReentrancyGuard {

    uint256 public constant MAX_TOKENS = 1024;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;
    uint256 public constant MAX_NAME_LENGTH = 50;
    uint256 public constant MAX_MSG_LENGTH = 250;
    
    bool public isSaleActive = false;
    bool public isNamingActive = false;
    uint256 public numTokensMinted = 0;
    uint256 public giftsRemaining = 50;
    
    uint256 private price = 0.025 ether;
    string private baseURI = "https://spiffy-spaceships.vercel.app/api/";

    // Leaderboards
    mapping(address => uint256) private numMultiplesOf10;
    mapping(address => uint256) private numMultiplesOf100;
    mapping(address => uint256) private numSingleDigit;
    mapping(address => uint256) private numDoubleDigit;
    
    // Comms
    string public msgMultiplesOf10;
    string public msgMultiplesOf100;
    string public msgSingleDigit;
    string public msgDoubleDigit;
    
    // Naming
    mapping(uint256 => string) private tokenNames;

    event tokenNamed(uint256 indexed tokenId, address indexed owner, string newName);
    event singleDigitLeaderMsgSet(address leader, string newMsg);
    event doubleDigitLeaderMsgSet(address leader, string newMsg);
    event multiplesOf10LeaderMsgSet(address leader, string newMsg);
    event multiplesOf100LeaderMsgSet(address leader, string newMsg);
    
    constructor() ERC721("SpiffySpaceships", "SSS") { }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

	// NOTE: Need this to move metadata to IPFS later
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ETH balance of contract is 0.");

        // Use this, not send() or transfer() to avoid potential out of gas errors and your balance being locked forever
        Address.sendValue(payable(owner()), balance);
    }

    function getOwnersTokens(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory tokenList = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            for (uint256 i = 1; i <= numTokensMinted; i++) {
                if (ownerOf(i) == owner) {
                    tokenList[resultIndex] = i;
                    resultIndex++;
                }
            }

            return tokenList;
        }
    }

    function isOwnerOfToken(address owner, address tokenContract) external view returns(bool) {
        ERC721 newToken = ERC721(address(tokenContract));
        return ( newToken.balanceOf(owner) > 0 );
    }

    //------------------------- STRING MANIPULATION --------------------------
    function trimStr(uint256 maxLength, string calldata str) internal pure returns( string memory ) {
        bytes memory strBytes = bytes(str);

        if (strBytes.length < maxLength) {
            return str;
        } else {
            // Trim down to max length
            bytes memory trimmed = new bytes(maxLength);
            for(uint256 i = 0; i < maxLength; i++) {
                trimmed[i] = strBytes[i];
            }
            return string(trimmed);
        }
    }

    //------------------------- NAMING --------------------------
    function flipNamingStatus() external onlyOwner {
        isNamingActive = !isNamingActive;
    }
     
    function setTokenName(uint256 tokenId, string calldata newName) external {
        require(isNamingActive, "Naming is not active." );
        require(ownerOf(tokenId) == msg.sender, "You are not the token owner.");

        // NOTE - API/JSON metadata will always keep token ID as first part of name (to avoid counterfeiting)
        // Don't worry about reserving names, dupes are fine

        tokenNames[tokenId] = trimStr(MAX_NAME_LENGTH, newName);

        emit tokenNamed(tokenId, msg.sender, tokenNames[tokenId]);
    }
    
    function getTokenName(uint256 tokenId) external view returns( string memory ){
        require( tokenId <= numTokensMinted, "Token doesn't exist." );
        
        return tokenNames[tokenId];
    }

    //------------------------- MESSAGES --------------------------
    function setMsgSingleDigit(string calldata leaderMsg) external {
        require(bytes(leaderMsg).length > 0, "You cannot set an empty message.");
        require(msg.sender == topSingleDigitHolder(), "You are not the leading owner of single-digit mint numbers.");

        msgSingleDigit = trimStr( MAX_MSG_LENGTH, leaderMsg );
        
        emit singleDigitLeaderMsgSet(msg.sender, leaderMsg);
    }
    
    function setMsgDoubleDigit(string calldata leaderMsg) external {
        require(bytes(leaderMsg).length > 0, "You cannot set an empty message.");
        require(msg.sender == topDoubleDigitHolder(), "You are not the leading owner of double-digit mint numbers.");
        
        msgDoubleDigit = trimStr( MAX_MSG_LENGTH, leaderMsg );
        
        emit doubleDigitLeaderMsgSet(msg.sender, leaderMsg);
    }
    
    function setMsgMultiplesOf10(string calldata leaderMsg) external {
        require(bytes(leaderMsg).length > 0, "You cannot set an empty message.");
        require(msg.sender == topMultOf10Holder(), "You are not the leading owner of mint numbers that are multiples of 10.");
        
        msgMultiplesOf10 = trimStr( MAX_MSG_LENGTH, leaderMsg );
        
        emit multiplesOf10LeaderMsgSet(msg.sender, leaderMsg);
    }

    function setMsgMultiplesOf100(string calldata leaderMsg) external {
        require(bytes(leaderMsg).length > 0, "You cannot set an empty message.");
        require(msg.sender == topMultOf100Holder(), "You are not the leading owner of mint numbers that are multiples of 100.");
        
        msgMultiplesOf100 = trimStr( MAX_MSG_LENGTH, leaderMsg );
        
        emit multiplesOf100LeaderMsgSet(msg.sender, leaderMsg);
    }

    //------------------------- GIFTING/MINTING --------------------------
    function flipSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }
     
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function getPrice() external view returns (uint256){
        return price;
    }
    
    function giftTokens(address to, uint256 numTokens) external onlyOwner {        
        require(numTokens <= giftsRemaining, "Exceeds remaining gifts.");

        _mintTokens(to, numTokens);
        
        giftsRemaining = giftsRemaining - numTokens;
    }
    
    function giftManyTokens(address[] calldata to) external onlyOwner {        
        require(to.length <= giftsRemaining, "Exceeds remaining gifts.");

        for(uint256 i = 0; i < to.length; i++){
            _mintTokens(to[ i ], 1);
        }
        
        giftsRemaining = giftsRemaining - to.length;
    }
    
    function mintTokensToSender(uint256 numTokens) external payable nonReentrant {
        require(isSaleActive, "Sale is not active." );
        require(numTokens <= MAX_TOKENS_PER_PURCHASE, "Exceeds maximum tokens you can purchase in a single transaction.");

        uint256 costToMint = price * numTokens;
        require(costToMint <= msg.value, "Insufficient ETH sent to contract.");

        _mintTokens(msg.sender, numTokens);

        // Refund any overpayment
        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    
    
    function _mintTokens(address to, uint256 numTokens) internal {
        require(numTokens > 0, "Must mint at least one token.");
        require(numTokensMinted + numTokens <= MAX_TOKENS, "Exceeds maximum tokens available.");

        for(uint256 i = 0; i < numTokens; i++){
            numTokensMinted++;
            _safeMint(to, numTokensMinted);
        }
    }
    
    
    
    //------------------------- LEADERBOARD TRACKING/MGMT --------------------------
    function _isSingleDigitId(uint256 tokenId) pure private returns(bool) {
        return tokenId < 10;
    }

    function _isDoubleDigitId(uint256 tokenId) pure private returns(bool)  {
        return tokenId < 100 && tokenId >= 10;
    }

    function _isMultipleOf10Id(uint256 tokenId) pure private returns(bool)  {
        return tokenId % 10 == 0;
    }

    function _isMultipleOf100Id(uint256 tokenId) pure private returns(bool)  {
        return tokenId % 100 == 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to){
            if (from != address(0)){
                _decrementTokenCounts(from, tokenId);
            }
            
            _incrementTokenCounts(to, tokenId);
        }
    }
    
    function _decrementAndCleanMapEntry(address a, mapping(address => uint256) storage m) private {
        if (m[a] == 1){
            delete m[a];
        } else {
            m[a]--;
        }
    }
    
    function _decrementTokenCounts(address a, uint256 tokenId) private {
        if (_isSingleDigitId(tokenId)){
            _decrementAndCleanMapEntry(a, numSingleDigit);
        }
        if (_isDoubleDigitId(tokenId)){
            _decrementAndCleanMapEntry(a, numDoubleDigit);
        }
        if (_isMultipleOf10Id(tokenId)){
            _decrementAndCleanMapEntry(a, numMultiplesOf10);
        }
        if (_isMultipleOf100Id(tokenId)){
            _decrementAndCleanMapEntry(a, numMultiplesOf100);
        }
    }
    
    function _incrementTokenCounts(address a, uint256 tokenId) private {
        if (_isSingleDigitId(tokenId)){
            numSingleDigit[a]++;
        }
        if (_isDoubleDigitId(tokenId)){
            numDoubleDigit[a]++;
        }
        if (_isMultipleOf10Id(tokenId)){
            numMultiplesOf10[a]++;
        }
        if (_isMultipleOf100Id(tokenId)){
            numMultiplesOf100[a]++;
        }
    }

    //------------------------- LEADERBOARD VIEWS --------------------------
    function getNumSingleDigit(address a) external view returns (uint256) {
        return numSingleDigit[a];
    }
    
    function getNumDoubleDigit(address a) external view returns (uint256) {
        return numDoubleDigit[a];
    }
    
    function getNumMultiplesOf10(address a) external view returns (uint256) {
        return numMultiplesOf10[a];
    }
    
    function getNumMultiplesOf100(address a) external view returns (uint256) {
        return numMultiplesOf100[a];
    }
    
    function topSingleDigitHolder() public view returns (address) {
        uint256 topCount = 0;
        address topOwner;
        
        for(uint256 i = 1; i < 10; i++){
            if (i <= numTokensMinted){
                address currOwner = ownerOf( i );
                uint256 currCount = numSingleDigit[currOwner];
                
                // Only bump top if greater. That means ties are determined by earliest mint
                if ( currCount > topCount ){
                    topCount = currCount;
                    topOwner = currOwner;
                }
            }
        }
        
        return topOwner;
    }
    
    function topDoubleDigitHolder() public view returns (address) {
        uint256 topCount = 0;
        address topOwner;
        
        for(uint256 i = 10; i < 100; i++){
            if (i <= numTokensMinted){
                address currOwner = ownerOf( i );
                uint256 currCount = numDoubleDigit[currOwner];
                
                // Only bump top if greater. That means ties are determined by earliest mint
                if ( currCount > topCount ){
                    topCount = currCount;
                    topOwner = currOwner;
                }
            }
        }
        
        return topOwner;
    }
    
    function topMultOf10Holder() public view returns (address) {
        uint256 topCount = 0;
        address topOwner;
        
        for(uint256 i = 10; i <= numTokensMinted; i += 10){
            address currOwner = ownerOf( i );
            uint256 currCount = numMultiplesOf10[currOwner];
            
            // Only bump top if greater. That means ties are determined by earliest mint
            if ( currCount > topCount ){
                topCount = currCount;
                topOwner = currOwner;
            }
        }
        
        return topOwner;
    }

    function topMultOf100Holder() public view returns (address) {
        uint256 topCount = 0;
        address topOwner;
        
        for(uint256 i = 100; i <= numTokensMinted; i += 100){
            address currOwner = ownerOf( i );
            uint256 currCount = numMultiplesOf100[currOwner];
            
            // Only bump top if greater. That means ties are determined by earliest mint
            if ( currCount > topCount ){
                topCount = currCount;
                topOwner = currOwner;
            }
        }
        
        return topOwner;
    }

}
