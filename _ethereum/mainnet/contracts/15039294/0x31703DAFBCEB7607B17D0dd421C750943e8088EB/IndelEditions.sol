// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol"; 

contract EditionsToken is ERC721A, Ownable, ReentrancyGuard {
    
    string public hiddenMetadataUri;
    string public currentCardName;
    string public uriPrefix = 'https://arweave.net/__ARWEAVE_HASH_/';
    string public uriSuffix = '.json';

    uint256 public mintPeriodDeadline;
    uint256 public maxSupply = 0;
    uint256 public maxMintAmountPerTx;
    uint256 public mintRate = 0.005 ether;
    uint256 public frenlistMintRate = 0.004 ether;

    bool public paused = false;
    bool public revealing = false;
    
    uint256 public currentCardNo = 0;   
    uint256 public currentCardIssueCount = 0;
    uint256 public currentTokenId = 0;
    uint256 public currentCardLimit = 0;
    bytes32 public frenlistMerkleRoot;

    // mappings for card attributes
    mapping(uint256 => string) tokenIdToCardNames;
    mapping(uint256 => uint256) tokenIdToCardNumber;
    mapping(uint256 => uint256) tokenIdToCardIssueNumber;
    mapping(uint256 => uint256) tokenIdToCardIssuance;
    mapping(uint256 => bool) tokenIdToCardReveal;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }
    


    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setNewCard(string memory _cardName, uint256 cardlimit, uint256 deadline, bool _revealing) public onlyOwner {
      
      if(currentCardIssueCount < currentCardLimit){ // if  the current cards mint count is less than limit...
        // you can't just set a new Card up (closing the last card) while a card is in its minting period, unless its sold out.
        require(block.timestamp >= mintPeriodDeadline, "You can't add a new card during a sale, wait till deadline is over then set new card.");
      }

      require(deadline >= (block.timestamp + 24 hours), "There has to be longer than one days minting period");

      // Acciently setting to far int he future would be immutable and non-recoverable so an imposed limit of 2 
      // weeks provides grace for a good selling window, while still be managable if a mistake was made.
      
      require(deadline <= (block.timestamp + 14 days), "There has to be shorter than 2 weeks minting period");
      currentCardNo ++;
      if(currentCardNo > 1){
        // backfill the last cards issuance count.
        for (uint i=currentTokenId; i>=((currentTokenId+1)-currentCardIssueCount); i--) {
            tokenIdToCardIssuance[i] = currentCardIssueCount;
        }
      }
      mintPeriodDeadline = deadline;
      currentCardName = _cardName;
      currentCardIssueCount = 0;
      currentCardLimit = cardlimit; 
      revealing = _revealing;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        // If operating under revealing the tokenURI, only use the hiddenMetaDataUrI if the 
        // token being requested is also the currentcard, all cards that have minted already should 
        // be presumed as non-revealing (revealed already), also meaning that setting a newCard to 
        //mint reveals the last cards without needing to reveal manually.

        if (revealing == true && tokenIdToCardNumber[_tokenId] == currentCardNo) {
         return hiddenMetadataUri;
        }

        string memory currentBaseURI = uriPrefix;
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
        : '';
    }
    function mint(uint256 quantity) external payable {
        require(block.timestamp < mintPeriodDeadline, "The dealine to mint this card has now passed.");
        if (msg.sender != owner()) {
            require(!paused, "Minting is paused!");
            require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        }
        require(currentCardIssueCount + quantity <= currentCardLimit, "Not enough tokens left, Beyond Cards Issuance limits");
        // Once a MaxSupply Cap is Added, Respect it.
        require(maxSupply == 0 || (currentTokenId+quantity) <= maxSupply, "Not enough tokens left - Goes beyond maximum Supply");
        SetCardDetails(quantity);
        _safeMint(msg.sender, quantity);
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                leaf
            ),
            "Address is not in the frenslist"
        );
        _;
    }

    function mintFrenlist(bytes32[] calldata merkleProof, uint256 quantity)
        public
        payable
        isValidMerkleProof(merkleProof, frenlistMerkleRoot)
    {
       require(block.timestamp < mintPeriodDeadline, "The dealine to mint this card has now passed.");
        if (msg.sender != owner()) {
            require(!paused, "Minting is paused!");
            require(msg.value >= (frenlistMintRate * quantity), "Not enough ether sent");
        }
        require(currentCardIssueCount + quantity <= currentCardLimit, "Not enough tokens left, Beyond Cards Issuance limits");
        // Once a MaxSupply Cap is Added, Respect it.
        require(maxSupply == 0 || (currentTokenId+quantity) <= maxSupply, "Not enough tokens left - Goes beyond maximum Supply");
        SetCardDetails(quantity);
        _safeMint(msg.sender, quantity);
    }


    function SetCardDetails(uint256 quantity) private { 
        for (uint i=0; i<quantity; i++) {
            currentCardIssueCount ++;
            currentTokenId ++;
            tokenIdToCardNames[currentTokenId] = currentCardName;
            tokenIdToCardNumber[currentTokenId] = currentCardNo;
            tokenIdToCardIssueNumber[currentTokenId] = currentCardIssueCount;
            tokenIdToCardIssuance[currentTokenId] = currentCardLimit;
            tokenIdToCardReveal[currentTokenId] = revealing;
        }
    }
    function setCurrentCardLimit(uint256 limit) public onlyOwner{
        require(limit< currentCardLimit, "You can't modify the limit on the current Card unless you reduce it.");
        currentCardLimit = limit;
    }
    function setMintRate(uint256 _cost) public onlyOwner {
        if(!(currentCardIssueCount ==0 || currentCardLimit == currentCardIssueCount)    ){
            require(block.timestamp >= mintPeriodDeadline, "You can't change the mint rate during a sale, unless its minted out or completely unsold yet");
        }
        mintRate = _cost;
    }
    function setFrenListMintRate(uint256 _cost) public onlyOwner {
        if(!(currentCardIssueCount ==0 || currentCardLimit == currentCardIssueCount)){
            require(block.timestamp >= mintPeriodDeadline, "You can't change the mint rate during a sale, unless its minted out or completely unsold yet");
        }
        frenlistMintRate = _cost;
    }
    function setMintPeriod(uint256 deadline) public onlyOwner {
        require(deadline < mintPeriodDeadline, "You can't lengthen the mint period once it has been set for this card.");
        // You can reduce the time period, but not in the last 24 hours - no funny business while closing.
        require(deadline >= (block.timestamp + 24 hours), "You can't reduce the time period in the last 24hrs ");
        mintPeriodDeadline = deadline;
    }
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        // open ended as each card has its issuance locked, when decided the figure is final and not updateable.
        require(maxSupply>0, "You can't reset the maxSupply to 0");   
        if(maxSupply != 0 ){
            require(_maxSupply < maxSupply, "You can not increase the max supply limits, unless setting the cap for the first time");
        }
        maxSupply = _maxSupply;
    }
    // get cards attributes Name, CardNo, CardIssue.
    function cardName(uint256 tokenId) public view returns(string memory) {
        return tokenIdToCardNames[tokenId];
    }
    function cardNumber(uint256 tokenId) public view returns(uint256)   {
        return tokenIdToCardNumber[tokenId];
    }
    function cardIssueNumber(uint256 tokenId) public view returns(uint256){
        return tokenIdToCardIssueNumber[tokenId];
    }
    function cardIssuance(uint256 tokenId) public view returns(uint256){
        return tokenIdToCardIssuance[tokenId];
    }
    function cardDetails(uint256 tokenId) public view returns(uint256 ,uint256 , string memory, uint256 ,uint256, bool){
        require(_exists(tokenId), 'ERC721Metadata: card details query for nonexistent token');
        return (tokenId, tokenIdToCardNumber[tokenId],  tokenIdToCardNames[tokenId], tokenIdToCardIssueNumber[tokenId], tokenIdToCardIssuance[tokenId],tokenIdToCardReveal[tokenId]);
    }

    function setFrenlistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        frenlistMerkleRoot = merkleRoot;
    }

    function withdraw(address _recipient) public payable onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }
      
    function setRevealed(bool _state) public onlyOwner {
        // a card is released revealed or not, it is only 
        // allowed to change state before or after a sale but not during.
        require(currentCardIssueCount == 0 || currentCardIssueCount == currentCardLimit,"You can only update the 'revealing' setting if no tokens or all tokens are minted for the current Card, at the start or end of a sale.");
        revealing = _state;
    }

}