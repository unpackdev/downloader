// SPDX-License-Identifier: MIT


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  █████   ███   █████          ████                                                 █████████   █████                                                               //
// ░░███   ░███  ░░███          ░░███                                                ███░░░░░███ ░░███                                                                //
//  ░███   ░███   ░███   ██████  ░███   ██████   ██████  █████████████    ██████    ░███    ░░░  ███████   ████████   ██████   ████████    ███████  ██████  ████████  //
//  ░███   ░███   ░███  ███░░███ ░███  ███░░███ ███░░███░░███░░███░░███  ███░░███   ░░█████████ ░░░███░   ░░███░░███ ░░░░░███ ░░███░░███  ███░░███ ███░░███░░███░░███ //
//  ░░███  █████  ███  ░███████  ░███ ░███ ░░░ ░███ ░███ ░███ ░███ ░███ ░███████     ░░░░░░░░███  ░███     ░███ ░░░   ███████  ░███ ░███ ░███ ░███░███████  ░███ ░░░  //
//   ░░░█████░█████░   ░███░░░   ░███ ░███  ███░███ ░███ ░███ ░███ ░███ ░███░░░      ███    ░███  ░███ ███ ░███      ███░░███  ░███ ░███ ░███ ░███░███░░░   ░███      //
//     ░░███ ░░███     ░░██████  █████░░██████ ░░██████  █████░███ █████░░██████    ░░█████████   ░░█████  █████    ░░████████ ████ █████░░███████░░██████  █████     //
//      ░░░   ░░░       ░░░░░░  ░░░░░  ░░░░░░   ░░░░░░  ░░░░░ ░░░ ░░░░░  ░░░░░░      ░░░░░░░░░     ░░░░░  ░░░░░      ░░░░░░░░ ░░░░ ░░░░░  ░░░░░███ ░░░░░░  ░░░░░      //
//                                                                                                                                        ███ ░███                    //
//                                                                                                                                       ░░██████                     //
//                                                                                                                                        ░░░░░░                      //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EscrowManagement.sol";
import "./SignedMessages.sol";
import "./TokenSegments.sol";

