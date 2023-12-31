// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155.sol";
import "./EasyLibrary.sol";
import "./EasyBatcher.sol";

abstract contract EasyMintLogic is ERC1155, EasyBatcher {
    using EasyLibrary for *;
    uint256 public maxMintAmount;
    uint256 public randomCounter;

    bool public paused = true;

    mapping(uint256 => uint256) public currentSupply;
    mapping(uint256 => bool) public createdToken;

    mapping(address => mapping(uint256 => uint256)) public walletMinted;
    mapping(uint256 => string) public roll;

    bool tiersInUse;
    bool onlyTiers;
    EasyLibrary.Tier[] public tiers;
    string public tierURI;
    mapping(address => mapping(uint256 => uint256)) public tierMinted;

    error SkewedArrays();
    error InvalidMintType();
    error IncorrectBatch();
    error InvalidAmount();
    error InvalidID();
    error FailedMintCheck();
    error Paused();
    error NotMintDate();
    error Limited();
    error InsufficientFunds();
    error OutOfStock();
    error NotListed();

    constructor() ERC1155(""){}

    function checkMintType(uint _fromBatch, bool _beState) internal view virtual {
        if ((!_beState && batchData[_fromBatch].bMintInOrder) || (_beState && !batchData[_fromBatch].bMintInOrder)) {
            revert InvalidMintType();
        }
    }

    function checkAmounts(uint _minAmount, uint _maxAmount) internal view virtual {
        if (_minAmount > _maxAmount || _minAmount <= 0) {
            revert InvalidAmount();
        }
    }

     /**
    @dev Admin can set the PAUSE state for all or just a batch.
    @param _pauseAll Whether to pause all batches.
    @param _fromBatch The ID of the batch to pause.
    @param _state Whether to set the batch or all batches as paused or unpaused.
    true = closed to Admin Only
    false = open for Presale or Public
    */
    function pause(bool _pauseAll, uint _fromBatch, bool _state) public virtual onlyAdmins {
        if(_pauseAll){
            paused = _state;
        }
        else{
            setStateOf(0, _state, _fromBatch);
        }
    }

    function setTierUse(bool _inUse, bool _onlyUse) public virtual onlyAdmins {
        tiersInUse = _inUse;
        onlyTiers = _onlyUse;
    }

    /**
    @dev Returns the cost for minting a token from the specified batch ID.
    If the caller is not an Admin, the function will return the presale cost if the batch is a presale batch,
    otherwise it will return the regular batch cost. If the caller is an Admin, the function will return 0.
    */
    function _cost(uint _batchID, bool _onTierList, uint8 _tID) public view virtual returns(uint256){
        if (!checkIfAdmin()) {
            if(_onTierList){
                return tiers[_tID].tCost;
            }
            
            return batchData[_batchID].bCost;
        }
        return 0;
    }

    function checkOut(uint _amount, uint _batchID, bytes32[] calldata proof) private {
        if (!checkIfAdmin()) {
            if(paused || batchData[_batchID].bPaused) {
                revert Paused();
            }

            if (batchData[_batchID].bMintStartDate > 0) {
                if(block.timestamp < batchData[_batchID].bMintStartDate) {
                    revert NotMintDate();
                }
            }

            if(batchData[_batchID].bLimit != 0){
                if(walletMinted[msg.sender][_batchID] + _amount > batchData[_batchID].bLimit) {
                    revert Limited();
                }
                walletMinted[msg.sender][_batchID] += _amount;
            }

            (bool _onTierList, uint8 _tID) = isValidTier(proof, keccak256(abi.encodePacked(msg.sender)));
            if(_onTierList){
                if (tiers[_tID].tLimit != 0) {
                    if (tierMinted[msg.sender][_tID] + _amount <= tiers[_tID].tLimit) {
                        tierMinted[msg.sender][_tID] += _amount;
                    } else if (_tID < tiers.length - 1) {
                        _tID++;
                    }
                }
            } else {
                if(onlyTiers){
                    revert NotListed();
                }
            }
            
            if(msg.value < (_amount * _cost(_batchID, _onTierList, _tID))) {
                revert InsufficientFunds();
            }
        }
    }

    function checkOutScan(uint _id, uint _fromBatch) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            if(batchData[_fromBatch].bMintInOrder){
                currentSupply[_id] = 1;
            }
        }

        if(batchData[_fromBatch].bRollInUse){
            roll[_id] = randomRoll(_fromBatch);
        }

        if(batchData[_fromBatch].bCost != batchData[_fromBatch].bNextCost && batchData[_fromBatch].bRangeNext[2] >= batchData[_fromBatch].bTriggerPoint){
            batchData[_fromBatch].bCost = batchData[_fromBatch].bNextCost;
        }
        randomCounter++;
    }

    /**
    @dev Allows Admins, Whitelisters, and Public to mint NFTs in order from a collection batch.
    Admins can call this function even while the contract is paused.
    @param _to The address to mint the NFTs to.
    @param _numberOfTokensToMint The number of tokens to mint from the batch in order.
    @param _fromBatch The batch to mint the NFTs from.
    @param proof An array of Merkle tree proofs to validate the mint.
    */
    function _mintInOrder(address _to, uint _numberOfTokensToMint, uint _fromBatch, bytes32[] calldata proof) public virtual payable {
        checkMintType(_fromBatch, true);
        if(exists(batchData[_fromBatch].bRangeNext[1])) {
            revert OutOfStock();
        }
        if (_fromBatch >= batchData.length) {
            revert BatchOutOfRange();
        }
        checkAmounts(_numberOfTokensToMint + batchData[_fromBatch].bRangeNext[2] - 1, batchData[_fromBatch].bRangeNext[1]);

        checkOut(_numberOfTokensToMint, _fromBatch, proof);
        
        _mintBatchTo(_to, _numberOfTokensToMint, _fromBatch);
    }

    function _mintBatchTo(address _to, uint _numberOfTokensToMint, uint _fromBatch)private {
        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = batchData[_fromBatch].bRangeNext[2];
            if(!canMintChecker(_id, 1, _fromBatch)) {
                revert FailedMintCheck();
            }
            
            checkOutScan(_id, _fromBatch);

            _ids[i] = batchData[_fromBatch].bRangeNext[2];
            _amounts[i] = 1;
            batchData[_fromBatch].bRangeNext[2]++;
        }
        
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint a single NFT with the given _id, _amount, and _fromBatch parameters for the specified _to address.
    @param _to The address to mint the NFT to.
    @param _id The ID of the NFT to mint.
    @param _amount The amount of NFTs to mint.
    @param _fromBatch The batch end ID that the NFT belongs to.
    @param proof The Merkle proof verifying the ownership of the tokens being minted.
    Requirements:
    - mintInOrder[_fromBatch] must be false.
    - _id must be within the batch specified by _fromBatch.
    - The total number of NFTs being minted across all batches cannot exceed maxMintAmount.
    - If the caller is not an admin, the contract must not be paused and the batch being minted from must not be paused.
    - The caller must have a valid Merkle proof for the tokens being minted.
    - The amount of tokens being minted must satisfy the canMintChecker function.
    - The ID being minted must not have reached its max supply.
    */
    function mint(address _to, uint _id, uint _amount, uint _fromBatch, bytes32[] calldata proof) public virtual payable {
        checkMintType(_fromBatch, false);
        if(!canMintChecker(_id, _amount, _fromBatch)) {
            revert FailedMintCheck();
        }

        checkOut(_amount, _fromBatch, proof);

        checkOutScan(_id, _fromBatch);
        currentSupply[_id] += _amount;
        
        _mint(_to, _id, _amount, "");
    }

    function canMintChecker(uint _id, uint _amount, uint _fromBatch) private view returns(bool){
        if(_id < batchData[_fromBatch].bRangeNext[0] || _id > batchData[_fromBatch].bRangeNext[1]) {
            revert IncorrectBatch();
        }
        checkAmounts(_amount, maxMintAmount);
        if(_id > collectionEndID) {
            revert InvalidID();
        }

        // checks if the id exceeded it's max supply limit that each id in the batch is assigned
        if(batchData[_fromBatch].bSupply != 0 && currentSupply[_id] + _amount > batchData[_fromBatch].bSupply){
            // CANNOT MINT 
            return false;
        }

        // checks if the batch (other than the original) that the id resides in needs requirement token(s)
        if(batchData[_fromBatch].bRequirementTokens.length > 0){
            if(EasyLibrary.hasSufficientTokens(batchData[_fromBatch].bRequirementAddresses, msg.sender, batchData[_fromBatch].bRequirementTokens, batchData[_fromBatch].bRequirementAmounts, batchData[_fromBatch].bRequirementContractType)){
                //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S) AMOUNTS
                return false;
            }
        }

        // CAN MINT
        return true;
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint multiple NFTs at once, given a list of token IDs, their corresponding amounts,
    and the batch from which they are being minted. Checks if the caller has the required permissions and if the maximum allowed mint
    amount and maximum allowed batch mint amount are not exceeded. Also verifies that the specified token IDs are in the given batch,
    and that the caller has passed a valid proof of a transaction to checkOut.
    */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts, uint _fromBatch, bytes32[] calldata proof) public virtual payable {
        checkMintType(_fromBatch, false);
        checkAmounts(_ids.length, maxMintAmount);
        if(_ids.length != _amounts.length) {
            revert SkewedArrays();
        }
        if(!canMintBatchChecker(_ids, _amounts, _fromBatch)) {
            revert FailedMintCheck();
        }

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            _totalBatchAmount += _amounts[i];
        }
        if(_totalBatchAmount <= maxMintAmount) {
            revert Limited();
        }

        checkOut(_totalBatchAmount, _fromBatch, proof);

        for (uint256 k = 0; k < _ids.length; k++) {
            uint256 _id = _ids[k];
            checkOutScan(_id, _fromBatch);
            currentSupply[_ids[k]] += _amounts[k];
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function canMintBatchChecker(uint[] memory _ids, uint[] memory _amounts, uint _fromBatch)private view returns(bool){
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if(!canMintChecker(_id, _amount, _fromBatch)){
                // CANNOT MINT
                return false;
            }
        }

        return true;
    }

    /**
    @dev Allows User to DESTROY multiple tokens they own.
    */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external virtual{
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function randomRoll(uint _fromBatch) internal view virtual returns (string memory){
        return EasyLibrary.randomRoll(
            uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                msg.sender,
                randomCounter,
                roll[randomCounter - 1])
            )),
            randomCounter,
            batchData[_fromBatch].bRollRange[1],
            batchData[_fromBatch].bRollRange[0]
        );
    }

    /**
    @dev Sets the roll for a given token.
    @param _id The token ID.
    @param _roll The value of the roll.
    @param _fromBatch The ID of the batch to set the roll limit for.
    */
    function rollSet(uint256 _id, uint _roll, uint _fromBatch) public virtual payable {
        if (!checkIfAdmin()) {
            EasyLibrary.validateRoll(_roll, batchData[_fromBatch].bRollSwapAllow, batchData[_fromBatch].bRollRange[0], batchData[_fromBatch].bRollRange[1], balanceOf(msg.sender, _id), batchData[_fromBatch].bRollCost);
        }
        roll[_id] = Strings.toString(_roll);
    }

    /**
    @dev Returns the total number of tokens with a given ID that have been minted.
    @param _id The ID of the token.
    @return total number of tokens with the given ID.
    */
    function totalSupplyOfID(uint256 _id) public view virtual returns(uint256) {
        return currentSupply[_id];
    }

    /**
    @dev Returns true if a token with the given ID exists, otherwise returns false.
    @param _id The ID of the token.
    @return bool indicating whether the token with the given ID exists.
    */
    function exists(uint256 _id) public view virtual returns(bool) {
        return createdToken[_id];
    }

    /**
    @dev Returns the maximum supply of a token with the given ID.
    @param _batchID The ID of the batch.
    @return maximum supply of any token from batch. If it is 0, the supply is limitless.
    */
    function checkMaxSupply(uint256 _batchID) public view virtual returns(uint256) {
        return batchData[_batchID].bSupply;
    }

    /**
    @dev Allows admin to set the maximum amount of NFTs a user can mint in a single session.
    @param _newmaxMintAmount The new maximum amount of NFTs a user can mint in a single session.
    */
    function setMaxMintAmount(uint256 _newmaxMintAmount) public virtual onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    /**
    * @dev Validates what tier a user is on for the Tierlist.
    */
    function isValidTier(bytes32[] calldata proof, bytes32 leaf) public view virtual returns (bool, uint8) {
        if (tiersInUse) {
            return EasyLibrary.validateTier(proof, leaf, tiers);
        }
        return (false, 0);
    }

    /**
    @dev Sets a new tier with the provided parameters or updates an existing tier.
    @param _create If true, creates a new tier with the provided parameters. If false, updates an existing tier.
    @param _tID The ID of the tier to be updated. Only applicable if _create is false.
    @param _tLimit The mint limit of the new tier or updated tier.
    @param _tCost The cost of the new tier or updated tier.
    @param _tRoot The Merkle root of the new tier or updated tier.
    Requirements:
    - Only admin addresses can call this function.
    - If _create is false, the ID provided must correspond to an existing tier.
    */
    function setTier(bool _create, uint8 _tID, uint256 _tLimit, uint256 _tCost, bytes32 _tRoot) external virtual onlyAdmins {
        // Define a new Tier struct with the provided cost and Merkle root.
        EasyLibrary.Tier memory newTier = EasyLibrary.Tier(
            _tLimit,
            _tCost,
            _tRoot
        );
        
        if(_create){
            // If _create is true, add the new tier to the end of the tiers array.
            tiers.push(newTier);
        }
        else{
            // If _create is false, update the existing tier at the specified ID.
            if(tiers.length <= 0 || _tID >= tiers.length) {
                revert InvalidID();
            }
            tiers[_tID] = newTier;
        }
    }
}
