// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./AccessControl.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./Abstract1155Factory.sol";
import "./Utils.sol";
import "./console.sol";
contract Commerce is Abstract1155Factory, ReentrancyGuard  {
    using SafeMath for uint256;

    mapping(uint256 => Token) public tokens;
    event Purchased(uint[] index, address indexed account, uint[] amount);
    event Fused(uint[] index, address indexed account, uint[] amount);
    struct Token {
        string ipfsMetadataHash;
        string extraDataUri;
        mapping(address => uint256) claimedTokens;
        mapping(uint => address) redeemableContracts;
        uint256 numRedeemableContracts;
        mapping(uint => Whitelist) whitelistData;
        uint256 numTokenWhitelists;
        MintingConfig mintingConfig;
        WhiteListConfig whiteListConfig;
        bool isTokenPack;
    }
    struct MintingConfig {
        bool saleIsOpen;
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxMintPerTxn;
        uint256 numMinted;
        uint256 fusionTokenID;
        uint256 fusionQuantity;
        bool fusionOpen;
    }
    struct WhiteListConfig {
        bool maxQuantityMappedByWhitelistHoldings;
        bool requireAllWhiteLists;
        bool hasMerkleRoot;
        bytes32 merkleRoot;
    }
    
    struct Whitelist {
        string tokenType;
        address tokenAddress;
        uint mustOwnQuantity;
        uint256 tokenId;
        bool active;
    }

    string public _contractURI;
   
    constructor(
        string memory _name, 
        string memory _symbol,
        address[] memory _admins,
        string memory _contract_URI
    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for (uint i=0; i< _admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, _admins[i]);
        }
        _contractURI = _contract_URI;
    }

     function getOpenSaleTokens() public view returns (string memory){
        string memory open = "";
        uint256 numTokens = 0;
        while(!Utils.compareStrings(tokens[numTokens].ipfsMetadataHash, "")) {
           if(isSaleOpen(numTokens)){
                open = string(abi.encodePacked(open, Strings.toString(numTokens), ","));
            }
            numTokens++;
        }
        return open;
    }

     function editToken(
        uint256 _tokenIndex,
        string memory _ipfsMetadataHash,
        string memory _extraDataUri,
        uint256 _windowOpens, 
        uint256 _windowCloses, 
        uint256 _mintPrice, 
        uint256 _maxSupply,
        uint256 _maxMintPerTxn,
        uint256 _maxPerWallet,
        bool _maxQuantityMappedByWhitelistHoldings,
        bool _requireAllWhiteLists,
        address[] memory _redeemableContracts
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token storage token = tokens[_tokenIndex];
        token.mintingConfig.windowOpens = _windowOpens;
        token.mintingConfig.windowCloses = _windowCloses;
        token.mintingConfig.mintPrice = _mintPrice;
        token.mintingConfig.maxSupply = _maxSupply;
        token.mintingConfig.maxMintPerTxn = _maxMintPerTxn;
        token.mintingConfig.maxPerWallet = _maxPerWallet;
        token.ipfsMetadataHash = _ipfsMetadataHash;
        token.extraDataUri = _extraDataUri;
        
        for (uint i=0; i<_redeemableContracts.length; i++) {
            token.redeemableContracts[i] = _redeemableContracts[i];
        }
        token.numRedeemableContracts = _redeemableContracts.length;
        token.whiteListConfig.maxQuantityMappedByWhitelistHoldings = _maxQuantityMappedByWhitelistHoldings;
        token.whiteListConfig.requireAllWhiteLists = _requireAllWhiteLists;
    }   

    function addFusion(
        uint256 _tokenIndex,
        uint256 _fusionTokenID, 
        uint256 _fusionQuantity
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token storage token = tokens[_tokenIndex];
        token.mintingConfig.fusionTokenID = _fusionTokenID;
        token.mintingConfig.fusionQuantity = _fusionQuantity;
    }

    function toggleFusion(
        uint256 _tokenIndex,
        bool _fusionOpen
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token storage token = tokens[_tokenIndex];
        token.mintingConfig.fusionOpen = _fusionOpen;
    }

    function addWhiteList(
         uint256 _tokenIndex,
         string memory _tokenType,
         address _tokenAddress,
         uint _tokenId,
         uint _mustOwnQuantity
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        Whitelist storage whitelist = tokens[_tokenIndex].whitelistData[tokens[_tokenIndex].numTokenWhitelists];
        whitelist.tokenType = _tokenType;
        whitelist.tokenId = _tokenId;
        whitelist.active = true;
        whitelist.tokenAddress = _tokenAddress;
        whitelist.mustOwnQuantity = _mustOwnQuantity;
        tokens[_tokenIndex].numTokenWhitelists = tokens[_tokenIndex].numTokenWhitelists + 1;
    }

     function disableWhiteList(
       uint256 _tokenIndex,
       uint _whiteListIndexToRemove
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_tokenIndex].whitelistData[_whiteListIndexToRemove].active = false;
    }

   function editTokenWhiteListMerkleRoot(
       uint256 _tokenIndex,
        bytes32 _merkleRoot,
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[_tokenIndex].whiteListConfig.merkleRoot = _merkleRoot;
        tokens[_tokenIndex].whiteListConfig.hasMerkleRoot = enabled;
    } 

   
     function burnFromRedeem(
        address account, 
        uint256 tokenIndex, 
        uint256 amount
    ) external {
        Token storage token = tokens[tokenIndex];
        bool hasValidRedemptionContract = false;
         if(token.numRedeemableContracts > 0){
            for (uint i=0; i < token.numRedeemableContracts; i++) {
                if(token.redeemableContracts[i] == msg.sender){
                    hasValidRedemptionContract = true;
                }
            }
        }
        require(hasValidRedemptionContract, "1");
        _burn(account, tokenIndex, amount);
    }  

    function fusion(
        uint256 tokenIndex, 
        uint256 amount
    ) external nonReentrant{
        Token storage token = tokens[tokenIndex];
        require(token.mintingConfig.fusionOpen, "20");
        Whitelist memory balanceRequest;
        balanceRequest.tokenType = "ERC1155";
        balanceRequest.tokenAddress = address(this);
        balanceRequest.tokenId = token.mintingConfig.fusionTokenID;
        uint256 balance = getExternalTokenBalance(msg.sender, balanceRequest);

        require(balance > token.mintingConfig.fusionQuantity, "21");
        uint256 numToIssue = amount.div(token.mintingConfig.fusionQuantity);
        uint256[] memory idsToMint;
        uint256[] memory quantitiesToMint;
        idsToMint = new uint256[](1);
        idsToMint[0] =  tokenIndex;
        quantitiesToMint = new uint256[](1);
        quantitiesToMint[0] = numToIssue;
        _mintBatch(msg.sender, idsToMint, quantitiesToMint, "");
        _burn(msg.sender, token.mintingConfig.fusionTokenID, amount);
        emit Fused(idsToMint, msg.sender, quantitiesToMint);
    }  

    function purchase(
        uint256[] calldata _quantities,
        uint256[] calldata _tokenIndexes,
        uint256[] calldata _merkleAmounts,
        bytes32[][] calldata _merkleProofs
    ) external payable nonReentrant {
        uint256 totalPrice = 0;
        for (uint i=0; i< _tokenIndexes.length; i++) {
            require(isSaleOpen(_tokenIndexes[i]), "5");
            require(tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(_quantities[i]) <= _merkleAmounts[i], "8");
            require(tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(_quantities[i]) <= tokens[_tokenIndexes[i]].mintingConfig.maxPerWallet, "9");
            require(_quantities[i] <= tokens[_tokenIndexes[i]].mintingConfig.maxMintPerTxn, "10");
            require(getTokenSupply(_tokenIndexes[i]) + _quantities[i] <= tokens[_tokenIndexes[i]].mintingConfig.maxSupply, "11");
            totalPrice = totalPrice.add(_quantities[i].mul(tokens[_tokenIndexes[i]].mintingConfig.mintPrice));
        }
        require(!paused() && msg.value >= totalPrice, "3");
        for (uint i=0; i< _tokenIndexes.length; i++) {
            
            uint256 quantityToMint = getQualifiedAllocation(msg.sender,_tokenIndexes[i], _quantities[i],_merkleAmounts[i],_merkleProofs[i], true); 
            require(quantityToMint > 0 && quantityToMint >= _quantities[i], "4");
        
            uint256[] memory idsToMint;
            uint256[] memory quantitiesToMint;
           
           
             idsToMint = new uint256[](1);
            idsToMint[0] =  _tokenIndexes[i];
            quantitiesToMint = new uint256[](1);
            quantitiesToMint[0] = _quantities[i];
                tokens[_tokenIndexes[i]].claimedTokens[msg.sender] = tokens[_tokenIndexes[i]].claimedTokens[msg.sender].add(_quantities[i]);
            _mintBatch(msg.sender, idsToMint, quantitiesToMint, "");
            
            
        }
        emit Purchased(_tokenIndexes, msg.sender, _quantities);
    }
    

    
    function mintBatch(
        address to,
        uint256[] calldata qty,
        uint256[] calldata _tokens) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mintBatch(to, _tokens, qty, "");
    }

     function getQualifiedAllocation(address sender, 
        uint256 tokenIndex,
        uint256 quantity,
        uint256 amount,
        bytes32[] calldata merkleProof,
        bool returnAllocationOnly) public view returns (uint256) {
        
        Token storage token = tokens[tokenIndex];

        uint256 totalAllowed = token.mintingConfig.maxPerWallet;
        if(token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
            totalAllowed = 0;
        }

        uint256 whiteListsValidAmounts = 0;
        if(token.numTokenWhitelists > 0){
            uint256 balance = 0;
            uint256 _wl_amount = 0;
            for (uint i=0; i < token.numTokenWhitelists; i++) {
                if(token.whitelistData[i].active){
                
                    _wl_amount = verifyWhitelist(sender, tokenIndex, i, returnAllocationOnly);
                    
                    if(token.whiteListConfig.requireAllWhiteLists){
                        require( verifyWhitelist(sender, tokenIndex, i, returnAllocationOnly) > 0, "12");
                    }
                    
                    if(token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
                        Whitelist memory balanceRequest;
                        balanceRequest.tokenType = token.whitelistData[i].tokenType;
                        balanceRequest.tokenAddress = token.whitelistData[i].tokenAddress;
                        balanceRequest.tokenId = token.whitelistData[i].tokenId;
                        balance = getExternalTokenBalance(sender, balanceRequest);
                        totalAllowed += balance;
                        whiteListsValidAmounts += balance;
                        
                    }
                    else{
                        whiteListsValidAmounts = _wl_amount;
                    }
                }
               
            }
        }
        else{
            whiteListsValidAmounts = token.mintingConfig.maxMintPerTxn;
        }

        if(!returnAllocationOnly){
            require(whiteListsValidAmounts > 0, "13");

            if(token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
            require(token.claimedTokens[sender].add(quantity) <= totalAllowed, "14");
            }
        }
       

        if(token.whiteListConfig.hasMerkleRoot){
             require(
                verifyMerkleProof(merkleProof, tokenIndex, amount),
                "15" 
            ); 
            //whiteListsValidAmounts += quantity;
        }
        
        if(returnAllocationOnly){
            return whiteListsValidAmounts < quantity ? whiteListsValidAmounts : quantity;
        }
        else{
            return whiteListsValidAmounts;
        }
       
         

    }

    function verifyWhitelist(address sender, uint256 tokenIndex, uint whitelistIndex, bool returnAllocationOnly) internal view returns (uint256) {
       
       uint256 isValid = 0;
       uint256 balanceOf = 0;
       Token storage token = tokens[tokenIndex];
       Whitelist memory balanceRequest;
       balanceRequest.tokenType = token.whitelistData[whitelistIndex].tokenType;
       balanceRequest.tokenAddress = token.whitelistData[whitelistIndex].tokenAddress;
       balanceRequest.tokenId = token.whitelistData[whitelistIndex].tokenId;
       balanceOf = getExternalTokenBalance(sender, balanceRequest);
       bool meetsWhiteListReqs = (balanceOf >= token.whitelistData[whitelistIndex].mustOwnQuantity);
       
        if(!token.isTokenPack && token.whiteListConfig.maxQuantityMappedByWhitelistHoldings){
            isValid = balanceOf;
        
        }
        else if( meetsWhiteListReqs){
            isValid = token.mintingConfig.maxMintPerTxn;
        }

        if(isValid == 0 && !token.whiteListConfig.requireAllWhiteLists){
            isValid = token.mintingConfig.maxMintPerTxn;
        }
        return isValid;
    }


    function getExternalTokenBalance (address sender, Whitelist memory balanceRequest) public view returns (uint256) {
        if(Utils.compareStrings(balanceRequest.tokenType, "ERC721")){
            WhitelistContract721 _contract = WhitelistContract721(balanceRequest.tokenAddress);
            return _contract.balanceOf(sender);
        }
        else if(Utils.compareStrings(balanceRequest.tokenType, "ERC1155")){
            WhitelistContract1155 _contract = WhitelistContract1155(balanceRequest.tokenAddress);
            return _contract.balanceOf(sender, balanceRequest.tokenId);
        }
    }

    function isSaleOpen(uint256 tokenIndex) public view returns (bool) {
        Token storage token = tokens[tokenIndex];
        if(paused()){
            return false;
        }
        if(block.timestamp > token.mintingConfig.windowOpens && block.timestamp < token.mintingConfig.windowCloses){
            return token.mintingConfig.saleIsOpen;
        }
        return false;
        
    }

    function toggleSale(uint256 mpIndex, bool on) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens[mpIndex].mintingConfig.saleIsOpen = on;
    }


    function verifyMerkleProof(bytes32[] calldata merkleProof, uint256 mpIndex, uint amount) public view returns (bool) {
        if(!tokens[mpIndex].whiteListConfig.hasMerkleRoot){
            return true;
        }
        string memory leaf = Utils.makeLeaf(msg.sender, amount);
        bytes32 node = keccak256(abi.encode(leaf));
        return MerkleProof.verify(merkleProof, tokens[mpIndex].whiteListConfig.merkleRoot, node);
    }


    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(getTokenSupply(_id) > 0, "16");
        if(Utils.compareStrings(tokens[_id].ipfsMetadataHash, "")){
            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
        }
        else{
            return string(abi.encodePacked(tokens[_id].ipfsMetadataHash));
        }   
    } 

    

     function getTokenSupply(uint256 tokenIndex) public view returns (uint256) {
         Token storage token = tokens[tokenIndex];
        return token.isTokenPack ? token.mintingConfig.numMinted : totalSupply(tokenIndex);
    }
}
contract WhitelistContract1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256) {}
}
contract WhitelistContract721 {
    function balanceOf(address account) external view returns (uint256) {}
 }