// we whitelist OpenSea so that minters can save on gas and spend it on NFTs
contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ConjuredLands is ReentrancyGuard, EscrowManagement, ERC721, ERC721Enumerable, Ownable, SignedMessages, TokenSegments  {
    using Strings for uint256; 
    address proxyRegistryAddress;
    mapping (address => bool) private airdroppers;
    mapping(address => uint256[]) private burnedTokensByOwners;
    uint8 public maxNumberOfTokens = 30;
    address[] public ownersThatBurned;
    address[20] public premiumOwners;
    uint256 public tokenPrice = 0.0555 ether;
    uint256 public premiumTokenPrice = 5.55 ether;
    uint256 public constant maxSupply = 10888;
    uint256 public constant maxIndex = 10887;
    mapping (uint256 => uint256) private tokenCreationBlocknumber;
    bool public mintingActive = true;
    bool public burningActive = false;
    uint8 public premiumMintingSlots = 22;
    // that's October 19th 2021 folks!
    uint256 public salesStartTime = 1634839200; 
    mapping (address => uint256) mintingBlockByOwners;
    mapping(address => uint256) public highestAmountOfMintedTokensByOwners;
    string private __baseURI;
    bool baseURIfrozen = false;
    
    // generate random index
    uint256 internal nonce = 19831594194915648;
    mapping(int8 => uint256[maxSupply]) private alignmentIndices;
    // the good, the evil and the neutral https://www.youtube.com/watch?v=WCN5JJY_wiA
    uint16[3] public alignmentMaxSupply;
    uint16[3] public alignmentTotalSupply;
    uint16[3] public alignmentFirstIndex;
    // these are URIs for the custom part, single URLs and segmented baseURIs
    mapping(uint256 => string) specialTokenURIs;

    constructor(string memory _name, string memory _symbol, address[] memory _teamMembers, uint8[] memory _splits, address _proxyRegistryAddress)
    ERC721(_name, _symbol)
    {
        // set the team members
        require(_teamMembers.length == _splits.length, "Wrong team lengths");
        if (_teamMembers.length > 0) {
            uint8 totalSplit = 0;
            for (uint8 i = 0; i < _teamMembers.length; i++) {
                EscrowManagement._addTeamMemberSplit(_teamMembers[i], _splits[i]);
                totalSplit += _splits[i];
            }
            require(totalSplit == 100, "Total split not 100");
        }
        alignmentMaxSupply[0] = 3000; // good
        alignmentMaxSupply[1] = 3000; // evil
        alignmentMaxSupply[2] = 4000; // neutral
        alignmentFirstIndex[0] = 888; // the indexes 0- 887 are reserved for the giveaways
        alignmentFirstIndex[1] = alignmentFirstIndex[0] + alignmentMaxSupply[0];
        alignmentFirstIndex[2] = alignmentFirstIndex[1] + alignmentMaxSupply[1];
        // set the deployer of this contract as an issuer of signed messages
        SignedMessages.setIssuer(msg.sender, true);
        __baseURI = "ipfs://QmamCw1tks7fpFyDCfGYVQyMkSwtJ39BRGxuA2D37hFME1/";
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _baseURI() internal view override returns(string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner(){
        require(!baseURIfrozen, "BaseURI frozen");
        __baseURI = newBaseURI;
    }
    
    function baseURI() public view returns(string memory){
        return __baseURI;
    }

    // calling this function locks the possibility to change the baseURI forever
    function freezeBaseURI() public onlyOwner(){
        baseURIfrozen = true;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // check if token is in a special segment
        int256 segmentId = TokenSegments.getSegmentId(tokenId);
        if (segmentId != -1) {
            // found a segment, get the URI, only return if it is set
            string memory segmentURI = TokenSegments.getBaseURIBySegmentId(segmentId);
            if (bytes(segmentURI).length > 0) {
                return string(abi.encodePacked(segmentURI,tokenId.toString()));
            }
        }
        // check if a special tokenURI is set, otherwise fallback to standard
        if (bytes(specialTokenURIs[tokenId]).length ==  0){
            return ERC721.tokenURI(tokenId);
        } else {
            // special tokenURI is set
            return specialTokenURIs[tokenId];
        }
    }

    function setSpecialTokenURI(uint256 tokenId, string memory newTokenURI) public onlyOwner(){
        require(getAlignmentByIndex(tokenId) == -1, "No special token");
        specialTokenURIs[tokenId] = newTokenURI;
    }

    function setSegmentBaseTokenURIs(uint256 startingIndex, uint256 endingIndex, string memory _URI) public onlyOwner(){
        TokenSegments._setSegmentBaseTokenURIs(startingIndex, endingIndex, _URI);
    }

    function setBaseURIBySegmentId(int256 pointer, string memory _URI) public onlyOwner(){
        TokenSegments._setBaseURIBySegmentId(pointer, _URI);
    }

    /**
        * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns(bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // use this to update the registry address, if a wrong one was passed with the constructor
    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner(){
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function approveAirdropperContract(address contractAddress, bool approval) public onlyOwner(){
        airdroppers[contractAddress] = approval;
    }

    function airdropper_allowedCaller(address caller) public view returns(bool){
        // only team members can airdrop
        return (EscrowManagement.teamMembersSplit[caller] > 0);
    }

    // used by the external airdropper
    function airdropper_allowedToken(uint256 tokenId) public view returns(bool){
        // only tokens in the giveaway section are allowed for airdrops
        return (getAlignmentByIndex(tokenId) == -1);
    }

    function airdropper_mint(address to, uint256 tokenId) public{
        // protect this call - only the airdropper contract can can call this
        require(airdroppers[msg.sender], "Not an airdropper");
        _internalMintById(to, tokenId);
    }

    function setIssuerForSignedMessages(address issuer, bool status) public onlyOwner(){
        SignedMessages.setIssuer(issuer, status);
    }


    function getAlignmentByIndex(uint256 _index) public view returns(int8){
        // we take the last one, and loop
        int8 alignment = -1;
        // check the boundaries - lower than the first or higher than the last
        if ((_index < alignmentFirstIndex[0]) ||
            ((_index > alignmentFirstIndex[alignmentFirstIndex.length - 1] + alignmentMaxSupply[alignmentMaxSupply.length - 1] - 1))) {
            return -1;
        }
        for (uint8 ix = 0; ix < alignmentFirstIndex.length; ix++) {
            if (alignmentFirstIndex[ix] <= _index) {
                alignment = int8(ix);
            }
        }
        return alignment;
    }
    
    function addTeamMemberSplit(address teamMember, uint8 split) public onlyOwner(){
        EscrowManagement._addTeamMemberSplit(teamMember, split);
    }
    
    function getTeamMembers() public onlyOwner view returns(address[] memory){
        return EscrowManagement._getTeamMembers();
    }
    
    function remainingSupply() public view returns(uint256){
        // returns the total remainingSupply
        return maxSupply - totalSupply();
    }

    function remainingSupply(uint8 alignment) public view returns(uint16){
        return alignmentMaxSupply[alignment] - alignmentTotalSupply[alignment];
    }
    
    function salesStarted() public view returns (bool) {
        return block.timestamp >= salesStartTime;
    }
    
    // set the time from which the sales will be started
    function setSalesStartTime(uint256 _salesStartTime) public onlyOwner(){
        salesStartTime = _salesStartTime;
    }
    
    function flipMintingState() public onlyOwner(){
        mintingActive = !mintingActive;
    }
   
    function flipBurningState() public onlyOwner(){
        burningActive = !burningActive;
    }
    
    // change the prices for minting
    function setTokenPrice(uint256 newPrice) public onlyOwner(){
        tokenPrice = newPrice;
    }
    
    function setPremiumTokenPrice(uint256 newPremiumPrice) public onlyOwner(){
        premiumTokenPrice = newPremiumPrice;
    }
    
    function getRandomId(uint256 _presetIndex, uint8 _alignment) internal returns(uint256){
        uint256 totalSize = remainingSupply(_alignment);
        int8 alignment = int8(_alignment);
        // allow the caller to preset an index
        uint256 index;
        if (_presetIndex == 0) {
            index = alignmentFirstIndex[uint8(alignment)] + uint256(keccak256(abi.encodePacked(nonce, "ourSaltAndPepper", blockhash(block.number), msg.sender, block.difficulty, block.timestamp, gasleft()))) % totalSize;
        } else {
            index = _presetIndex;
            alignment = getAlignmentByIndex(index);
        }
        if (alignment == -1) {
            // if the index is out of bounds, then exit
            return 0;
        }
        uint256 value = 0;
        // the indices holds the value for unused index positions
        // so you never get a collision
        if (alignmentIndices[alignment][index] != 0) {
            value = alignmentIndices[alignment][index];
        } else {
            value = index;
        }

        // Move last value to the actual position, so if it get taken, you can give back the free one
        if (alignmentIndices[alignment][totalSize - 1] == 0) {
            // Array position not initialized, so use that position
            alignmentIndices[alignment][index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            alignmentIndices[alignment][index] = alignmentIndices[alignment][totalSize - 1];
        }
        nonce++;
        return value;
    }
    
    // team members can always mint out of the giveaway section
    function membersMint(address to, uint256 tokenId) onlyTeamMembers() public{
        // can only mint in the non public section
        require(getAlignmentByIndex(tokenId) == -1, "Token in public section");
        _internalMintById(to, tokenId);
    }

    // internal minting function by id, can flexibly be called by the external controllers
    function _internalMintById(address to, uint256 tokenId) internal{
        require(tokenId <= maxIndex, "Token out of index");
        _safeMint(to, tokenId);
        getRandomId(tokenId, 0);
        // consume the index in the alignment, if it was part of the open section
        int8 alignment = getAlignmentByIndex(tokenId);
        if (alignment != -1) {
            alignmentTotalSupply[uint8(alignment)]++;
        }
    }

    // internal minting function via random index, can flexibly be called by the external controllers
    function _internalMintRandom(address to, uint256 numberOfTokens, uint8 alignment) internal{
        require(numberOfTokens <= maxNumberOfTokens, "Max amount exceeded");
        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = getRandomId(0, alignment);
            if (alignmentTotalSupply[alignment] < alignmentMaxSupply[alignment]) {
                _safeMint(to, mintIndex);
                alignmentTotalSupply[alignment]++;
            }
        }

        if (numberOfTokens > 0) {
            // this is for preventing getting the id in the same transaction (semaphore)
            mintingBlockByOwners[msg.sender] = block.number;
            // keep track of the minting amounts (even is something has been transferred or burned)
            highestAmountOfMintedTokensByOwners[msg.sender] += numberOfTokens;
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }
    
    function mint(uint256 numberOfTokens, uint8 alignment) public payable nonReentrant{
        require(mintingActive && salesStarted(), "Minting is not active");
        require((tokenPrice * numberOfTokens) == msg.value, "Wrong payment");
        require(numberOfTokens <= remainingSupply(alignment), "Purchase amount exceeds max supply");
        _internalMintRandom(msg.sender, numberOfTokens, alignment);
    }
    
    function premiumMint(uint8 alignment) public payable nonReentrant{
        require(mintingActive && salesStarted(), "Minting is not active");
        require(premiumMintingSlots>0, "No more premium minting slots");
        require(totalSupply()<= maxSupply, "Maximum supply reached");
        require(msg.value == premiumTokenPrice, "Wrong payment");
        premiumOwners[premiumMintingSlots -1] = msg.sender;
        premiumMintingSlots--;
        _internalMintRandom(msg.sender, 1, alignment);
    }
    
    function burn(uint256 tokenId) public nonReentrant{
        require(burningActive, "Burning not active.");
        super._burn(tokenId);
        // keep track of burners
        if (burnedTokensByOwners[msg.sender].length == 0){
            // first time they burn, add the caller to the list
            ownersThatBurned.push(msg.sender);
        }
        burnedTokensByOwners[msg.sender].push(tokenId);
    }
    
    function getBurnedTokensByOwner(address owner) public view returns(uint256[] memory){
        return burnedTokensByOwners[owner];
    }
    
    event FundsReceived(address from, uint256 amount, string description);
    // accounting purposes: we need to be able to split the incoming funds between sales and royalty
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value, "direct payment, no sale");
    }
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value, "direct payment, no sale");
    }

    /*
     *  Functions for handling signed messages
     * 
     * */

    function mintById_SignedMessage(uint256 _tokenId, uint256 _setPrice, uint256 expirationTimestamp, uint256 _nonce, bytes memory _sig) public payable{
        // check validity and execute
        require(expirationTimestamp <= block.timestamp, "Expired");
        bytes32 message = SignedMessages.prefixed(keccak256(abi.encodePacked(msg.sender, _tokenId, _setPrice, expirationTimestamp, _nonce)));
        require(msg.value == _setPrice, "Wrong payment");
        require(SignedMessages.consumePass(message, _sig, _nonce), "Error in signed msg");
        _internalMintById(msg.sender, _tokenId);
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }

    //DAppJS.addSignatureCall('test', 'address', 'uint8', 'uint256', 'uint256', 'uint256','uint256', 'bytes memory');
    function mintByAlignment_SignedMessage(uint8 _alignment, uint256 _numberOfTokens, uint256 _maxAmountOfTokens, uint256 _setPrice, uint256 expirationTimestamp, uint256 _nonce, bytes memory _sig) public payable{
        // check validity and execute
        require(expirationTimestamp <= block.timestamp, "Expired");
        require(_numberOfTokens <= _maxAmountOfTokens, "Amount too big");
        bytes32 message = SignedMessages.prefixed(keccak256(abi.encodePacked(msg.sender, _alignment, _maxAmountOfTokens, _setPrice, expirationTimestamp, _nonce)));
        require(msg.value == _setPrice * _numberOfTokens, "Wrong payment");
        require(SignedMessages.consumePass(message, _sig, _nonce), "Error in signed msg");
        _internalMintRandom(msg.sender, _numberOfTokens, _alignment);
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }

    function mintAnyAlignment_SignedMessage(uint8 _alignment, uint256 _numberOfTokens, uint256 _maxAmountOfTokens, uint256 _setPrice, uint256 expirationTimestamp, uint256 _nonce, bytes memory _sig) public payable{
        // check validity and execute
        require(expirationTimestamp <= block.timestamp, "Expired");
        require(_numberOfTokens <= _maxAmountOfTokens, "Amount too big");
        bytes32 message = SignedMessages.prefixed(keccak256(abi.encodePacked(msg.sender, _maxAmountOfTokens, _setPrice, expirationTimestamp, _nonce)));
        require(msg.value == _setPrice * _numberOfTokens, "Wrong payment");
        require(SignedMessages.consumePass(message, _sig, _nonce), "Error in signed msg");
        _internalMintRandom(msg.sender, _numberOfTokens, _alignment);
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value, "payment by minting sale");
        }
    }
    
    /*
     * Withdrawal functions
    */
    function withdrawToOwner() public onlyOwner(){
        EscrowManagement._withdrawToOwner(owner());
    }
    
    // these functions are meant to help retrieve ERC721, ERC1155 and ERC20 tokens that have been sent to this contract
    function withdrawERC721(address _contract, uint256 id, address to) public onlyOwner(){
        EscrowManagement._withdrawERC721(_contract, id, to);
    }
    
    function withdrawERC1155(address _contract, uint256[] memory ids, uint256[] memory amounts, address to) public onlyOwner(){
        // withdraw a 1155 token
        EscrowManagement._withdrawERC1155(_contract, ids, amounts, to);
    }
    
    function withdrawERC20(address _contract, address to, uint256 amount) public onlyOwner(){
        // withdraw a 20 token
        EscrowManagement._withdrawERC20(_contract, to, amount);
    }
    
    function balanceOf(address owner) public view override(ERC721) returns (uint256) {
        return super.balanceOf(owner);
    }

    function transferSplitByOwner(address from, address to, uint8 split) public onlyOwner(){
        // allow the contract owner to change the split, if anything with withdrawals goes wrong, or a team member loses access to their EOA
        EscrowManagement._transferSplit(from, to, split);
    }
        
    function tokensOfOwner(address owner) public view returns (uint256[] memory){
        // allow this function only after the minting has happened for passed owner
        require(block.number > mintingBlockByOwners[owner], "Hello @0xnietzsche");
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // The address has no tokens
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}