// SPDX-License-Identifier: MIT
/*
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - --
-                                                                                                                                                  -
-                                                                                                                                                  -
-                                                                                                                                                  -
-                                                                             .:-----:.                                                            -
-                                                                        :-=++== . . .=++==-                                                       -
-                                                                     :=+=. . . . . . . . . ++=                                                    -
-                                                                   -+=. . . . . . . . . . . . ++.                                                 -
-                                                                 :*= . . . . . . . . .  . . . . +=                                                -
-                                                                =+. . .. . .. . .. . .. . . . . .=*.                                              -
-                                                               ++. . . . . . . . . . . . . . . . . *.                                             -
-                                                              =+. . . . . . . . . . . . . . . . . . #.                                            -
-                                                              #. . . . . . . . . . . . . . . . . . . =+                                           -
-                                                             -+. . . . . . . . . . . . . . . . . . . #                                            -
-                                                             +=. . . . . . . . . . . . . . . . . . . *.                                           -
-                                                             +=. . . . . . . . . . . . . . . . . . . *.                                           -
-                                                             +=. . . . . . . . . . . . . . . . . . . *.                                           -
-                                ...::----.                   ==. . . . . . . . . . . . . . . . . . . *.                                           -
-                                :----------.                 =+. . . . . . . . . . . . . . . . . . . *.                                           -
-                         ....::----+++++++**=++=+*=**+++===*+*+......................................*=:.   ...::::-------------::..              -
-                        ---------++++++**::::==.""       :+::=*........................................-=**::...                  .:------.       -
-                         ------++++++**:::==""           #::::#......................................:::--*                               .=-     -
-                          .------+++**:::*:"             *:::::-==++++++++++=+==---::::::::::--------=++*%=.                             .:+-     -
-                            .:---++**:::*.                =+-:::::::::::::::::::::--------==+++===--:.    .:------.                  .:-=+=.      -
-                            .-----**:::*.      ..::::.._    :===+++=========++++++=====--:.                 .::--=+##*-        ..::-+==-          -
-                              .----*-:-*-------:        ++-.__      ........                       .:-===+===-........-===-.::-++**:              -
-                               .=*++=-:.                      "--_                            :-=++=-                 '""-=*#+==--*:              -
-                         :-----:.                                 ==-.                    :=++=.                           .=*+-++-+.             -
-                  .:----:"                                           :==:              .++=.                        ..........*. +--+             -
-             :----:                                                     .==.         :*+.                   ..................-#:+--"             -
-        :---:.                                                             -+      .++                 ......-=+*******+:::::..*#-*-              -
-     ---.                                                               ...:*    .:*-              ......+*****++:::::::::::::.+*+=               -
-    *                                                       .....:::::::-=++.   .:*-            ....-=***+:::::++**+::::::::::.+*:                -
-    ==.                                         .....:::::::::-==+++++++=-.....::++          .....-***::::+***++==-#+:::::::::.#'                 -
-      -+-                         .....:::::::::::--==++++++++*%-===============#.         .....-+#+::::+#+=------=#+::::::::.+-                  -
-        .=+=-:........:::::::::::::::--==+++++++++==**---------+#===============#.      .......-=#::::::#------=+**:::::::::.+=                   -
-            :--=================-----:.*===========**---=+==+---**==============#..............-**::::::#*******+::::::::..=*:                    -
-                                       ===========**---+-   .+--=#==============#..............-**::::::::::::::::::::...+=:                      -
-                                        *...======**---*     *=-=*-=+-==========-%..............=*:::::::::::::::-...=+=-                         -
-                                         +.    ..=**---*    .+--+#   :-=+========*=..............-=::::::::-.....=+=-:                            -
-                                          -=:     *+---=+:.-*---+*       .-=+=-===*%...............------...=++=-.                                -
-                                            :==.   ++----==----*:             -==+=+*=-...............=+===-.                                     -
-                                               :---.*+-------=*.                  .--++#==++++=====--:.                                           -
-                                                   --*+*+++*+-                                                                                    -
-                                                       ....                                                                                       -
-                                                                                                                                                  -
-                                                                                                                                                  -
-                                                                                                                                                  -
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - --
*/
pragma solidity 0.8.7;

