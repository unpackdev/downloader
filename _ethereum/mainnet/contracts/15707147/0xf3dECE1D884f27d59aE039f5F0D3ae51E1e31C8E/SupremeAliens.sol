// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

/*
                                             ...........                                           
                                      ..,:loxkO0000000Okxol:,..                                    
                                  .'cdOXNWMMMMMMMMMMMMMMMMMWNKko:.                                 
                               .'lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.                               
                             .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.                            
                           .,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMW0c.                           
                          .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                          
                         .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'                         
                        .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                        
                        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                       
                       .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                       
                       'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                       
                       ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                       
                       ;KMNOkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OkONMK;                       
                       'OMK: ....';cokKWMMMMMMMMMMMMMMMMMMMMWKkoc;,.... :XMO'                      
                       .dWWl.  .     ..;dKWMMMMMMMMMMMMMMWKd;..        .oWWd.                       
                        'OMO'            .c0WMMMMMMMMMMW0c.       .    'OMK;                        
                         :XNl.             .oNMMMMMMMMNo. .     .     .oNNo.                        
                         .lNXc.             .cXMMMMMMXc.            ..cXWx.                         
                          .oNXl. ..        . .lNMMMMNl. .         . .lXWk.                          
                           .oNNk,.            .kWMMMk.            .,xNWx.                           
                            .lXMXx:.     .    .cNMMNl.  .       .:xXWNd.                            
                             .:0WMNKxc;...     ;KMMK,     ...;lx0NMMXc.                             
                               ,kNMMMMNX0kdollcoXMWXocllodk0XWMMMMWO;.                              
                                .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                                
                                 .,kNMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.                                 
                                   .:0WMMMMMMMMMMMMMMMMMMMMMMMXo.                                   
                                     .lKWMMMMMMMMMMMMMMMMMWMNx,.                                    
                                       .oKWMMMMMMMMMMMMMMMWO:.                                      
                                        .'o0WMMMMMMMMMMMNOc.                                        
                                         ...:xKWMMMMWWKx:.                                         
                                              .;clllc;..         
                                                👽👽👽
*/

