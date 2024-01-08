// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./OpenDoors.sol";

contract DimensionDoors is ERC1155, Ownable {
    
    using SafeMath for uint256;
    
    event doorUnlocked(address indexed unlockedBy, uint256 openedDoorId);

    // Adress to the opened doors smart contract, needed to mint new tokens on that contract when a door unlock happens
    address immutable public openedDoorsAdress;
    
    // Contract name
    string constant private _name = "Dimension Doors";
    
    // Contract symbol
    string constant private _symbol = "DIMDOOR";
    
    // Base Ids for differentiating between classes
    uint256 constant KEY_S = 0;
    uint256 constant KEY_A = 1;
    uint256 constant KEY_B = 2;
    uint256 constant KEY_C = 3;
    uint256 constant DOOR_S = 4;
    uint256 constant DOOR_A = 6;
    uint256 constant DOOR_B = 9;
    uint256 constant DOOR_C = 13;
    
    // Doors will be released on a batch-basis spanned over time. So not all doors are mintable upon release
    // There will be 50 batches in total
    uint256 public constant MAX_BATCHES = 50;
    
    // Per batch, each door has a limited supply
    uint256 constant DOOR_S_BATCH_SUPPLY = 1;
    uint256 constant DOOR_A_BATCH_SUPPLY = 2;
    uint256 constant DOOR_B_BATCH_SUPPLY = 3;
    uint256 constant DOOR_C_BATCH_SUPPLY = 4;
    
    uint256 constant DOOR_TOTAL_BATCH_SUPPLY = DOOR_S_BATCH_SUPPLY + DOOR_A_BATCH_SUPPLY + DOOR_B_BATCH_SUPPLY + DOOR_C_BATCH_SUPPLY;
    
    /** Closed doors are of a limited supply, no S-class is the same as the other for example, while a C-class has 10 of the same
     * Do note that while closed doors have copies, open doors are all unique. If you open 2 of the same C-class doors, you will get 2 different outcomes.
     * This supply is on a per-door basis
     */ 
    uint256 constant DOOR_S_SUPPLY = 1;
    uint256 constant DOOR_A_SUPPLY = 2;
    uint256 constant DOOR_B_SUPPLY = 5;
    uint256 constant DOOR_C_SUPPLY = 10;
    
    // We have a total of 4 keys
    uint256 constant NUM_KEYS = 4;
    
    /** Keys have total supply, because keys of the same class are interchangeable
     * The keys supply equal the total amount of opened doors supply across all batches
     * Keys will be released with each batch, that way we avoid people having keys with no doors to use them on
     */
    uint256 public constant KEY_S_SUPPLY = DOOR_S_BATCH_SUPPLY * DOOR_S_SUPPLY * MAX_BATCHES; // 50
    uint256 public constant KEY_A_SUPPLY = DOOR_A_BATCH_SUPPLY * DOOR_A_SUPPLY * MAX_BATCHES; // 200
    uint256 public constant KEY_B_SUPPLY = DOOR_B_BATCH_SUPPLY * DOOR_B_SUPPLY * MAX_BATCHES; // 750
    uint256 public constant KEY_C_SUPPLY = DOOR_C_BATCH_SUPPLY * DOOR_C_SUPPLY * MAX_BATCHES; // 2000
    
    /**
     * There will be 2 sets of provenance hashes, 1 for keys + closed doors and 1 for opened doors.
     * Provenance hashes will be done per batch, so the first batch will have a provenance hash of the NFTs inside that batch,
     * The second will also have a provenance hash, and from there a master provenance hash will be made from those 2 hashes
     * This will repeat until we have a master provenance hash of of all batches combined.
     * All batch provenance hashes will be stored in a mapping
     * The master provenance hash will be updated before each batch drop
     * The first closed doors provenance hash batch will also contain the keys
     */
    mapping(uint256 => string) public CLOSEDDOORS_PROVENANCE_BATCH;
    
    // This is the master provenance hash for closed doors
    string public CLOSEDDOORS_PROVENANCE_MASTER = "";
    
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

    // Doors of different classes have different prices based on their rarity
    uint256 private priceDoorS = 500000000000000000; // 0.5 ETH
    uint256 private priceDoorA = 250000000000000000; // 0.25 ETH    
    uint256 private priceDoorB = 100000000000000000; // 0.1 ETH
    uint256 private priceDoorC = 50000000000000000; // 0.05 ETH
    
    // Key starting price is a fifth of the door price
    uint256 private priceKeyS = priceDoorS / 5 * 2; // 0.2 ETH
    uint256 private priceKeyA = priceDoorA / 5 * 2; // 0.1 ETH    
    uint256 private priceKeyB = priceDoorB / 5 * 2; // 0.04 ETH
    uint256 private priceKeyC = priceDoorC / 5 * 2; // 0.02 ETH
    
    // Bool to easily turn off sales when needed
    bool public isSaleActive = true;
    bool public isUnlockActive = false;
    
    // The current batch we're on, can't exceed the max batch, we start from 0 so this value can't be higher than MAX_BATCHES
    uint256 public currentBatch = 1;
    
    // Keeping track of all mints per tokenId
    mapping(uint256 => uint256) public tokenSupply;
        
    // Keeping track of all burns per tokenId
    mapping(uint256 => uint256) public burnedSupply;
    
    constructor(address _openedDoorsAdress) ERC1155("") {
        openedDoorsAdress = _openedDoorsAdress;
    }
    
    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }
    
    /**
     * Returns the URI of a token given its ID
     * @param _id ID of the token to query
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(_id < getCurrentBatchSupply(), "URI query for nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
    
    function baseURI() public view returns (string memory) {
        return super.uri(0);
    }

    function setClosedMasterProvenanceHash(string memory _provenanceHash) public onlyOwner {
        CLOSEDDOORS_PROVENANCE_MASTER = _provenanceHash;
    }
    
    function setClosedBatchProvenanceHash(uint256 _batchId, string memory _provenanceHash) public onlyOwner {
        require(_batchId < MAX_BATCHES + 1);
        CLOSEDDOORS_PROVENANCE_BATCH[_batchId] = _provenanceHash;
    }
    
    function setCurrentBatch(uint256 _batchId) public onlyOwner {
        require(_batchId < MAX_BATCHES + 1);
        currentBatch = _batchId;
    }
    
    function reserveTokens(address _to, uint256[] memory _tokenIds, uint256[] memory _counts) public onlyOwner {
        for(uint256 i = 0; i < _counts.length; i++) {
            require(_tokenIds[i] < getCurrentBatchSupply(), "Token not within current batch");
            require(tokenSupply[_tokenIds[i]] + burnedSupply[_tokenIds[i]] + _counts[i] < maxSupplyPerClass(_tokenIds[i]) + 1, "Token exceeds maximum supply");
            tokenSupply[_tokenIds[i]] = tokenSupply[_tokenIds[i]].add(_counts[i]);
            _mint(_to, _tokenIds[i], _counts[i], "");
        }
    }
    
    function mint(uint256[] memory _tokenIds, uint256[] memory _counts) public payable {
        require(isSaleActive, "Sale not active" );
        require(_tokenIds.length == _counts.length, "Array lengths don't match");
        require(_tokenIds.length > 0, "Order empty");
        
        uint256 orderCount = 0;
        uint256 price = 0;
        // Check if supply is within the order limits
        // Check if the price is right
        // Check if the ordered supply does not exceed the possible supply
        for(uint256 i = 0; i < _counts.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenId < getCurrentBatchSupply(), "Token not within current batch");
            
            uint256 count = _counts[i];
            require(tokenSupply[tokenId] + burnedSupply[tokenId] + count < maxSupplyPerClass(tokenId) + 1, "Token exceeds maximum supply");
            orderCount = orderCount.add(count);
            price = price.add(getPricePerClass(tokenId).mul(count));
        }
        require(orderCount < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens per purchase");
        require(price <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < _counts.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 count = _counts[i];
            tokenSupply[tokenId] = tokenSupply[tokenId].add(count);
            _mint(msg.sender, tokenId, count, "");
        }
    }
    
    function purchaseAndUnlock(uint256 _doorId, uint256 _keyId, uint256 _doorOption) external payable {
        require(isUnlockActive, "Unlocking not available");
        uint256[] memory tokens = new uint256[](2);
        tokens[0] = _doorId;
        tokens[1] = _keyId;
        
        uint256[] memory counts = new uint256[](2);
        counts[0] = 1;
        counts[1] = 1;
        
        mint(tokens, counts);
        _unlock(_doorId, _keyId, _doorOption);
    }
    
    /**
     * Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function burn(address _from, uint256 _id, uint256 _quantity) internal {
        _burn(_from, _id, _quantity);
        burnedSupply[_id] = burnedSupply[_id].add(_quantity);
        tokenSupply[_id] = tokenSupply[_id].sub(_quantity);
    }

    /**
     * Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     * @param _newURI New URI for all tokens
     */
    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }
    
    // Withdraw balance to owner
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    
    // Returns the amount of tokens available in the current and previous batches
    function getCurrentBatchSupply() internal view returns (uint256) {
        // Check if we're past the max tokens
        return (NUM_KEYS + currentBatch * DOOR_TOTAL_BATCH_SUPPLY);
    }
    
    /**
    * Returns the total quantity for every token ID
    */
    function totalSupply() external view returns (uint256[] memory) {
        uint256 batchSupply = getCurrentBatchSupply();
        uint256[] memory supply = new uint256[](batchSupply);
        for(uint256 i = 0; i < batchSupply; i++) {
            supply[i] = tokenSupply[i].add(burnedSupply[i]);
        }
        return supply;
    }
    
    /**
    * Returns an array of which consists of the quantities of each token the owner holds
    * @param _owner the adress of the owner to check
    */
    function tokensByOwner(address _owner) external view returns(uint256[] memory) {
        uint256 batchSupply = getCurrentBatchSupply();
        uint256[] memory count = new uint256[](batchSupply);
        
        for(uint256 i = 0; i < batchSupply; i++) {
            uint256 balance = balanceOf(_owner, i);
            if (balance > 0) {
                count[i] = balance;
            }
        }
        return count;
    }
    
    // Sale status for closed doors and keys
    function toggleSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }
    
    // Sale status for keys specifically, so we can do a presale without doors being unlocked too early
    function toggleUnlockStatus() external onlyOwner {
        isUnlockActive = !isUnlockActive;
    }
    
    /** Setting and getting price for each door and key class
     * @param _priceId An id for each type of key and door, starting from S, A, B, C for the keys, and then the same for doors, so the ids start at 0 and end at 7
     * @param _newPrice the new price for said id
     */
    function setPrice(uint256 _priceId, uint256 _newPrice) external onlyOwner {
        require(_priceId < 8, "id out of bounds");
        
        // Keys
        if (_priceId == 0) {
            priceKeyS = _newPrice;
        }
        else if (_priceId == 1) {
            priceKeyA = _newPrice;
        }
        else if (_priceId == 2) {
            priceKeyB = _newPrice;
        }
        else if (_priceId == 3) {
            priceKeyC = _newPrice;
        }
        // Doors
        else if (_priceId == 4) {
            priceDoorS = _newPrice;
        }
        else if (_priceId == 5) {
            priceDoorA = _newPrice;
        }
        else if (_priceId == 6) {
            priceDoorB = _newPrice;
        }
        else if (_priceId == 7) {
            priceDoorC = _newPrice;
        }
    }
    
    // Returns an array of 8 values, for each type of key and door, starting from S, A, B, C for the keys, and then the same for doors
    function getPrices() external view returns(uint256[8] memory) {
        return [priceKeyS, priceKeyA, priceKeyB, priceKeyC, priceDoorS, priceDoorA, priceDoorB, priceDoorC];
    }
    
    /**
     * Returns the max supply based on the tokenId given
     * @param _tokenId the tokenId to get the class and determine the supply of
     */
    function maxSupplyPerClass(uint256 _tokenId) internal view returns (uint256) {
        
        // For keys, limit the available keys to the current batch, so that not all keys can be minted at once
        if (_tokenId < KEY_S + 1) {
            return KEY_S_SUPPLY / MAX_BATCHES * currentBatch;
        }
        else if (_tokenId < KEY_A + 1) {
            return KEY_A_SUPPLY / MAX_BATCHES * currentBatch;
        }
        else if (_tokenId < KEY_B + 1) {
            return KEY_B_SUPPLY / MAX_BATCHES * currentBatch;
        }
        else if (_tokenId < KEY_C + 1) {
            return KEY_C_SUPPLY / MAX_BATCHES * currentBatch;
        } else {
            // Only keep the right digit because that's what differentiates the door classes
            uint256 testId = _tokenId.sub(4).mod(10).add(3);
            
            if (testId < DOOR_S) { // S-class 
                return DOOR_S_SUPPLY;
            }
            else if (testId < DOOR_A) { // A-class
                return DOOR_A_SUPPLY;
            }
            else if (testId < DOOR_B) { // B-class
                return DOOR_B_SUPPLY;
            } 
            else if (testId < DOOR_C) { // C-class
                return DOOR_C_SUPPLY;
            }
        }
        
        // If all that fails, no supply
        return 0;
    }
    
    /**
     * Returns the set price based on the tokenId given
     * @param _tokenId the tokenId to get the class and determine the price of
     */
    function getPricePerClass(uint256 _tokenId) internal view returns (uint256) {
        // Keys are first in the token order so check those first
        if (_tokenId < KEY_S + 1) { // S-class
            return priceKeyS;
        }
        else if (_tokenId < KEY_A + 1) { // A-class
            return priceKeyA;
        }
        else if (_tokenId < KEY_B + 1) { // B-class
            return priceKeyB;
        }
        else if (_tokenId < KEY_C + 1) { // C-class
            return priceKeyC;
        } else { // If we're not dealing with keys, we check the doors
            // Only keep the right digit because that's what differentiates the door classes
            uint256 testId = _tokenId.sub(4).mod(10).add(3);
            
            if (testId < DOOR_S) { // S-class 
                return priceDoorS;
            }
            else if (testId < DOOR_A) { // A-class
                return priceDoorA;
            }
            else if (testId < DOOR_B) { // B-class
                return priceDoorB;
            } 
            else if (testId < DOOR_C) { // C-class
                return priceDoorC;
            }
        }
        
        return 0;
    }
    
    /**
     * Get the opened door ID based on the closed door id, key id and door option
     * The door option determines which of that specific closed door will be unlocked
     * Also checks if the option is for the right key.
     * Each class has a formula to determine the token id for the opened doors
     * @param _closedDoorId the token id of the door
     * @param _keyId the token id of the key, key id is always 0-3
     * @param _doorOption the unique option for the closed door, the max options is based on the uniqueness of the closed door
     */
    function getOpenedDoorId(uint256 _closedDoorId, uint256 _keyId, uint256 _doorOption) public pure returns (uint256) {
        // No need to remove key ids because functions have taken that into account already
        if (_keyId == 0 && _doorOption < DOOR_S_SUPPLY) { // S-class, 1 option 
            return ((_closedDoorId - 4) * 6);
        }

        if (_keyId == 1 && _doorOption < DOOR_A_SUPPLY) { // A-class, 2 options
            uint256 mod = _closedDoorId.mod(10);   
            return (mod * 2 - 9 + (_closedDoorId - mod) * 6).add(_doorOption);
        }
        
        if (_keyId == 2 && _doorOption < DOOR_B_SUPPLY) { // B-class, 5 options
            uint256 mod = _closedDoorId.mod(10);   
            return ((mod - 6) * 5 + (_closedDoorId - mod) * 6).add(_doorOption);
        }
        
        if (_keyId == 3 && _doorOption < DOOR_C_SUPPLY) { // C-class, 10 options
            uint256 mod = _closedDoorId.mod(10);   
            return (20 + mod * 10 + (_closedDoorId - mod - 10) * 6).add(_doorOption);
        }
        
        require(false, "Invalid door id");
        // This usually would not trigger
        return 0;
    }
    
    /**
     * Checks if the key is for the right door. It does this by determining the class of both.
     * The class is determined by first subtracting the amount of keys from the door id,
     * then using % 10 you get the most right digit. This digit relies heavily on minting order in batches of 10:
     * 0 = S-class, 1-2 = A-class, 3-5 = B-cass, 6-9 = C-class
     * For the key id, we have:
     * 0 = S-class, 1 = A-class, 2 = B-class, 3 = C-class
     * @param _doorId the token id of the door
     * @param _keyId the token id of the key, key id is always 0-3
     */
    function doesDoorKeyMatch(uint256 _doorId, uint256 _keyId) internal pure returns (bool matches) {
        if (_doorId < 4 || _keyId > 3) { // Make sure ids are in range
            return false;
        }
        
        // Subtract 4 from doorId to get rid of the keyIds and do a mod of 10 to get the most right digit
        uint256 testId = _doorId.sub(4).mod(10);

        if (testId < 1) { // S-class 
            return (_keyId == 0);
        }
        
        if (testId < 3) { // A-class
            return (_keyId == 1); 
        }
        
        if (testId < 6) { // B-class
            return (_keyId == 2);
        }
        
        if (testId < 10) { // C-class
            return (_keyId == 3);
        }
        
        // This should never trigger, but if it does and returns false, the unlock function simply fails.
        return false;
    }

    /**
     * Mints a specific door with a door/key-pair and an option id, then burns the closed door and key tokens
     * @param _doorId the token id of the door
     * @param _keyId the token id of the key, key id is always 0-3
     * @param _doorOption the option ID of the specific door, this is how a specific variant of the less-rare doors is determined
     */
    function unlock(uint256 _doorId, uint256 _keyId, uint256 _doorOption) external {
        require(isUnlockActive, "Unlocking not available");
        _unlock(_doorId, _keyId, _doorOption);
    }
    
    function unlockMultiple(uint256[] memory _doorIds, uint256[] memory _keyIds, uint256[] memory _doorOptions) external {
        require(isUnlockActive, "Unlocking not available");
        uint256 doorIds_length = _doorIds.length;
        require(doorIds_length == _keyIds.length && doorIds_length == _doorOptions.length, "Lengths don't match");
        require(doorIds_length > 0, "Empty");
        
        for(uint256 i = 0; i < doorIds_length; i++) {
            _unlock(_doorIds[i], _keyIds[i], _doorOptions[i]);
        }
    }
    
    // Mainly used only for upgradeability/future-proofing
    function unlockAsOwner(uint256 _doorId, uint256 _keyId, uint256 _doorOption) external onlyOwner{
        _unlock(_doorId, _keyId, _doorOption);
    }
    
    function _unlock(uint256 _doorId, uint256 _keyId, uint256 _doorOption) internal {
        //require(balanceOf(_msgSender(), _doorId) > 0, "No doors");
        // Only check balance of keys beforehand
        // Because the burn functions already have this safety check and start with doors first
        // So there's no need to do a balance check for doors and thus, safe gas
        require(balanceOf( _msgSender(), _keyId) > 0, "No keys");
        
        require(doesDoorKeyMatch(_doorId, _keyId), "Door and key don't match");

        DimensionDoorsOpened openedDoorsContract = DimensionDoorsOpened(openedDoorsAdress);
        uint256 openedDoorId = getOpenedDoorId(_doorId, _keyId, _doorOption);
        require(!openedDoorsContract.exists(openedDoorId), "Door already minted");

         // Burn the door and key
        burn(_msgSender(), _doorId, 1);
        burn(_msgSender(), _keyId, 1);
        
        openedDoorsContract.mintTo(_msgSender(), openedDoorId);
        emit doorUnlocked(_msgSender(), openedDoorId);
    }
}