import "./Doodles.sol";
import "./AccessControl.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract SpaceDoodles is ERC721Enumerable, IERC721Receiver, VRFConsumerBaseV2, ReentrancyGuard, AccessControl {

    uint256 public minBatchSize = 20;
    uint256 public maxBatchSize = 40;
    uint256 public constant NUM_PER_WORD = 6;
    bool public launchingActive;
    bool public dockingActive;
    uint8[] public loadedDieLookup;
    uint256 public batchCount;
    string private baseURI;

    Doodles immutable DOODLES;
    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    
    struct RequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }
    RequestConfig public requestConfig;

    struct Stats {
        uint8 rank;
        uint8 piloting;
        uint8 mechanical;
        uint8 stamina;
        uint8 bladder;
        uint8 vibe;
    }
    
    event ChangedStats(
        uint256 indexed _tokenId
    );

    mapping(uint256 => Stats) public tokenStats; // token id => stats
    mapping(uint256 => uint256[]) public batches; // batch id => token ids
    mapping(uint256 => uint256) public requestIdToBatchId; // VRF request id => batch id

    bytes32 constant public SUPPORT_ROLE = keccak256("SUPPORT");
    bytes32 constant public RANK_WRITER_ROLE = keccak256("RANK_WRITER");

    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist.");
        _;
    }

    constructor(address _Doodles,
                address _VRFCoordinator,
                address _LINKToken,
                bytes32 _keyHash,
                uint64 _subId)
        ERC721("Space Doodles", "SDOODLE")
        VRFConsumerBaseV2(_VRFCoordinator) {

        DOODLES = Doodles(_Doodles);
        COORDINATOR = VRFCoordinatorV2Interface(_VRFCoordinator);
        LINKTOKEN = LinkTokenInterface(_LINKToken);

        requestConfig = RequestConfig({
            keyHash: _keyHash,
            subId: _subId,
            callbackGasLimit: 2500000,
            requestConfirmations: 3
        });

        // roll this 256-sided die to get a trait value
        loadedDieLookup = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,7,7,8];

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    // chainlink config setters

    function setSubId(uint64 _subId) external onlyRole(SUPPORT_ROLE) {
        requestConfig.subId = _subId;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyRole(SUPPORT_ROLE) {
        requestConfig.callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyRole(SUPPORT_ROLE) {
        requestConfig.requestConfirmations = _requestConfirmations;
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(SUPPORT_ROLE) {
        requestConfig.keyHash = _keyHash;
    }

    // more configuration

    function setMinBatchSize(uint256 _minBatchSize) external onlyRole(SUPPORT_ROLE) {
        minBatchSize = _minBatchSize;
        if (minBatchSize > maxBatchSize) {
            maxBatchSize = minBatchSize;
        }
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external onlyRole(SUPPORT_ROLE) {
        maxBatchSize = _maxBatchSize;
        if (minBatchSize > maxBatchSize) {
            minBatchSize = maxBatchSize;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
  
    function setBaseURI(string memory uri) external onlyRole(SUPPORT_ROLE) {
        baseURI = uri;
    }

    function setLaunchingActive(bool launchingActive_) external onlyRole(SUPPORT_ROLE) {
        launchingActive = launchingActive_;
    }

    function setDockingActive(bool dockingActive_) external onlyRole(SUPPORT_ROLE) {
        dockingActive = dockingActive_;
    }

    // getters and setters for stats

    function getStats(uint256 tokenId) external view tokenExists(tokenId) returns (Stats memory) {
        Stats memory sd = tokenStats[tokenId];
        require(sd.rank > 0, "Token traits have not been initialized.");
        return sd;
    }

    function setRank(uint256 tokenId, uint8 _rank) external onlyRole(RANK_WRITER_ROLE) tokenExists(tokenId) {
        tokenStats[tokenId].rank = _rank;
        emit ChangedStats(tokenId);
    }

    // batch processing

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return (a + m - 1) / m;
    }

    function processBatch() internal returns (uint256) {
        RequestConfig memory rc = requestConfig;

        uint32 numWords = uint32(ceil(batches[batchCount].length, NUM_PER_WORD));
        uint256 requestId = COORDINATOR.requestRandomWords(rc.keyHash,
                                                           rc.subId,
                                                           rc.requestConfirmations,
                                                           rc.callbackGasLimit,
                                                           numWords);

        requestIdToBatchId[requestId] = batchCount;
        batchCount++;
        return requestId;
    }

    function flushBatch() external nonReentrant onlyRole(SUPPORT_ROLE) returns (uint256) {
        return processBatch();
    }

    function retryBatch(uint256 batchId) public onlyRole(SUPPORT_ROLE) returns (uint256) {
        uint256 batchSize = batches[batchId].length;

        // only allowed to retry if Stats haven't been set
        for (uint256 i; i < batchSize; i++) {
            require(tokenStats[batches[batchId][i]].rank == 0, "Traits have already been set.");
        }

        RequestConfig memory rc = requestConfig;

        uint32 numWords = uint32(ceil(batches[batchId].length, NUM_PER_WORD));
        uint256 requestId = COORDINATOR.requestRandomWords(rc.keyHash,
                                                           rc.subId,
                                                           rc.requestConfirmations,
                                                           rc.callbackGasLimit,
                                                           numWords);

        requestIdToBatchId[requestId] = batchId;
        return requestId;
    }

    // trait assignment

    function selectTrait(uint8 seed) internal view returns (uint8) {
        return loadedDieLookup[seed];
    }

    uint256 constant public SHIFT_BITS = 8;
    function computeStats(uint256 seed) internal view returns (Stats memory) {
        return Stats({rank: 1,
                      piloting: selectTrait(uint8(seed)),
                      mechanical: selectTrait(uint8(seed >> SHIFT_BITS)),
                      stamina: selectTrait(uint8(seed >> (SHIFT_BITS * 2))),
                      bladder: selectTrait(uint8(seed >> (SHIFT_BITS * 3))),
                      vibe: selectTrait(uint8(seed >> (SHIFT_BITS * 4)))});
    }

    // VRF callback function

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 batchId = requestIdToBatchId[requestId];
        uint256 batchSize = batches[batchId].length;
        for (uint256 i; i < batchSize; i++) {
            uint256 j = i / NUM_PER_WORD;
            uint256 seed = randomWords[j] & 0xFFFFFFFFFF;
            uint256 tokenId = batches[batchId][i];
            Stats memory sd = computeStats(seed);
            tokenStats[tokenId] = sd;
            emit ChangedStats(tokenId);
            randomWords[j] >>= 40;
        }
    }

    // launching/docking
    // launch: transfer in a Doodle and transfer/mint out a Space Doodle
    // dock: transfer in a Space Doodle and transfer out a Doodle
    // onERC721Received handler lets you send a Doodle directly to the contract, saving a setAllowedForAll call

    function createSpaceShip(address to, uint256 tokenId) internal {
        batches[batchCount].push(tokenId);
        _safeMint(to, tokenId);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory data) public virtual override nonReentrant returns (bytes4) {
        if (msg.sender == address(DOODLES)) {
            require(launchingActive, "Launching is not allowed at this time.");

            if (!_exists(tokenId)) {
                createSpaceShip(from, tokenId);
                if ((data.length == 0 && batches[batchCount].length >= minBatchSize) ||
                    batches[batchCount].length >= maxBatchSize) {
                    processBatch();
                }
            } else {
                _safeTransfer(address(this), from, tokenId, "");
            }
        } else if (msg.sender == address(this)) {
            require(dockingActive, "Docking is not allowed at this time.");
            DOODLES.safeTransferFrom(address(this), from, tokenId);
        } else {
            revert("Only Doodles and Space Doodles are supported.");
        }

        return this.onERC721Received.selector;
    }

    function launchMany(uint[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            DOODLES.safeTransferFrom(msg.sender, address(this), tokenIds[i], "skip"); // skip batch check in onERC721Received
        }

        if (batches[batchCount].length >= minBatchSize) {
            processBatch();
        }
    }

    function dockMany(uint[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}