//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

import "./Pausable.sol";
import "./NPassCore.sol";
import "./IN.sol";

import "./Helpers.sol";

/**
 * @title RenAIssaNce -> forked from NDerivative
 * @author Inspired by @KnavETH @0xBlossom
 */
contract Renaissance is NPassCore, Pausable{

    mapping(uint => uint) public metaId;

    // Rarity checkers
    uint256[] private isRare;
    uint256[] private isSuperRare;

    // The starting metaID indexes for each tournament round [ROUND0, ROUND1, ROUND2, FINAL_ROUND]
    uint256[] private superRareCounter =    [ 0, 1200, 1450, 1525];
    uint256[] private rareCounter =         [40, 1215, 1455, 1528];
    uint256[] private commonCounter =       [80, 1230, 1460, 1531];

    // The limit of mints in each tournement round [ROUND0, ROUND1, ROUND2, FINAL_ROUND]
    uint256[] private MAX_SUPER_RARE_NUMBER =   [40, 1215, 1455, 1528];
    uint256[] private MAX_RARE_NUMBER =         [80, 1230, 1460, 1531];
    uint256[] private MAX_COMMON_NUMBER =       [1200,1450,1525, 1545];

    // This block contains adjustable flags for minting rounds
    uint256 private currentPrice = 0;
    uint256 private currentRound = 0;

    // IPFS URLS for each round, they are mutable until BASE_LOCK is called for each index
    string[] private BASE_URIS = ["ipfs://QmYNc7SNm5boYDwKgqyrXX1aqHidHXAVRnjwqnF4hHqpRV", "", "",""];
    bool[] private BASE_LOCK = [true, false, false, false];

    // Allow common minters for overflow upwards into rare / rare into super_rare
    bool private _allowMovingUp = false;

    // Constructor uses NPassCore
    constructor(
        address _nContractAddress,
        uint256[] memory _superRareIds,
        uint256[] memory _rareIds
    ) 
        NPassCore("renaiss.art | art reborn", "RENAI", IN(_nContractAddress), true, 1545, 0, 0, 0) {
            isRare = _rareIds;
            isSuperRare = _superRareIds;
    }

    /** Allow moving up
      * @notice Controls upwards overflow out of rareness categories
     */
    function allowMovingUp() public view onlyOwner returns(bool) {
        return _allowMovingUp;
    }
    function setAllowMovingUp(bool _newValue) public onlyOwner {
        _allowMovingUp = _newValue;
    }


    /** Open Zepellin Pausable
     */
    function pauseMints() public onlyOwner {
        _pause();
    }
    function resumeMints() public onlyOwner {
        _unpause();
    }

    /** Set the mint price  
     * @notice To be used for setting price for later tournament rounds
     */
    function setCurrentPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice >= 0, "REN:InvalidPrice");
        currentPrice = _newPrice;
    }
    function getCurrentPrice() public view returns (uint){
        return currentPrice;
    }

    /**Set current round
     *@notice sets the current round for pending mints 
     * Only 
     */
    function setCurrentRound(uint256 _newValue) public onlyOwner {
        require(_newValue >= 0 && _newValue < 4, "REN:RoundNotValid");
        require(bytes(BASE_URIS[_newValue]).length > 0, "REN:URINotSet");
        currentRound = _newValue;
    }
    function getCurrentRound() public view returns (uint) {
        return currentRound;
    }

    /** Set the IPFS Link for each tournment round
     * @notice can only be done when the round is unlocked
     */
    function setIPFSLink(string calldata _newValue, uint _round) public onlyOwner {
        require(!BASE_LOCK[_round], "REN:RoundLocked");
        BASE_URIS[_round] = _newValue;
    }
    function getCurrentIPFSLink() public view returns (string memory) {
        string memory base_uri = BASE_URIS[currentRound];
        return base_uri;
    }
    
    /** Lock the IPFS link for that round
     *  @notice CANNOT BE UNSET USE WITH CAUTION
     */
    function setLockRound(uint _round) public onlyOwner{
        require(_round >= 0 && _round < 4, "REN:RoundNotValid");
        BASE_LOCK[_round] = true;
    }

    /** Get base URI from MetaID
     * @notice Each tournement round has a different metadata range, this allows them to use different IPFS links based 
     * on the round in which they were minted
     */
    function getBaseURIFromMetaId(uint _metaId) internal view returns (string memory){
        if (_metaId < 1200){
            return BASE_URIS[0];
        }
        else if (_metaId < 1450){
            return  BASE_URIS[1];
        }
        else if (_metaId < 1525){
            return BASE_URIS[2];
        }
        else {
            return BASE_URIS[3];
        }
    }

    /** TokenURI - reference to ERC721 metadata
     * @notice uses getBASEURIFROMMETAID to determine base URI hash
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint _metaId = getMetaId(tokenId);
        string memory baseURI = getBaseURIFromMetaId(_metaId);
        string memory uri = RenaissanceHelpers.append(baseURI,"/", RenaissanceHelpers.toString(_metaId));
        return uri;
    }

    /** Decides the rarity of the N holder based on the rarity of their token 
     */
    function assignMetaId(uint256 _tokenId) internal returns (uint256){
        if(RenaissanceHelpers.checkRarity(_tokenId, isSuperRare)){
            if(superRareCounter[currentRound] < MAX_SUPER_RARE_NUMBER[currentRound]){

                return superRareCounter[currentRound]++;

            }else if(rareCounter[currentRound] < MAX_RARE_NUMBER[currentRound]){
                
                return rareCounter[currentRound]++;
            }else if (commonCounter[currentRound] < MAX_COMMON_NUMBER[currentRound]){
                
                return commonCounter[currentRound]++;
            }else{ 
                
                revert("All have been minted.");
            }
        }else if(RenaissanceHelpers.checkRarity(_tokenId, isRare)){
            if(rareCounter[currentRound] < MAX_RARE_NUMBER[currentRound]){
                
                return rareCounter[currentRound]++;
            }else if (commonCounter[currentRound] < MAX_COMMON_NUMBER[currentRound]){
                
                return commonCounter[currentRound]++;
            }
            else if(_allowMovingUp && superRareCounter[currentRound] < MAX_SUPER_RARE_NUMBER[currentRound]){
                
                return superRareCounter[currentRound]++;
            }
            else{
                revert("All have been minted.");
            }
        }
        else {
            if (commonCounter[currentRound] < MAX_COMMON_NUMBER[currentRound]){
                return commonCounter[currentRound]++;
            }else  if(_allowMovingUp && rareCounter[currentRound] < MAX_RARE_NUMBER[currentRound]){
                return rareCounter[currentRound]++;
            }else if(_allowMovingUp && superRareCounter[currentRound] < MAX_SUPER_RARE_NUMBER[currentRound]){
                return superRareCounter[currentRound]++;
            }else{
                revert("All have been minted.");
            }
        }
    }


     /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @param tokenId Id to be minted
     */
    function mintWithN(uint256 tokenId) public payable override nonReentrant whenNotPaused {
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(n.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");
        require(msg.value == currentPrice, "REN:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }

        uint256 _metaId = assignMetaId(tokenId);
        uint256 _roundAdjustedID = ((tokenId * 100) + currentRound);
        metaId[_roundAdjustedID] = _metaId;
        _safeMint(msg.sender, _roundAdjustedID);
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param tokenIds Ids to be minted
     */
    function multiMintWithN(uint256[] calldata tokenIds) public payable override nonReentrant whenNotPaused {
        uint256 maxTokensToMint = tokenIds.length;
        require(maxTokensToMint <= MAX_MULTI_MINT_AMOUNT, "NPass:TOO_LARGE");
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + maxTokensToMint <= maxTotalSupply) ||
                reserveMinted + maxTokensToMint <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value == currentPrice * maxTokensToMint, "NPass:INVALID_PRICE");
        // To avoid wasting gas we want to check all preconditions beforehand
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(n.ownerOf(tokenIds[i]) == msg.sender, "NPass:INVALID_OWNER");
        }

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(maxTokensToMint);
        }
        for (uint256 i = 0; i < maxTokensToMint; i++) {
            uint256 _metaId = assignMetaId(tokenIds[i]);
            uint256 _roundAdjustedID = ((tokenIds[i] * 100) + currentRound);
            metaId[_roundAdjustedID] = _metaId;
            _safeMint(msg.sender, _roundAdjustedID);
        }
    }
     
    /**
        notice: Only public for verification purposes, returns the base_url/metaID for the provided token
        @param _tokenId - the tokenID to search with
     */
    function getMetaId(uint256 _tokenId) public view returns (uint256){
        return metaId[_tokenId];
    }
}

