// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./MonsterBudHolders.sol";
import "./IMonsterBudsV2.sol";
import "./StringsUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";


/**
 * @dev Implementation of the {IMonsterBuds} interface.
 */

contract MonsterbudsV2 is MonsterBudHolders, ERC721URIStorageUpgradeable, IMonsterBudsV2{
    using StringsUpgradeable for uint256;
    
    // token count
    uint256 public tokenCounter;

    // percentage denominator
    uint private percentDeno;

    // percent of fees
    uint private feeMargin;
    
    // new Item count
    uint256 private newItemId;

    // SKT Wallet address
    address private feeSKTWallet;

    // smartcontract community address
    address private SmartContractCommunity;

    // array of token ids
    uint256[] private tokenIds;

    // array of token URI's
    string[] private tokenUris;

    // token price
    uint private tokenValue;

    // breed price
    uint private breedValue; 

    // token URI
    string private beforeUri;

    string private afterUri;

    // status where buy should be allowed or not
    bool private buyONorOFFstatus;

    // status where self breed should be allowed or not
    bool private selfBreedStatus;

    // status where hybrid should be allowed or not
    bool private hybridStatus;
    
    // stores the details of token breeding
    struct breedInfomation{
        uint256 tokenId;
        uint breedCount;
        uint256 timstamp;
    }

    // mapping of token Id with Breeding Information
    mapping (uint256 => breedInfomation) public breedingInfo;

    // mapping of ppp tokeen id with their minting status
    mapping(uint256 => bool) public pppMintStatus;

    // stucture for purchase
    struct Order{
        address buyer;
        address owner; 
        uint256 token_id;
        string tokenUri;
        uint256 expiryTimestamp;
        uint256 price;
        bytes32 signKey;  // buyHash
        bytes32 signature; // messageHash
    }

    // structure for breed
    struct SelfBreed{
        uint256 req_token_id;
        uint256 accept_token_id;
        bytes32 signKey;
    }

    // 2nd structure for purchase
    struct PurchaseOrder{
        uint256 token_id;
        uint256 expiryTimestamp;
        uint256 price;
        bytes32 signKey;
        bytes32 signature;
    }

    // PFP ETH value
    uint256 private pfpValue;

    // packwood ERC 721 address
    address public packwoodERC721;


    // modifier
    modifier onlyPackwood721(){
        require(msg.sender == packwoodERC721, "$MONSTERBUDS: You are not authorised");
        _;
    }

    // functions Sections

    function updatePackwoodERC721(address nextOwner) external onlyOwner returns (address){
        require(nextOwner != address(0x00), "$MONSTERBUDS: cannot be zero address");
        packwoodERC721 = nextOwner; // update commuinty wallet
        return packwoodERC721;
    }

    /**
     * @dev calculates the 5 percent fees
    */

    function feeCalulation(uint256 _totalPrice) private view returns (uint256) {
        uint256 fee = feeMargin * _totalPrice;
        uint256 fees = fee / percentDeno;
        return fees;
    }

    /**
     * @dev sets the status of Buy Tokens function.
    */

    function updateBuyStatus(bool _status) external onlyOwner returns (bool){
        buyONorOFFstatus = _status;
        return buyONorOFFstatus;
    }

    /**
     * @dev sets the value of pfp Tokens function.
    */

    function updatePfpValue(uint256 _value) external onlyOwner returns (bool){
        pfpValue = _value;
        return true;
    }

    /**
     * @dev sets the status of self breed Tokens function.
    */

    function updateSelfBreedStatus(bool _status) external onlyOwner returns (bool){
        selfBreedStatus = _status;
        return selfBreedStatus;
    }

    /**
     * @dev sets the status of hybrid Tokens function.
    */

    function updateHybridStatus(bool _status) external onlyOwner returns (bool){
        hybridStatus = _status;
        return hybridStatus;
    }

    /**
     * @dev concates the two string and token id to create new URI. 
          *
     * @param _before token uri before part.
     * @param _after token uri after part.
     * @param _token_id token Id.
     *
     * Returns
     * - token uri
    */

    function uriConcate(string memory _before, uint256 _token_id, string memory _after) private pure returns (string memory){
        string memory token_uri = string( abi.encodePacked(_before, _token_id.toString(), _after));
        return token_uri;
    }

    /**
     * @dev updates the token price(in ETH)
     *  
     * @param _ethValue updated ETH price of token minting.
     *
     * Requirements:
     * - `_ethValue` must be pass.
     * - only owner can update value.
    */

    function updateTokenMintRate(uint256 _ethValue) external onlyOwner returns (uint256){
        tokenValue = _ethValue; // update the eth value of token
        return tokenValue;
    }

    /**
     * @dev updates the percent denominator. 
     * For the fee margin in points the denominator should be increased
     *  
     * @param _no denominator(100, 1000, 10000)
     * Requirements:
     * - only owner can update value.
    */

    function updatepercentDenominator(uint256 _no) external onlyOwner returns (uint256){
        percentDeno = _no; // update the eth value of token
        return percentDeno;
    }

    /**
     * @dev updates the token URI. 
     *
     * @param tokenId token Id.
     * @param token_uri token uri.
     *
     * Requirements:
     * - only owner can update ant token URI.
    */

    function updateTokenUri(uint256 tokenId, string memory token_uri) external onlyOwner returns (bool){
        _setTokenURI(tokenId, token_uri); // update the uri of token
        return true;
    } 

    /**
     * @dev updates the breed price(in ETH). 
     *
     * @param _ethValue updated ETH price of breeding.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updateBreedValue(uint256 _ethValue) external onlyOwner returns (uint256){
        breedValue = _ethValue; // update the eth value of breed value
        return breedValue;
    }

    /**
     * @dev updates the default Token URI. 
     *
     * @param _before token uri before part.
     * @param _after token uri after part.
     *
     * Requirements:
     * - only owner can update default URI.
    */

    function updateDefaultUri(string memory _before, string memory _after) external onlyOwner returns (bool){
        beforeUri = _before; // update the before uri for SKT
        afterUri = _after; // update the after uri for SKT
        return true;
    }

    /**
     * @dev updates the SKT Wallet Address. 
     * 
     * @param nextOwner updated SKT wallet address.
     *  
     * Requirements:
     * - only owner can update value.
     * - `nextOwner` cannot be zero address.
    */

    function updateFeeSKTWallet(address payable nextOwner) external onlyOwner returns (address){
        require(nextOwner != address(0x00), "$MONSTERBUDS: cannot be zero address");
        feeSKTWallet = nextOwner; // update the fee wallet for SKT
        return feeSKTWallet;
    }

    /**
     * @dev updates the SmartContract Community Wallet Address.
     * 
     * @param nextOwner updated smart contract community wallet address.
     *  
     * Requirements:
     * - only owner can update value.
     * - `nextOwner` must not be zero address.
    */

    function updateSKTCommunityWallet(address payable nextOwner) external onlyOwner returns (address){
        require(nextOwner != address(0x00), "$MONSTERBUDS: cannot be zero address");
        SmartContractCommunity = nextOwner; // update commuinty wallet
        return SmartContractCommunity;
    }

    /**
     * @dev updates the percent of fees. 
     * - `nextFeeMargin` must be pass.
     *  
     * Requirements:
     * - only owner can update value.
    */

    function updateFeeMargin(uint256 nextMargin) external onlyOwner returns (uint256){
        feeMargin = nextMargin; // update fee percent
        return feeMargin;
    }

    /**
     * @dev mints the ERC721 NFT tokens.
     *
     * @param quantity number of tokens that to be minted.
     *  
     * Requirements:
     * - `quantity` must be from 1 to 28.
     * - ETH amount must be quantity * token price.
     * 
     * Returns
     * - array of newly token counts.
     *
     * Emits a {TokenDetails} event.
    */

    function createCollectible(uint quantity) external payable override returns (uint256[] memory){

        uint256 totalAmount = (tokenValue * quantity); // total amount
        uint256 count = tokenCounter + (quantity-1);
        require(count <= 10420, "$MONSTERBUDS: Total supply has reached");
        require(quantity <= 28 && totalAmount == msg.value, "$MONSTERBUDS: Cannot mint more than max buds or price is incorrect");
        delete tokenIds; // delete the privious tokenIDs array
        delete tokenUris;
        string memory _uri;

        for (uint i = 0; i < quantity; i++) {
            // loop to mint no of seeds
            newItemId = tokenCounter;
            _uri = uriConcate(beforeUri, newItemId, afterUri);
            _safeMint(msg.sender, newItemId); // mint new seed
            _setTokenURI(newItemId, _uri); // set uri to new seed
            breedInfomation storage new_data = breedingInfo[newItemId];
            new_data.tokenId = newItemId;
            new_data.breedCount = 0;
            new_data.timstamp = block.timestamp + 4 days;
            tokenIds.push(newItemId);
            tokenUris.push(_uri);
            tokenCounter = tokenCounter + 1;
        }

        payable(owner()).transfer(msg.value); // transfer the ethers to smart contract owner

        emit TokenDetails(msg.sender, tokenUris, tokenIds, msg.value);

        return tokenIds;
    }

    /**
     * @dev user can create new ERC721 token by hybriding with another token.
     * 
     * @param req_token_id token Id of msg.sender.
     * @param accept_token_id token Id of accepter address.
     * @param breed_req_id request Id send by msg.sender to accepter.
     *
     * Returns
     * - new token count.
     *
     * Emits a {hybreed} event.
    */

    function hybreedCollectiable( uint256 req_token_id,uint256 accept_token_id, uint256 breed_req_id) external override payable returns (uint256) {
        address payable accepter_token_address = payable(ownerOf(accept_token_id));
        address owner_req = (ownerOf(req_token_id));

        require(hybridStatus == true, "$MONSTERBUDS: Breeding is closed");
        require(accepter_token_address != msg.sender && owner_req == msg.sender, "$MONSTERBUDS: can not hybrid");

        uint256 breedFee = breedValue * 2; // 0.008 Eth breed Value * 2
        require(breedFee == msg.value, "$MONSTERBUDS: Amount is incorrect");

        newItemId = tokenCounter;
        string memory seed_token_uri = uriConcate(beforeUri, newItemId, afterUri);

        _safeMint(msg.sender, newItemId); // mint child seed
        _setTokenURI(newItemId, seed_token_uri); // set token uri for child seed
        tokenCounter = tokenCounter + 1;

        accepter_token_address.transfer(breedValue); // send 0.008 to accepter address
        payable(feeSKTWallet).transfer(breedValue);
        // send 0.008 to skt fee wallet
        emit hybreed(
            msg.sender,
            accepter_token_address,
            req_token_id,
            accept_token_id,
            seed_token_uri,
            newItemId,
            breed_req_id,
            breedValue,
            breedValue
        );

        return newItemId;
    }

    /**
     * @dev user can create new ERC721 token by self breeding with owned two tokens.
     * 
     * @param breed struct for breeding info.
     * @param signature verify.
     *
     * Returns
     * - new token count.
     *
     * Emits a {breedSelf} event.
    */

    function selfBreedCollectiable(SelfBreed calldata breed, bytes calldata signature) external payable returns (uint256) {
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), breed.signKey, signature);
        require(status == true, "$MONSTERBUDS: cannot breed[ERROR]");
        
        require(selfBreedStatus == true, "$MONSTERBUDS: Breeding is closed");
        require(breed.req_token_id > 865 && breed.accept_token_id > 865, "$MONSTERBUDS: PPP Monsters cannot breed");  // 865 ppp users
        require(breedValue == msg.value, "$MONSTERBUDS: Amount is incorrect");

        address owner_req = (ownerOf(breed.req_token_id));
        address owner_accept = (ownerOf(breed.accept_token_id));

        require(owner_req == owner_accept && owner_req == msg.sender && breed.req_token_id != breed.accept_token_id, "$MONSTERBUDS: Cannot Self Breed");
        require(breedingInfo[breed.req_token_id].breedCount < 2 && breedingInfo[breed.accept_token_id].breedCount < 2, "$MONSTERBUDS: Exceeds max breed count");
        require(block.timestamp >= breedingInfo[breed.req_token_id].timstamp && block.timestamp >= breedingInfo[breed.accept_token_id].timstamp,"$MONSTERBUDS: You cannot breed now");
       

        newItemId = tokenCounter;
        string memory seed_token_uri = uriConcate(beforeUri, newItemId, afterUri);

        _safeMint(msg.sender, newItemId); // mint new child seed
        _setTokenURI(newItemId, seed_token_uri); // set child uri
        uint countOfReq = breedingInfo[breed.req_token_id].breedCount;
        uint countOfAccept = breedingInfo[breed.accept_token_id].breedCount;

        breedInfomation storage new_data = breedingInfo[newItemId];
        new_data.tokenId = newItemId;
        new_data.breedCount = 0;
        new_data.timstamp = block.timestamp + 4 days;

        tokenCounter = tokenCounter + 1;
        breedInfomation storage req_data = breedingInfo[breed.req_token_id];
        req_data.tokenId = breed.req_token_id;
        req_data.breedCount = countOfReq + 1;
        req_data.timstamp = block.timestamp + 1512000;

        breedInfomation storage accept_data = breedingInfo[breed.accept_token_id];
        accept_data.tokenId = breed.accept_token_id;
        accept_data.breedCount = countOfAccept + 1;
        accept_data.timstamp = block.timestamp + 1512000;
    

        payable(feeSKTWallet).transfer(msg.value); // send 0.008 to skt fee wallet

        emit breedSelf(
            msg.sender,
            breed.req_token_id,
            breed.accept_token_id,
            seed_token_uri,
            newItemId,
            msg.value
        );

        return newItemId;
    }
    
    // /**
    //  * @dev free mint for ppp users.
    //  *
    //  * Requirements
    //  * - user address must be ppp user.
    //  * - user address must not be zero address.
    //  *
    //  * Returns
    //  * - new token count.
    //  *
    //  * Emits a {FreeTokenDetails} event.
    // */

    // function freeMint() external override returns(uint256) {
    //     require(holders[msg.sender] == true, "$MONSTERBUDS: Not PPP User");
    //     string memory _uri;
    //     holders[msg.sender] = false;
    //     newItemId = tokenCounter;
    //     string memory before_ = "https://s3.amazonaws.com/assets.monsterbuds.io/Monster-Uri/PPP_Ticket_";
    //     string memory after_ = ".json";
    //     _uri = uriConcate(before_, newItemId, after_);
    //     _safeMint(msg.sender, newItemId); // mint new seed
    //     _setTokenURI(newItemId, _uri); // set uri to new seed
    //     tokenCounter = tokenCounter + 1;

    //     emit FreeTokenDetails(0, msg.sender, _uri, newItemId, false);

    //     return newItemId;
    // }

    /**
     * @dev user can create new ERC721 token by self breeding with owned two tokens.
     * 
     * @param _tokenId token Id of msg.sender.
     *
     * Returns
     * - new token count.
     *
     * Emits a {FreeTokenDetails} event.
    */

    function createPPPCollectiable(uint256 _tokenId) external returns (uint256){
        require(_tokenId <= 865 && ownerOf(_tokenId) == msg.sender ,"$MONSTERBUDS: Not a PPP token or owner of PPP token");
        require(pppMintStatus[_tokenId] == false, "$MONSTERBUDS: Token is already minted by selected PPP token ID");

        newItemId = tokenCounter;
        string memory token_uri = uriConcate(beforeUri, newItemId, afterUri);
        _safeMint(msg.sender, newItemId); // mint child seed
        _setTokenURI(newItemId, token_uri); // set token uri for child seed
        breedInfomation storage new_data = breedingInfo[newItemId];
        new_data.tokenId = newItemId;
        new_data.breedCount = 0;
        new_data.timstamp = block.timestamp + 4 days;

        tokenCounter = tokenCounter + 1;
        pppMintStatus[_tokenId] = true;

        emit FreeTokenDetails(_tokenId, msg.sender, token_uri, newItemId, true);
        return newItemId;

    }

    /**
     * @dev matches the price and order
     * 
     * @param order structure about token order details.
     *
     * Returns
     * - bool.
     *
     * Emits a {buyTransfer} event.
    */

    function orderCheck(Order memory order) private returns(bool){
        address payable owner = payable(ownerOf(order.token_id));
        bytes32 hashS = keccak256(abi.encodePacked(msg.sender));
        bytes32 hashR = keccak256(abi.encodePacked(owner));
        bytes32 hashT = keccak256(abi.encodePacked(order.price));
        bytes32 hashV = keccak256(abi.encodePacked(order.token_id));
        bytes32 hashP = keccak256(abi.encodePacked(order.expiryTimestamp));
        bytes32 sign  = keccak256(abi.encodePacked(hashV, hashP, hashT, hashR, hashS));

        require(order.expiryTimestamp >= block.timestamp, "MONSTERBUDS: expired time");
        require(sign == order.signKey, "$MONSTERBUDS: ERROR");
        require(order.price == msg.value, "MONSTERBUDS: Price is incorrect");

        uint256 feeAmount = feeCalulation(msg.value);
        payable(feeSKTWallet).transfer(feeAmount); // transfer 5% ethers of msg.value to skt fee wallet
        payable(SmartContractCommunity).transfer(feeAmount); // transfer 5% ethers of msg.value to commuinty

        uint256 remainAmount = msg.value - (feeAmount + feeAmount);
        payable(order.owner).transfer(remainAmount); // transfer remaining 90% ethers of msg.value to owner of token
        _transfer(order.owner, msg.sender, order.token_id); // transfer the ownership of token to buyer

        emit buyTransfer(order.owner, msg.sender, order.token_id, msg.value);
        return true;
    }

    /**
     * @dev user can purchase the token.
     * 
     * @param order structure about token order details.
     * @param signature signature to verify. 
     *
     * Returns
     * - bool.
    */

    function purchase(Order memory order, bytes memory signature) external payable returns(bool){

        require(buyONorOFFstatus == true, "$MONSTERBUDS: Marketplace for buying is closed");
        orderCheck(order);
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), order.signature, signature);
        require(status == true, "$MONSTERBUDS: cannot purchase the token");
        return true;
    }

    /**
     * @dev user can purchase the token.
     * 
     * @param token_id token Id.
     *
     * Returns
     * - bool.
     *
     * Emits a {PfpDetails} event.
    */

    function createPfpVersion(uint256 token_id) external payable returns(bool){
        require(msg.value == pfpValue, "$MONSTERBUDS: Price is incorrect");
        require(ownerOf(token_id) == msg.sender, "$MONSTERBUDS: You are not owner of token");

        payable(feeSKTWallet).transfer(msg.value); 

        emit PfpDetails(msg.sender, token_id, msg.value);
        return true;
    }

    /**
     * @dev breeding of Packwood ERC721 and monsterbuds ERC721 creates new token
     * 
     * @param monsterbudId token Id.
     * @param reciever mint new token to reciver address
     *
     * Returns
     * - bool.
     *
     * Emits a {PfpDetails} event.
    */

    function breedUpdation(uint256 monsterbudId, address reciever) external onlyPackwood721 returns(uint256){
        
        require(breedingInfo[monsterbudId].breedCount < 2, "$MONSTERBUDS: Exceeds max breed count");
        require(block.timestamp >= breedingInfo[monsterbudId].timstamp ,"$MONSTERBUDS: cannot breed now");

        newItemId = tokenCounter;
        string memory seed_token_uri = uriConcate(beforeUri, newItemId, afterUri);

        _safeMint(reciever, newItemId); // mint new child seed
        _setTokenURI(newItemId, seed_token_uri); // set child uri
        uint countOfReq = breedingInfo[monsterbudId].breedCount;

        breedInfomation storage new_data = breedingInfo[newItemId];
        new_data.tokenId = newItemId;
        new_data.breedCount = 0;
        new_data.timstamp = block.timestamp + 4 days;

        tokenCounter = tokenCounter + 1;
        breedInfomation storage req_data = breedingInfo[monsterbudId];
        req_data.tokenId = monsterbudId;
        req_data.breedCount = countOfReq + 1;
        req_data.timstamp = block.timestamp + 1512000;

        return newItemId;

    }
}
