pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT



import "./ILockingLayers.sol";
import "./VRFConsumerBase.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @dev LockingLayers is an ERC721 contract that contains the logic and source of ownership
 * for Whole Picture. The core mechanics breakdown as follows:
 *   - Each artwork consists of 4 layers. 
 *   - A Layer contain a canvasId.
 *   - Each layer shifts its canvasId after X blocks, unless the layer is locked.
 *   - Layers are revealed over time, and the entire process ends after all layers are revelaed and
 *     all layer shifts have finished.
 *   
 * Schema is:
 *   - artworkId => owned by address
 *     - canvasIds[NUM_LAYERS] => owned by artwork => NUM_LAYERS = 4 so each artwork ownes 4 canvasIds
 *
 * Layer Mappings:
 *   - Mappings from canvasId => canvas are stored offchain in IPFS. Mapping json file can be viewed
 *   - at ipfs://QmZ7Lpf5T4NhawAKsWAmomG5sxkSN6USfRVRW5nMzjrHdD
 * 
 * IMPORTANT NOTES:
 *  - canvasIds and actionIds are 1 indexed, not 0 indexed. This is because a 0 index signifies that
 *  a layer is not locked, and an actionId of 0 signifies that the action has not happened yet.
 */
contract LockingLayers is ILockingLayers, ERC721, VRFConsumerBase, Ownable {
    using SafeMath for uint256;


    // Total number of artworks to create
    uint16 constant TOTAL_ARTWORK_SUPPLY = 1200;


    // The layerIds owned by each artwork
    uint8 constant NUM_LAYERS = 4;


    // Actions are shifts per each layer
    // NOTE: all actions are 1 indexed, not 0 indexed. This is because an action idx of
    // 0 means that layer does nto exist yet
    uint8 constant ACTIONS_PER_LAYER = 5;


    // Defines number blocks required to trigger an action
    uint16 constant BLOCKS_PER_ACTION = 4444;


    // Total number of actions for the project
    uint16 constant MAX_ACTIONS = ACTIONS_PER_LAYER * NUM_LAYERS;


    // There will be the same number of layerIds because each artwork is guaranteed to have 4 layers
    uint16 constant NUM_CANVAS_IDS = TOTAL_ARTWORK_SUPPLY;


    // Number of artworks in each tier
    uint16[3] totalArtworksInTier = [200, 800, 200];


    // remaining artworks in each tier that can be purchased
    uint16[3] artworksRemainingInTier = [200, 800, 200];


    // CID of the mappings from canvasId to canvas! View on ipfs.
    string constant provinanceRecord = "QmZ7Lpf5T4NhawAKsWAmomG5sxkSN6USfRVRW5nMzjrHdD";


    // First artwork will be id of 0
    uint16 nextArtworkId = 0;


    // Records the official 
    uint256 private _startBlock = 0;

   
    // True once artwork has begun (once VRF has been received)
    bool private isArtworkStarted = false; 


    // Block that stores first time of first purchase
    uint256 public firstPurchaseBlock = 0;


    // If not all artworks are sold, will trigger start this many blocks after first artwork purchased
    uint256 public constant AUTOMATIC_START_BLOCK_DELAY = 184000;


    // Mapping to the artwork tier for each token
    // artworkId => tier
    mapping(uint256 => ArtworkTier) public artworkTier;

    
    // The constant number of locks for each purchase tier.
    uint8[4] locksPerTier = [1, 2, 4];


    // Remaining locks per artwork -- each lock will decrement value
    // artworkId => _locksRemaining
    mapping(uint256 => uint8) _locksRemaining;


    // A record of locked layers for each token:
    // artworkId => lockedCanvasId[NUM_LAYERS]
    // NOTE: a value of 0 signifies that a layer is NOT locked
    //   - Example: 
    //     - lockedLayersForToken[100][1] = 10
    //       - can be read as artworkId 100 has layer 1 (0 indexed) locked with canvasId 10.
    //     - lockedLayerForToken[100][0] = 0
    //       - can be read as artworkId 100's layer 0 is NOT locked
    mapping(uint256 => uint16[NUM_LAYERS]) lockedLayersForToken;


    // A record of if an artwork is locked and at which action it was locked.
    // canvasId => actionId[NUM_LAYERS] -> ~7 actions per layer so uint8 is good for actionId
    // canvasIds are reused for each layer to save on storage costs.
    //   - Example:
    //     - lockedLayerHistory[10][1] = 2
    //       - can be read as canvasId 10 for second layer (0 indexed) was locked on action 2
    //     - lockedLayerHistory[10][2] = 0
    //       - can be read as canvasId 10 has NOT BEEN LOCKED for third layer
    mapping(uint16 => uint8[NUM_LAYERS]) lockedLayerHistory;


    // Offsets for layerIds for each layer, used when finding base id for next layer
    // The [0] index is set by Chainlink VRF (https://docs.chain.link/docs/chainlink-vrf-api-reference)
    // Later indexes are only influenced by participants locking layers, so the artwork is
    // more connected with the behaviour of the participants.
    // INVARIANT: Can only change for future UNLOCKED layer, can never be altered for 
    // past layers. Needs to be deterministic for past/current layers. 
    //   - Example:
    //     - layerIdStartOffset[1] = 19413
    //     - can be read as the starting canvasId will be offset by 19413
    uint256[NUM_LAYERS] public canvasIdStartOffsets;

    // CHAINLINK VRF properties -- want to keep locally to test gas spend
    bytes32 constant keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 constant vrfFee = 2000000000000000000;

    // Store the current URI -- URI may change if domain is updated
    string baseURI = "https://su3p5zea28.execute-api.us-west-1.amazonaws.com/prod/metadata/";

    constructor() 
        ERC721("Whole Picture", "WP") 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )    
    public {

    }

    /** 
      * @dev Metadata base uri    
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

   

    /**
     * @dev Returns the currnet price in wei for an artwork in a given tier.
     * Pricing is a bonding curve, using 4 quadratic easing sections:
     *   - Enthusiast tier is an ease out curve
     *   - Collector tier is ease in segment until midway point, then ease out
     *   - Strata tier is ease in.
     */
    function currentPrice(ArtworkTier tier) public override view returns (uint256) {
        if(artworksRemainingInTier[uint256(tier)] == 0) {
            return 0;
        }

        uint256 min;
        uint256 max;
        uint256 numerator;
        uint256 denominator;
        
        if(tier == ArtworkTier.ENTHUSIAST) {
            min = 1 * 1 ether / 10;
            max = 5 * 1 ether / 10;
            numerator = totalArtworksInTier[0] - artworksRemainingInTier[0];
            denominator = totalArtworksInTier[0];

        }
        else if(tier == ArtworkTier.COLLECTOR) {
            uint256 collectorMin =  5 * 1 ether / 10;
            uint256 collectorMax = 25 * 1 ether / 10;
            uint256 midwayPrice = collectorMin + (collectorMax - collectorMin) / 2;
            uint256 midwayArtworks = totalArtworksInTier[1] / 2;
            if(artworksRemainingInTier[1] > midwayArtworks){
                // invert so switch min and max
                min = midwayPrice;
                max = collectorMin;
                numerator = midwayArtworks - (totalArtworksInTier[1] - artworksRemainingInTier[1]);
                denominator = midwayArtworks;
            } else {
                min = midwayPrice;
                max = collectorMax;
                numerator = midwayArtworks - artworksRemainingInTier[1];
                denominator = midwayArtworks;
            }
        }
        else {
            // Strata tier so return STRATA_TIER price
            // inverted so switch max and min
            max = 25 * 1 ether / 10;
            min = 4 * 1 ether / 1;
            numerator = artworksRemainingInTier[2] - 1; // inverted so use remaining for numerator
            denominator = totalArtworksInTier[2] - 1; // minus one so ends on 4
        }
        
        return easeInQuad(min, max, numerator, denominator);
    }


    /**
     * @dev Get the price and available artworks for a given tier
     *   - Returns:
     *      - uint256 => PRICE in wei
     *      - uint256 => available artworks
     */
    function getTierPurchaseData(ArtworkTier tier) public override view returns (uint256, uint16) {
        return (currentPrice(tier), artworksRemainingInTier[uint256(tier)]);
    }


    /**
     * @dev Returns the number of artworks issued.
     */
    function totalArtworks() public override pure returns (uint16) {
        return TOTAL_ARTWORK_SUPPLY;
    }


    /**
     * @dev Returns the total artworks remaining across all tiers.
     */
    function availableArtworks() public override view returns (uint16) {
        return artworksRemainingInTier[0] + artworksRemainingInTier[1] + artworksRemainingInTier[2];
    }


    /**
     * @dev The number of blocks remaining until next layer is revealed.
     */
    function blocksUntilNextLayerRevealed() public override view returns (uint256) {
        if(!hasStarted()) {
            return 0;
        }
        return ((getAction()) * BLOCKS_PER_ACTION + startBlock()) - block.number;
    }


    /**
     * @dev Checks if an artwork can lock the current layer.
     *   - if no locks remaining or if layer is already locked, cannot lock
     */
    function canLock(uint256 artworkId) public override view returns (bool) {
        // check locks
        return (_locksRemaining[artworkId] > 0);
    }


    /**
     * @dev Checks if an artwork can lock the current layer.
     *   - if no locks remaining or if layer is already locked, cannot lock
     */
    function locksRemaining(uint256 artworkId) public view returns (uint8) {
        // check locks
        return _locksRemaining[artworkId];
    }


    /**
     * @dev Get canvasIds for each layer for artwork.
     */
    function getCanvasIds(uint256 artworkId) public override view returns (uint16, uint16, uint16, uint16) {
        // ensure no ids sent if hasn't started or artwork doesn't exist
        if(!hasStarted() || !_exists(artworkId)) {
            return (0, 0, 0, 0);
        }

        (uint8 currentLayer, uint8 currentAction) = getCurrentLayerAndAction();

        // initialize array, all values start at 0
        uint16[NUM_LAYERS] memory canvasIds;

        // now need to loop through all layers
        for(uint8 i = 0; i <= currentLayer; i++) {
            uint8 layerAction;

            // check if we are on the current (topmost) layer, in which case we use the current action
            if(i == currentLayer) {
                layerAction = currentAction;
            } else {
                // otherwise we use the final action for previous layer
                layerAction = ACTIONS_PER_LAYER;
            }

            // now get the canvasId for action for target layer
            canvasIds[i] = getCanvasIdForAction(artworkId, i, layerAction);
        }
        return (canvasIds[0], canvasIds[1], canvasIds[2], canvasIds[3]);
    }


    /**
     * @dev Returns the startBlock for the artwork.
     * There are two conditions for the artwork to start -- either all artworks are sold,
     * or the automatic trigger started after the first artwork has sold has been reached.
     */
    function startBlock() public view returns (uint256) {    
        return _startBlock;      
    }


    /**
     * @dev Check whether the artwork has started.
     */
    function hasStarted() public view returns (bool) {
        return startBlock() != 0;
    }


    /**
     * @dev Gets the overall action since the start of the process.
     * NOTE: Actions are 1 indexed! 0 means no actions because has not begun.
     */
    function getAction() public view returns (uint8) {
        if(!hasStarted()) {
            return 0;
        }

        uint256 elapsedBlocks = block.number.sub(startBlock());
        // actions are 1 indexed so need to add 1
        uint256 actionsElapsed = elapsedBlocks.div(BLOCKS_PER_ACTION) + 1;
        uint256 clampedActions = Math.min(actionsElapsed, MAX_ACTIONS);
        // console.log("ElapsedBlocks: %s", elapsedBlocks);
        return uint8(clampedActions);
    }


    /**
     * @dev Returns the current layer as well as the current action.
     *   - Returns:
     *     - (layer, actionInLayer)
     *   - If action == 0, then layer is not revealed
     */
    function getCurrentLayerAndAction() public view returns (uint8, uint8) {
        
        uint8 totalActions = getAction();
        
        // ensure we return 
        if(totalActions == 0) {
            return (0, 0);
        }

        // need to subtract 1 because actions start at 1
        uint8 actionZeroIndexed = totalActions - 1;

        uint8 currentLayer = (actionZeroIndexed) / ACTIONS_PER_LAYER;
         
        uint8 currentActionZeroIndexed = actionZeroIndexed - (currentLayer * ACTIONS_PER_LAYER);
        
        // re-add 1 to restore 1 index
        uint8 currentAction = currentActionZeroIndexed + 1;

        return (currentLayer, currentAction);
    }

    /**
     * @dev Purchases an artwork.
     *   - Returns the artworkID of purchased work.
     *   - Reverts if insuffiscient funds or no artworks left.
     */
    function purchase(ArtworkTier tier) public override payable returns (uint256) {
        require(artworksRemainingInTier[uint256(tier)] > 0, "No artworks remaining in tier!");

        // Validate payment amount
        uint256 weiRequired = currentPrice(tier);
        require(msg.value >= weiRequired, "Not enough payment sent!");
        
        uint256 newArtworkId = nextArtworkId;

        // check if first sale, and if so set first sale block
        if(newArtworkId == 0) {
            firstPurchaseBlock = block.number;
        }

        // mint new artwork!
        _safeMint(_msgSender(), newArtworkId);

        // record tier and the number of locks
        artworkTier[newArtworkId] = tier;
        _locksRemaining[newArtworkId] = locksPerTier[uint256(tier)];

        // decrement artworks available in tier
        artworksRemainingInTier[uint256(tier)] -= 1;

        // incriment artwork to the next artworkId
        nextArtworkId++;

        // check if all artworks sold, then trigger startBlock if not already started
        if(nextArtworkId == TOTAL_ARTWORK_SUPPLY) {
            if(!hasStarted()) {

                requestStartArtwork();
            } 
        }



        emit ArtworkPurchased(newArtworkId, uint8(tier));

        return newArtworkId;
    }

    /**
     * @dev Request to start the artwork!
     *   - Acheived by requesting a random number from Chainlink VRF.
     *   - Will automatically be requested after the last sale -- or can be requested
     *     manually once sale period has ended.
     * Requirements:
     *   Can only occur after:
     *     - All works have been sold
     *     - Sale period ended (X blocks past the block of the first purchase)
     *     - Has not already been started
     *     - Enough LINK on contract
     */
    function requestStartArtwork() public returns (bytes32) {
        require(!hasStarted(), "Artwork has already been started!");
        
        // Require all artworks sold or after sale period has ended
        require(
            availableArtworks() == 0 || 
            firstPurchaseBlock > 0 && block.number > firstPurchaseBlock + AUTOMATIC_START_BLOCK_DELAY,
            "Cannot start the artwork before all works are sold out or until after sale period"
        );




        // Request randomness from VRF
        return requestRandomness(keyHash, vrfFee, block.number);

    }


    /** 
     * @dev Respond to Chainlink VRF
     *   - This will start artwork if not already started
     */
    function fulfillRandomness(bytes32 /*requestId*/, uint256 randomness) internal override {
        startArtwork(randomness);
    }


    /**
     * @dev Start the artwork! This sets the start seed and start block.
     *   - Can only be called once
     */
    function startArtwork(uint256 randomSeed) internal {
        // Ensure start block not already set (in case random number requested twice before being fulfilled)
        require(!hasStarted(), "Artwork has already started, seed cannot be set twice!");



        // Set start block and the start seed, which kicks off the artwork experience!!!!!
        _startBlock = block.number;

        // The first canvas start is the random Seed!
        canvasIdStartOffsets[0] = randomSeed % TOTAL_ARTWORK_SUPPLY;
    }


    /**
     * @dev Lock artwork layer.
     *   - Reverts if cannot lock.
     *   - Emits LayerLocked event
     */
    function lockLayer(uint256 artworkId) public override {

        require(hasStarted(), "Art event has not begun!");

        require(_exists(artworkId), "Artwork does not exist!");

        // require locking party to be owner
        require(_msgSender() == ownerOf(artworkId), "Must be artwork owner!");

        // require locks remaining
        require(canLock(artworkId), "No locks remaining!");

        // first determine active layer and current action
        (uint8 currentLayer, uint8 currentAction) = getCurrentLayerAndAction();
        
        // Ensure we are not on action 0, which means cannot lock
        require(currentAction > 0, "Canvas is not yet revealed!");

        // recreate history to determine current canvas
        uint16 currentCanvasId = getCanvasIdForAction(artworkId, currentLayer, currentAction);
        
        // ensure not already locked so user does not waste lock
        uint8 currLockedValue = lockedLayerHistory[currentCanvasId][currentLayer];
        require(currLockedValue == 0, "Layer must not be already locked!");
        require(currentCanvasId > 0, "Invalid canvas id of 0!"); // is this needed???

        // update locked layer by idx mapping
        lockedLayersForToken[artworkId][currentLayer] = currentCanvasId;

        // update canvasId locked layer mapping
        lockedLayerHistory[currentCanvasId][currentLayer] = currentAction;

        // Update start canvasId offset for next layer
        if(currentLayer < NUM_LAYERS - 1) {

            canvasIdStartOffsets[currentLayer + 1] = (block.number + canvasIdStartOffsets[currentLayer]) % TOTAL_ARTWORK_SUPPLY;
        }



        _locksRemaining[artworkId] -= 1;
        emit LayerLocked(artworkId, currentLayer, currentCanvasId);
    }


    /**
     * @dev Valid canvasIds are always 1 indexed! An index of 0 means canvas is not yet revealed.
     */
    function incrimentCanvasId(uint16 canvasId) internal pure returns (uint16) {
        return (canvasId % NUM_CANVAS_IDS) + 1;
    }


    /**
     * @dev Gets the corresponding canvasId for an artwork and layer at a given action.
     *   This function calculates the current canvas by starting at first canvas of the current
     *   layer and recreating past actions, which leads to the current valid layer.
     *     - Each artworkID should ALWAYS return a unique canvas ID for the same action state.
     *     - CanvasIds are 1 indexed, so a revealed canvas should NEVER return 0!
     */
    function getCanvasIdForAction(uint256 artworkId, uint8 layer, uint8 action) internal view returns (uint16) {        

        // If we are on 0 action, layer is not revealed no valid canvasId
        if(action == 0) {
            return 0;
        }

        // If artwork does not exist, return 0
        if(!_exists(artworkId)) {
            return 0;
        }

        // If canvas is locked, return the locked canvasId
        uint16 lockedCanvasId = lockedLayersForToken[artworkId][layer];
        if(lockedCanvasId != 0) {

            return lockedCanvasId;
        }

        // first canvasId is 1 INDEXED => the offset + the artwork id + 1
        uint16 currCanvasId = uint16(((canvasIdStartOffsets[layer] + artworkId) % (NUM_CANVAS_IDS)) + 1);

        // We begin at action 1, and then find corresponding canvasId. Then we incriment for each
        // action while also checking if canvasId has been locked in the past. This will be expensive
        // when many layers are locked.

        
        // this will start on second action, and then work way up to latest final action
        for(uint8 i = 1; i < action; i++) {

            // incriment the currentCanvasId
            currCanvasId = incrimentCanvasId(currCanvasId);

            // check if this canvas was locked on a previous action
            uint8 canvasLockedOnAction = lockedLayerHistory[currCanvasId][layer];
            
            // TODO: Prevent infinite loop just in case??

            // while canvasId was locked on a previous action, incriment the current canvasId
            while( canvasLockedOnAction != 0 && canvasLockedOnAction <= i) {

                // advance canvas step
                currCanvasId = incrimentCanvasId(currCanvasId);
                canvasLockedOnAction = lockedLayerHistory[currCanvasId][layer];
            }
        }

        return currCanvasId;
    }

    
    /**
     * @dev Ease in quadratic lerp function -- x * x, invert for ease out
     */
    function easeInQuad(uint256 min, uint256 max, uint256 numerator, uint256 denominator) 
        internal pure returns (uint256) 
    {
        if(min <= max) {
            // min + (max - min) * x^2
            return (max.sub(min)).mul(numerator).mul(numerator).div(denominator).div(denominator).add(min);
        }
        // inverted -> max - (max - min) * x^2
        return min.sub((min.sub(max)).mul(numerator).mul(numerator).div(denominator).div(denominator));
    }


    /**
     * @dev Updates the URI in case of domain change or switch to IPFS in the future;
     */
    function setBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }
    

    /**
     * @dev Withdrawl funds to owner
     *   - This saves gas vs if each payment was sent to owner
     */
    function withdrawlFunds() public {
        (bool success, ) = address(0x1Df3260ea86d338404aC49F3D33cec477a46A827).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

}