contract SupremeAliens is ERC1155, Ownable {
    string public name = "Supreme Aliens";
    string public symbol = "SANFT";
    string private ipfsCID = "QmcpCFTP1L5KCXSoAJrGegoAsXPhAbCPBjCozfwm3GprGC";
    string private hiddenCIDorURI = "";
    uint256 public collectionTotal = 400;
    uint256 public cost = 0.03 ether;
    uint256 public maxMintAmount = 10;
    uint256 public maxBatchMintAmount = 10;
    uint256 public whitelisterLimit = 5;

    bool public paused = true;
    bool public revealed = true;
    bool public mintInOrder = true;

    uint256 public tokenNextToMint;
    mapping(uint => string) private tokenToURI;
    mapping(uint256 => uint256) private currentSupply;
    mapping(uint256 => bool) private hasMaxSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => bool) private hasMaxSupplyForBatch;
    mapping(uint256 => uint256) public maxSupplyForBatch;
    mapping(uint256 => bool) private createdToken;

    bool public roleInUse = false;
    mapping(uint256 => string) public role;
    uint256 public roleLimitMin;
    uint256 public roleLimitMax;

    mapping(uint256 => uint256[]) public requirementTokens;
    mapping(uint256 => uint256[]) public batchRequirementTokens;

    mapping(uint256 => bool) public flagged;
    mapping(address => bool) public restricted;

    uint256[] public collectionBatchEndID;
    string[] public ipfsCIDBatch;
    string[] public uriBatch;

    mapping(address => uint256) public holdersAmount;
    mapping(address => uint256) public claimBalance;

    uint256 public phaseForMint = 1;
    uint256 public phaseCheckPoint = 1;
    uint256 public phaseTriggerPoint = 150;
    uint256 public phaseCostNext = 0.04 ether;

    bool public onlyWhitelisted = false;
    address[] public whitelistedAddresses;
    mapping(address => mapping(uint256 => uint256)) public whitelisterMintedPhaseBalance;
    uint256 public costForWhitelisters = 0.01 ether;
    mapping(address => uint256) public whitelistTier;
    uint256[] public costTiers;
    uint256[] public whitelisterTierLimits;

    address payable public payments;
    address public projectLeader;
    address[] public admins;
    uint256 public devpayCount = 1;
    uint256 private devpayCountMax = 0;

    constructor() ERC1155(""){
        collectionBatchEndID.push(collectionTotal);
        ipfsCIDBatch.push(ipfsCID);
        uriBatch.push("");
        maxSupply[1] = 1;
        hasMaxSupply[1] = true;
        createdToken[1] = true;
        currentSupply[1] = 1;
        tokenNextToMint = 2;
        _mint(msg.sender, 1, 1, "");

        projectLeader = 0xf9f2596D8014677ea00F68ef09cF2f3dd179a3F9;

    }

    /**
     * @dev The contract developer's website.
     */
    function contractDev() public pure returns(string memory){
        string memory dev = unicode"🐸 https://www.halfsupershop.com/ 🐸";
        return dev;
    }

    /**
     * @dev Admin can set the PAUSE state.
     * true = closed to Admin Only
     * false = open for Presale or Public
     */
    function pause(bool _state) public onlyAdmins {
        paused = _state;
    }

    /**
     * @dev Admin can set the roleInUse state allowing Mints to pick a role randomly.
     */
    function setRoleInUse(bool _state) public onlyAdmins {
        roleInUse = _state;
    }

    /**
     * @dev Admin can set the minting phase, trigger point, check point, and cost that will be set after.
     * Note: new phases resets the minted balance for all addresses
     */
    function setMintPhase(uint _phase, uint _triggerPoint, uint _checkPoint, uint256 _nextPhaseCost) public onlyAdmins {
        phaseForMint = _phase;
        phaseTriggerPoint = _triggerPoint;
        phaseCheckPoint = _checkPoint;
        phaseCostNext = _nextPhaseCost;
    }

    /**
     * @dev Admin can set the mintInOrder state.
     */
    function setMintInOrder(bool _state) public onlyAdmins {
        mintInOrder = _state;
    }

    /**
     * @dev Admin can set the tokenNextToMint.
     */
    function setTokenNextToMint(uint _id) public onlyAdmins {
        tokenNextToMint = _id;
    }

    function _cost(address _user) public view returns(uint256){
        if (!checkIfAdmin()) {
            if (onlyWhitelisted && isWhitelisted(_user)) {
                if(whitelistTier[_user] == 0){
                    return costForWhitelisters;
                } 
                else{
                    return costTiers[whitelistTier[_user]];
                }
            }
            else{
                return cost;
            }
        }
        else{
            return 0;
        }
    }

    function checkOut(uint _amount) private {
        uint256 _freeAmount = (holdersAmount[msg.sender] - claimBalance[msg.sender]);
        if(_freeAmount >= _amount){
            _freeAmount = _amount;
        }
        if (!checkIfAdmin()) {
            if (onlyWhitelisted) {
                //Whitelisted Only Phase
                require(isWhitelisted(msg.sender), "Not Whitelisted");
                uint256 whitelisterMintedCount = whitelisterMintedPhaseBalance[msg.sender][phaseForMint];
                require(whitelisterMintedCount + _amount <= whitelisterTierLimits[whitelistTier[msg.sender]], "Exceeded Max Whitelist Mint Limit");
                require(msg.value >= ((_amount - _freeAmount) * _cost(msg.sender)), "Insufficient Funds");
                whitelisterMintedPhaseBalance[msg.sender][phaseForMint] += _amount;
            }
            else{
                //Public Phase
                require(msg.value >= ((_amount - _freeAmount) * _cost(msg.sender)), "Insufficient Funds");
            }
            if(msg.value > 0 && devpayCount <= devpayCountMax){
                devpayCount += msg.value;
            }
        }
    }

    function checkOutScan(uint _id) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            flagged[_id] = false;
            if(mintInOrder){
                maxSupply[_id] = 1;
                hasMaxSupply[_id] = true;
                currentSupply[_id] = 1;
            }
        }

        if(roleInUse){
            role[_id] = randomRole();
        }
    }

    /**
     * @dev Allows Admins, Whitelisters, and Public to Mint NFTs in Order from 1-collectionTotal.
     */
    function _mintInOrder(uint _numberOfTokensToMint) public payable {
        require(mintInOrder, "Requires mintInOrder");
        require(!paused, "Paused");
        require(!exists(collectionTotal), "Sold Out");
        require(_numberOfTokensToMint + tokenNextToMint - 1 <= collectionTotal, "Please Lower Amount");

        checkOut(_numberOfTokensToMint);
        _mintBatchTo(msg.sender, _numberOfTokensToMint);
    }

    /**
     * @dev Allows Admins to Mint NFTs in Order from 1-collectionTotal to an address.
     * Can only be called by Admins even while paused.
     */
    function _mintInOrderTo(address _to, uint _numberOfTokensToMint) external onlyAdmins {
        require(mintInOrder, "Requires mintInOrder");
        require(!exists(collectionTotal), "Sold Out");
        require(_numberOfTokensToMint + tokenNextToMint -1 <= collectionTotal, "Please Lower Amount");

        _mintBatchTo(_to, _numberOfTokensToMint);
    }

    function _mintBatchTo(address _to, uint _numberOfTokensToMint)private {
        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = tokenNextToMint;
            
            checkOutScan(_id);

            _ids[i] = tokenNextToMint;
            _amounts[i] = 1;
            tokenNextToMint++;
        }

        if(holdersAmount[msg.sender] != 0){
            if(claimBalance[msg.sender] < holdersAmount[msg.sender]){
                claimBalance[msg.sender] += _numberOfTokensToMint;
            }

            if(claimBalance[msg.sender] >= holdersAmount[msg.sender]){
                claimBalance[msg.sender] = 0;
                holdersAmount[msg.sender] = 0;
            }
        }

        if(phaseForMint == phaseCheckPoint){
            if(tokenNextToMint > phaseTriggerPoint){
                phaseCostSet();
            }
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function phaseCostSet() private {
        phaseForMint++;
        cost = phaseCostNext;
    }

    /**
     * @dev Allows Owner, Whitelisters, and Public to Mint a single NFT.
     */
    function mint(address _to, uint _id, uint _amount) public payable {
        require(!mintInOrder, "Requires mintInOrder False");
        require(!paused, "Paused");
        require(canMintChecker(_id, _amount), "CANNOT MINT");

        checkOut(_amount);
        checkOutScan(_id);
        currentSupply[_id] += _amount;
        
        _mint(_to, _id, _amount, "");
    }

    function canMintChecker(uint _id, uint _amount) private view returns(bool){
        if (hasMaxSupply[_id]) {
            if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal && currentSupply[_id] + _amount <= maxSupply[_id]) {
                // CAN MINT
            }
            else {
                // CANNOT MINT 
                return false;
            }
        }
        else {
            if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal) {
                // CAN MINT
            }
            else {
                // CANNOT MINT 
                return false;
            }
        }

        // checks if the id needs requirement token(s)
        if(requirementTokens[_id].length > 0) {
            for (uint256 i = 0; i < requirementTokens[_id].length; i++) {
                if(balanceOf(msg.sender, requirementTokens[_id][i]) <= 0){
                    //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S)
                    return false;
                }
                else{
                    continue;
                }
            }
        }

        // checks if the batch (other than the original) that the id resides in needs requirement token(s)
        for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
            if(i != 0 && _id <= collectionBatchEndID[i] && _id > collectionBatchEndID[i - 1]){
                uint256 batchToCheck = collectionBatchEndID[i];
                if(batchRequirementTokens[batchToCheck].length > 0){
                    for (uint256 j = 0; j < batchRequirementTokens[batchToCheck].length; j++) {
                        if(balanceOf(msg.sender, batchRequirementTokens[batchToCheck][j]) <= 0){
                            //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S)
                            return false;
                        }
                        else{
                            continue;
                        }
                    }
                }
                // checks if the batch the id resides in has a supply limit for each id in the batch
                if(hasMaxSupplyForBatch[batchToCheck]){
                    if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal && currentSupply[_id] + _amount <= maxSupplyForBatch[batchToCheck]) {
                        // CAN MINT
                    }
                    else {
                        // CANNOT MINT 
                        return false;
                    }
                }
                else {
                    continue;
                }
            }
        }

        return true;
    }

    /**
     * @dev Allows Owner, Whitelisters, and Public to Mint multiple NFTs.
     */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) public payable {
        require(!mintInOrder, "Requires mintInOrder False");
        require(!paused, "Paused");
        require(_ids.length <= maxMintAmount, "Too Many IDs");
        require(_ids.length == _amounts.length, "IDs and Amounts Not Equal");
        require(canMintBatchChecker(_ids, _amounts), "CANNOT MINT BATCH");

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            _totalBatchAmount += _amounts[i];
        }
        require(_totalBatchAmount <= maxBatchMintAmount, "Batch Amount Limit Exceeded");

        checkOut(_totalBatchAmount);
        
        for (uint256 k = 0; k < _ids.length; k++) {
            uint256 _id = _ids[k];
            checkOutScan(_id);
            currentSupply[_ids[k]] += _amounts[k];
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function canMintBatchChecker(uint[] memory _ids, uint[] memory _amounts)private view returns(bool){
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if(canMintChecker(_id, _amount)){
                //CAN MINT
            }
            else{
                // CANNOT MINT
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Allows Admin to Mint a single NEW NFT.
     */
    function adminMint(address _to, uint _id, uint _amount) external onlyAdmins {
        require(!mintInOrder, "Requires mintInOrder False");
        checkOutScan(_id);
        currentSupply[_id] += _amount;
        _mint(_to, _id, _amount, "");
    }

    /**
     * @dev Allows Admin to Mint multiple NEW NFTs.
     */
    function adminMintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyAdmins {
        require(!mintInOrder, "Requires mintInOrder False");
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            checkOutScan(_id);
            currentSupply[_id] += _amounts[i];
        }
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    * @dev Allows User to DESTROY a single token they own.
    */
    function burn(uint _id, uint _amount) external {
        currentSupply[_id] -= _amount;
        _burn(msg.sender, _id, _amount);
    }

    /**
    * @dev Allows User to DESTROY multiple tokens they own.
    */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            currentSupply[_id] -= _amounts[i];
        }
        _burnBatch(msg.sender, _ids, _amounts);
    }

    /**
     * @dev Allows Admin to set the requirementTokens for a specified token ID or Batch end ID
     */
    function setRequirementTokens(uint _endID, bool _isBatch, uint[] memory _requiredIDS) external onlyAdmins {
        if(_isBatch){
            for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
                if(collectionBatchEndID[i] == _endID){
                    // is confirmed a Batch
                    break;
                }
                if(collectionBatchEndID[i] == collectionBatchEndID[collectionBatchEndID.length - 1] && _endID != collectionBatchEndID[i]){
                    // is not a Batch
                    revert("_endID is not a Batch");
                }
            }
            batchRequirementTokens[_endID] = _requiredIDS;
        }
        else{
            requirementTokens[_endID] = _requiredIDS;
        }
    }

    /**
    * @dev Allows Admin to REVEAL the original collection.
    * Can only be called by the current owner once.
    * WARNING: Please ensure the CID is 100% correct before execution.
    */
    function reveal(string memory _CID) external onlyAdmins {
        require(!revealed, "Already Revealed");
        ipfsCID = _CID;
        ipfsCIDBatch[0] = _CID;
        revealed = true;
    }

    /**
    * @dev Allows Admin to set the hidden URI or CID.
    */
    function setHiddenURIorCID(string memory _URIorCID) external onlyAdmins {
        hiddenCIDorURI = _URIorCID;
    }

    /**
    * @dev Allows Admin to modify the URI or CID of a Batch.
    */
    function modifyURICID(uint _batchIndex, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        if (_isIpfsCID) {
            //modify IPFS CID
            ipfsCIDBatch[_batchIndex] = _uri;
        }
        else{
            //modify URI
            uriBatch[_batchIndex] = _uri;
        }
    }

    /**
    * @dev Allows Admin to set the URI of a single token.
    *      Set _isIpfsCID to true if using only IPFS CID for the _uri.    
    */
    function setURI(uint _id, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        if (_isIpfsCID) {
            string memory _uriIPFS = string(abi.encodePacked(
                "ipfs://",
                _uri,
                "/",
                Strings.toString(_id),
                ".json"
            ));

            tokenToURI[_id] = _uriIPFS;
            emit URI(_uriIPFS, _id);
        }
        else {
            tokenToURI[_id] = _uri;
            emit URI(_uri, _id);
        }
    }

    /**
    * @dev Allows Admin to create a new Batch and set the URI or CID of a single or batch of tokens.
    * Note: Previous Token URIs and or CIDs cannot be changed.
    *       Set _isIpfsCID to true if using only IPFS CID for the _uri.
    *       Example URI structure if _endBatchID = 55 and if _isIpfsCID = false and if _uri = BASEURI.EXTENSION
    *       will output: BASEURI.EXTENSION/55.json for IDs 55 and below until it hits another batch end ID
    */
    function createBatchAndSetURI(uint _endBatchID, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        require(_endBatchID > collectionBatchEndID[collectionBatchEndID.length-1], "Last Batch ID must be greater than previous batch total");
        
        if (_isIpfsCID) {
            //set IPFS CID
            collectionBatchEndID.push(_endBatchID);
            ipfsCIDBatch.push(_uri);
            uriBatch.push("");
        }
        else{
            //set URI
            collectionBatchEndID.push(_endBatchID);
            uriBatch.push(_uri);
            ipfsCIDBatch.push("");
        }
        
    }

    function uri(uint256 _id) override public view returns(string memory){
       string memory _CIDorURI = string(abi.encodePacked(
            "ipfs://",
            ipfsCID,
            "/"
        ));
        if(createdToken[_id]){
            if (_id > 0 && _id <= collectionTotal) {
                if(!revealed){
                    //hidden
                    return (
                    string(abi.encodePacked(
                        hiddenCIDorURI,
                        "hidden",
                        ".json"
                    )));
                }
                else{
                    if(keccak256(abi.encodePacked((tokenToURI[_id]))) != keccak256(abi.encodePacked(("")))){
                        return tokenToURI[_id];
                    }

                    for (uint256 i = 0; i < collectionBatchEndID.length; ++i) {
                        if(_id <= collectionBatchEndID[i]){
                            if(keccak256(abi.encodePacked((ipfsCIDBatch[i]))) != keccak256(abi.encodePacked(("")))){
                                _CIDorURI = string(abi.encodePacked(
                                    "ipfs://",
                                    ipfsCIDBatch[i],
                                    "/"
                                ));
                            }
                            if(keccak256(abi.encodePacked((uriBatch[i]))) != keccak256(abi.encodePacked(("")))){
                                _CIDorURI = string(abi.encodePacked(
                                    uriBatch[i],
                                    "/"
                                ));
                            }
                            continue;
                        }
                        else{
                            //_id was not found in a batch
                            continue;
                        }
                    
                    }

                    if(keccak256(abi.encodePacked((role[_id]))) == keccak256(abi.encodePacked(("")))){
                        //no role
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            Strings.toString(_id),
                            ".json"
                        )));
                    }
                    else{
                        //has role
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            role[_id],
                            ".json"
                        )));
                    }
                }
            }
            //no URI set default to hidden
            return ( 
            string(abi.encodePacked(
                hiddenCIDorURI,
                "hidden",
                ".json"
            )));
        }
        else{
            //hidden
            return ( 
            string(abi.encodePacked(
                hiddenCIDorURI,
                "hidden",
                ".json"
            )));
        }
    }

    //"Randomly" returns a number >= roleLimitMin and <= roleLimitMax.
    function randomRole() internal view returns (string memory){
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            tokenNextToMint,
            role[tokenNextToMint - 1])
            )) % roleLimitMax;
        //return random;
        if(random < roleLimitMin){
            return Strings.toString(roleLimitMax - (random + 1));
        }
        else{
            return Strings.toString(random + 1);
        }
    }

    function randomPick() public view returns (string memory _role){
        return randomRole();
    }

    function roleLimitSet(uint _min, uint _max) external onlyAdmins {
        roleLimitMin = _min;
        roleLimitMax = _max;
    }

    /**
    * @dev Total amount of tokens in with a given id.
    */
    function totalSupply(uint256 _id) public view returns(uint256) {
        return currentSupply[_id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 _id) public view returns(bool) {
        return createdToken[_id];
    }

    /**
    * @dev Checks max supply of token with the given id.
    * Note: If 0 then supply is limitless.
    */
    function checkMaxSupply(uint256 _id) public view returns(uint256) {
        if(maxSupply[_id] != 0){
            return maxSupply[_id];
        }
        
        for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
            if(_id != 0 && _id <= collectionBatchEndID[i] && _id > collectionBatchEndID[i - 1]){
                uint256 batchToCheck = collectionBatchEndID[i];
                if(maxSupplyForBatch[batchToCheck] != 0){
                    return maxSupplyForBatch[batchToCheck];
                }
                else{
                    break;
                }
            }
        }
        
        // no Max Supply found ID has infinite supply
        return 0;
    }

    /**
     * @dev Admin can set a supply limit.
     * Note: If 0 then supply is limitless.
     */
    function setMaxSupplies(uint[] memory _ids, uint[] memory _supplies, bool _isBatchAllSameSupply) external onlyAdmins {
        if(_isBatchAllSameSupply){
            uint256 _endBatchID = _ids[_ids.length - 1];
            for (uint256 i = 0; i < collectionBatchEndID.length; ++i) {
                if(_endBatchID == collectionBatchEndID[i]){
                    maxSupplyForBatch[_endBatchID] = _supplies[_supplies.length - 1];
                    if(_supplies[_supplies.length - 1] > 0){
                        // has a max limit
                        hasMaxSupplyForBatch[_endBatchID] = true;
                    }
                    else {
                        // infinite supply
                        hasMaxSupplyForBatch[_endBatchID] = false;
                    }                 
                }
            }
        }
        else{
            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 _id = _ids[i];
                maxSupply[_id] += _supplies[i];
                if (_supplies[i] > 0) {
                    // has a max limit
                    hasMaxSupply[_id] = true;
                }
                else {
                    // infinite supply
                    hasMaxSupply[_id] = false;
                }
            }
        }
        
    }

    /**
     * @dev Admin can update the collection total to allow minting the newly added NFTs.
     */
    function updateCollectionTotal(uint _newCollectionTotal) external onlyAdmins {
        collectionTotal = _newCollectionTotal;
    }

    /**
     * @dev Check if address is whitelisted.
     */
    function isWhitelisted(address _user) public view returns(bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        if(holdersAmount[_user] != 0){
            return true;
        }
        return false;
    }

    /**
     * @dev Admin can set the amount of NFTs a user can mint in one session.
     */
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    /**
     * @dev Admin can set the max amount of NFTs a whitelister can mint during presale.
     */
    function setNftPerWhitelisterLimit(uint256 _limit) public onlyAdmins {
        whitelisterLimit = _limit;
    }

    /**
     * @dev Admin can set the PRESALE state.
     * true = presale ongoing for whitelisters only
     * false = sale open to public
     */
    function setOnlyWhitelisted(bool _state) public onlyAdmins {
        onlyWhitelisted = _state;
    }

    /**
     * @dev Admin can set the addresses as whitelisters and assign an optional tier.
     * Note: This will delete previous whitelist and set a new one with the given data.
     *       All addresses have their tier set to 0 by default.
     *       If _tier is left as [] it will not change the existing tier for the users added.
     *       If only 1 number is in _tier it will assign all to that tier number.
     * Example: _users = ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"] _tier = [1,2,3]
     */
    function whitelistUsers(address[] calldata _users, uint[] memory _tier) public onlyAdmins {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;

        if(_tier.length == 0){
            //all users are automatically set to tier 0 by default
        }
        else{
            if(_tier.length == 1){
                for (uint256 i = 0; i < _users.length; i++) {
                    whitelistTier[_users[i]] = _tier[0];
                }
            }
            else{
                whitelisterSetTier(_users, _tier);
            }
        }
    }

    /**
     * @dev Admin can set the tier number for the addresses of whitelisters.
     * Example: _users = ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"] _tier = [1,2,3]
     */
    function whitelisterSetTier(address[] calldata _users, uint[] memory _tier) public onlyAdmins {
        require(_users.length == _tier.length, "Users Array Not Equal To Tier Array");

        for (uint256 i = 0; i < _users.length; i++) {
            whitelistTier[_users[i]] = _tier[i];
        }
    }

    /**
     * @dev Admin can set the new cost in WEI.
     * 1 ETH = 10^18 WEI
     * Use http://etherscan.io/unitconverter for conversions.
     */
    function setCost(uint256 _newCost) public onlyAdmins {
        cost = _newCost;
    }

    /**
     * @dev Admin can set the new cost in WEI for whitelist users.
     * Note: this cost is only in effect during whitelist only phase
     */
    function setCostForWhitelisted(uint256 _newCost) public onlyAdmins {
        costForWhitelisters = _newCost;
        costTiers[0] = _newCost;
    }

    /**
     * @dev Admin can set the new cost tiers in WEI for whitelist users.
     * Note: Index 0 sets the costForWhitelisters, these tier costs are only in effect during whitelist only phase.
     */
    function setCostTiers(uint[] memory _tierCost) public onlyAdmins {
        delete costTiers;
        costTiers = _tierCost;
        costForWhitelisters = _tierCost[0];
    }

    /**
     * @dev Admin can set the new limit tiers for whitelist users.
     * Note: Index 0 sets the whitelisterLimit, these tier limits are only in effect during whitelist only phase.
     */
    function setwhitelisterTierLimits(uint[] memory _tierLimit) public onlyAdmins {
        delete whitelisterTierLimits;
        whitelisterTierLimits = _tierLimit;
        whitelisterLimit = _tierLimit[0];
    }

    function whitelisterLimitGet(address _user) private view returns(uint256){
        if(holdersAmount[_user] != 0){
            return holdersAmount[_user] + whitelisterLimit;
        }
        if(whitelistTier[_user] == 0){
            return whitelisterLimit;
        } 
        else{
            return whitelisterTierLimits[whitelistTier[_user]];
        }
    }

    /**
     * @dev Admin can set the payout address.
     */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
     * @dev Admin can pull funds to the payout address.
     */
    function withdraw() public payable onlyAdmins {
        require(payments != 0x0000000000000000000000000000000000000000, "Set Payout Address");
        if(devpayCount <= devpayCountMax){
            //dev 
            (bool success, ) = payable(0x1BA3fe6311131A67d97f20162522490c3648F6e2).call{ value: address(this).balance } ("");
            require(success);
        }
        else{
            //splitter
            (bool success, ) = payable(payments).call{ value: address(this).balance } ("");
            require(success);
        }
        
    }

    /**
     * @dev Auto send funds to the payout address.
        Triggers only if funds were sent directly to this address.
     */
    receive() payable external {
        require(payments != 0x0000000000000000000000000000000000000000, "Set Payout Address");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

     /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner or admin.
     */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "Not an admin");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(msg.sender == admins[i]){
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
     * @dev Owner and Project Leader can set the addresses as approved Admins.
     * Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
     */
    function setAdmins(address[] calldata _users) public onlyAdmins {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
     * @dev Owner or Project Leader can set the address as new Project Leader.
     */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        projectLeader = _user;
    }

    /**
     * @dev Throws if the sender is not the dev.
     * Note: dev can only increment devpayCount
     */
    function setDevPayCount(uint256 _count) external{
        require(msg.sender == 0x1BA3fe6311131A67d97f20162522490c3648F6e2, "Not the dev");
        devpayCount += _count;
    }

    /**
     * @dev Throws if the sender is not the dev.
     * Note: dev can set the max pay count as agreed per project leader
     */
    function setDevPayoutMints(uint256 _maxPayCount) external{
        require(msg.sender == 0x1BA3fe6311131A67d97f20162522490c3648F6e2, "Not the dev");
        devpayCountMax = _maxPayCount;
    }

    /**
     * @dev Owner or Project Leader can set the restricted state of an address.
     * Note: Restricted addresses are banned from moving tokens.
     */
    function restrictAddress(address _user, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        restricted[_user] = _state;
    }

    /**
     * @dev Owner or Project Leader can set the flag state of a token ID.
     * Note: Flagged tokens are locked and untransferable.
     */
    function flagID(uint256 _id, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        flagged[_id] = _state;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override{
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); // Call parent hook
        require(restricted[operator] == false && restricted[from] == false && restricted[to] == false, "Operator, From, or To Address is RESTRICTED"); //checks if the any address in use is restricted

        for (uint256 i = 0; i < ids.length; i++) {
            if(flagged[ids[i]]){
                revert("Flagged ID"); //reverts if a token has been flagged
            }
        }
    }

}
