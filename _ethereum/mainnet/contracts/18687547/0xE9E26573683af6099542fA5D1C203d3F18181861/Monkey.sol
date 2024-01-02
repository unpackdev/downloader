//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**                                                                                                                       
    __  __  ___  _   _ _  _________   __
|  \/  |/ _ \| \ | | |/ / ____\ \ / /
| |\/| | | | |  \| | ' /|  _|  \ V / 
| |  | | |_| | |\  | . \| |___  | |  
|_|  |_|\___/|_| \_|_|\_\_____| |_|                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                           
                                                                     ###                                                               
                                                     ###+++++++++++###++##                                                             
                                                   ##+---------------++--+++####                                                       
                                                 ##+---------------------------++##                                                    
                                                ##++#########+--------------------+##                                                  
                                                #### ##++++#+++++------------------+##                                                 
                                                    ###+-+#####++-+++--------------++##                                                
                                                    ##+++++####+++##++++--++++-----+++##                                               
                                                    ##-..---+#######+-.......-++---+++##                                               
                                                    #-...----+####+-..----.....+#++###+#+##                                            
                                               #++-++..-+++++---+-.-+++++++--..-###-...-..-+#                                          
                                              #-----+--+-....+-...-++......++-.-#+--+++++++--#                                         
                                             #+-++++#--+--+#+---..-----##+..----#++++--..-++--#                                        
                                             #-++--+##-+++###+------+++###-.---+#+++-.....-+--#                                        
                                             #-+-.-++#+++####+++-+++++###--++-+##++++-....---+#                                        
                                             #+--.-+####+++-.-+++++..--++++++###+###+-....---#                                         
                                              #+--+++#-......................+#####+---..--+##                                         
                                               ##+-+#-....................---.+####++++--+##                                           
                                                 ####+---+.............---++--+#####+++###                                             
                                       #++-+#      ###+----------------------+#######                                                  
                                       #-..-#       ####++----------------++######                                                     
                                  #++####++-+##+##    #####+++++++++++++########                                                       
                                 #-..--+##+-+#...+#   ##+++####+###+++########++##           ######                                    
                                 ##+++-.++--++..-+#  #++++##++---++++++++++###++++#       ##+--...-+#                                  
                                    ##+-...--+#+++###+---+##+-------------+###+++++## #++++..++++-+##                                  
                               #+--+##+...-+--++-+##----+##-.-----++------+###+-----+##....+++########                                 
                               #+--+--...+++-...-###++++##+.....-------...++###------+#++++++-++##+--+#                                
                                ##++++-....-++++##++###+++-..............-+++###++--++#-.---+++-+##++##                                
                                     ##+...--+##+++#+##+-..................+++####++--#+----+++++#####                                 
                                       #+++++##+++####++.-..................+++####+#+##+++-..-+++--+#                                 
                                          ##+++#######+#+-................---++###########++-+++##+++#                                 
                                            ###     ###++.......--........-#######   #########     #                                   
                                    ########   #++++##++#+-...-++----...--+###+####                                                    
                                 ##++--++++++# #++++########+---------++#+++########                                                   
                                #+--+##########+++++#######++++#+++#++++########++++++##                                               
                               #++-+##     ##+-------++#####++##++####++#####++--------+#                                              
                               #+---+#     #----------++####+++++++++++####+------------+#                                             
                                #+---##    #+--------+++#+#################++++---------+#                                             
                                 ##+##     #+++-------+#######################+-------++##                                             
                                           ##+++------+++#######+++#########+++------+++##                                             
                                           ######+++++++++#######++#######++++++++++######                                             
                                         #+-...--++++########   ####   #########+++---...-##                                           
                                       ##+-+-.-.........--+##           ##+-..........-.+--###                                         
                                      #++++--++-.....--...+#            #+-...-......++---++-+#                                        
                                      ###+-+#+-..-+####+-++#             #++++###+-...-#+--+##                                         
                                        #++##++++###                             ###+++###++#   
                                                              
Dapp: https://www.jungle-protocol.com/
Telegram: https://t.me/Jungle_Protocol
Twitter: https://twitter.com/Jungle_Protocol

 */

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IConfig.sol";
import "./IBanansToken.sol";
import "./IStolenPool.sol";
import "./IRandomizer.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
Monkey: destroyer of $BANAN
- Non-transferrable ERC721
- Mintable by burning $BANAN
- Minted as one of 3 tiers: white, gold, diamond, which have different reward rates per attack for banans in the stolen pool
- Each monkey has 5 HP (can fail 5 attacks, each failed attack is -1 HP), and has a 50/50 chance of attack success
- When a monkey loses all HP, it is burned
- Monkeys cannot be burned by the owner, but can be rerolled for the same price in banans paid to mint
- 
 */

contract Monkey is ERC721, Ownable, ReentrancyGuard {
    //================================================================================================
    // SETUP
    //================================================================================================
    using SafeERC20 for IERC20;

    string public baseURI =
        "https://bafybeicblns3rjbuqytxlh6rj6vv6isevkowtyoa7h6fitazvz5js4uxwy.ipfs.nftstorage.link/";

    IConfig public config;

    bool private isInitialized;
    bool public monkeyMintIsOpen;
    bool public monkeyAttackIsOpen;

    uint16 public constant PERCENTAGE_DENOMINATOR = 10000;
    uint32 public amountMinted;
    uint256 public amountBurned;
    uint32 public startTimestamp;
    uint16 public monkeyBatchSize = 50;
    uint32 public monkeyMintSecondsBetweenBatches = 1 days;
    uint8 public monkeyMaxPerWallet = 3;
    uint32 public monkeyAttackCooldownSeconds = 8 hours;
    uint8 public monkeyAttackHpDeductionAmount = 1;

    uint128 public monkeyMintPriceInBanans = 451 * 1e18;

    uint16 public monkeyMintBananFeePercentageToBurn = 2000; //20%
    uint16 public monkeyMintBananFeePercentageToStolenPool = 8000; //80%
    uint16 public monkeyMintTier1Threshold = 6000; //60%
    uint16 public monkeyMintTier2Threshold = 3000; //30%, used as chance > tier1, chance <= tier1+tier2
    uint8 public monkeyHP = 5; //number of survivable attacks
    uint16 public monkeyHitRate = 5000; //50%

    uint16 public monkeyAttackHpDeductionThreshold = 7500; //75%

    uint24 public requestNonce;
    uint32 public constant claimRequestTimeout = 15 minutes;

    struct MonkeyEntry {
        uint16 healthPoints;
        uint8 tier;
        uint32 lastAttackTimestamp;
        string tokenURI;
        bool hasAttacked;
    }
    mapping(uint256 => MonkeyEntry) public monkeys;
    mapping(address => uint256[]) public ownerToMonkeyIds;
    mapping(uint256 => uint256) public batchNumberToAmountMinted;
    mapping(uint256 => uint256) public batchNumberToNumRerolls; // used to expand number minted per batch for rerolls since one is being burned, i.e. mintable0 = 50, reroll, mintable1 = 51, but there are still 50 since 1 was burned. just so that rerolls can't be used to drain the batch.

    event MonkeyMint(
        uint256 monkeyId,
        uint256 tier,
        uint256 healthPoints,
        address owner
    );
    event MonkeyReroll(address owner, uint256 monkeyId);
    event MonkeyHealthPointsUpdated(uint256 monkeyId, uint256 healthPoints);
    event AttackResult(
        uint256 monkeyId,
        address attackSender,
        string attackResult
    );

    error ForwardFailed();
    error MonkeysPerWalletLimitReached();
    error TisSoulbound();
    error EOAsOnly(address sender);
    error InsufficientBanansForMonkeyMint();
    error MaxMonkeysMinted();
    error NoMonkeysOwned();
    error InvalidAttackVerdict(uint256 verdict);
    error CallerIsNotConfig();
    error AttackOnCooldown();
    error MintIsClosed();
    error AttacksAreClosed();
    error NotOwnerOfMonkey();
    error CantRerollMonkeyThatHasAttacked();

    constructor(
        address _configManagerAddress
    ) ERC721("Monkey", "MNK") {
        config = IConfig(_configManagerAddress);
        startTimestamp = uint32(block.timestamp);
    }

    //================================================================================================
    // MINT + REROLL LOGIC
    //================================================================================================

    /**
        @dev requestToMintMonkeys - mints monkeys after necessary checks
        @notice requires prior approval of this contract to spend user's $BANAN!
            3 Args:
                _amount: number of monkeys to mint
                _isReroll: true if this is a reroll, false if it's a new mint
                _idToBurn: if _isReroll is true, this is the monkeyId to burn
        @notice checks monkey mint is open
        @notice if reroll, calls _burnMonkey, and negates effect on total mintable monkeys this batch
        @notice checks if max monkeys have been minted within this batch
        @notice checks if user has enough $BANAN to mint
        @notice checks if user has reached max monkeys per wallet
        @notice checks if user is an EOA
        @notice banans "sent" to the stolen pool are burned here and "virtually deposited" to the stolen pool via depositFromMonkey()
     */

    function requestToMintMonkeys(
        uint8 _amount,
        bool _isReroll,
        uint256 _idToBurn
    ) public payable nonReentrant returns (uint256) {
        IERC20 banans = IERC20(config.banansAddress());

        uint256 mintTransactionBanansTotal = monkeyMintPriceInBanans * _amount;
        uint256 amountToBurn = Math.mulDiv(
            mintTransactionBanansTotal,
            monkeyMintBananFeePercentageToBurn,
            PERCENTAGE_DENOMINATOR
        );
        uint256 amountToStolenPool = Math.mulDiv(
            mintTransactionBanansTotal,
            monkeyMintBananFeePercentageToStolenPool,
            PERCENTAGE_DENOMINATOR
        );

        if (msg.sender != tx.origin && msg.sender != address(this)) {
            revert EOAsOnly(msg.sender);
        }

        if (!monkeyMintIsOpen) {
            revert MintIsClosed();
        }

        if (banans.balanceOf(msg.sender) < mintTransactionBanansTotal) {
            revert InsufficientBanansForMonkeyMint();
        }

        if (
            balanceOf(msg.sender) + _amount > monkeyMaxPerWallet && !_isReroll
        ) {
            revert MonkeysPerWalletLimitReached();
        }

        if (_isReroll) {
            if (ownerOf(_idToBurn) != msg.sender) {
                revert NotOwnerOfMonkey();
            }
            if (monkeys[_idToBurn].hasAttacked) {
                revert CantRerollMonkeyThatHasAttacked();
            }
            ++batchNumberToNumRerolls[getBatchNumber()];
            _burnMonkey(_idToBurn);
            emit MonkeyReroll(msg.sender, _idToBurn);
        }

        uint256 thisBatchNumber = getBatchNumber();
        if (
            batchNumberToAmountMinted[thisBatchNumber] + _amount >
            monkeyBatchSize + batchNumberToNumRerolls[thisBatchNumber]
        ) {
            revert MaxMonkeysMinted();
        }

        if (
            banans.allowance(msg.sender, config.bananStolenPoolAddress()) <
            mintTransactionBanansTotal
        ) {
            banans.forceApprove(address(this), mintTransactionBanansTotal);
        }

        banans.safeTransferFrom(
            msg.sender,
            address(this),
            mintTransactionBanansTotal
        );
        IBanansToken(address(banans)).burn(mintTransactionBanansTotal);

        IStolenPool(config.bananStolenPoolAddress()).virtualDeposit(
            amountToStolenPool
        );

        uint256 randomNumber = IRandomizer(config.randomizerAddress())
            .getRandomNumber(msg.sender, block.timestamp, requestNonce);

        batchNumberToAmountMinted[thisBatchNumber] += _amount;
        ++requestNonce;

        _mintNMonkeys(randomNumber, _amount);
    }

    //------------------------------------------------------------------------------------------------
    // MINT / REROLL - RELATED INTERNAL FUNCTIONS
    //------------------------------------------------------------------------------------------------
    /**
        @dev wrapper to call _mintMonkey multiple times
        @notice uses first random to generate more by hashing that number and the iterator value
     */
    function _mintNMonkeys(uint256 _randomNumber, uint256 _amount) private {
        for (uint256 i = 0; i < _amount; i++) {
            uint256 newRandom = uint256(
                keccak256(abi.encode(_randomNumber, i))
            );
            _mintMonkey(newRandom);
        }
    }

    /**
        @dev mints a monkey using rng to determine tier. 
        @notice important that ++amountMinted happens before anything that depends on amountMinted,
            this is the token ID.
        @notice sets tokenURI to the baseURI + tier + .json
        @notice pushes latest tokenId to the ownerToMonkeyIds mapping
     */
    function _mintMonkey(uint256 _randomNumber) private {
        address recipient = msg.sender;
        uint256 randValMod = _randomNumber % PERCENTAGE_DENOMINATOR;

        ++amountMinted;

        MonkeyEntry storage monkey = monkeys[amountMinted];
        monkey.healthPoints = monkeyHP;

        if (randValMod <= monkeyMintTier1Threshold) {
            monkey.tier = 1;
        } else if (
            randValMod > monkeyMintTier1Threshold &&
            randValMod <= monkeyMintTier1Threshold + monkeyMintTier2Threshold
        ) {
            monkey.tier = 2;
        } else {
            monkey.tier = 3;
        }

        string memory thisTokenURI = string(
            abi.encodePacked(baseURI, Strings.toString(monkey.tier), ".json")
        );

        monkey.tokenURI = thisTokenURI;
        ownerToMonkeyIds[recipient].push(amountMinted);

        _safeMint(recipient, amountMinted);

        emit MonkeyMint(
            amountMinted,
            monkey.tier,
            monkey.healthPoints,
            recipient
        );
    }

    /**
        @dev burns monkey nft, and removes it's corresponding entries in all related mappings and from the owner's array of owned monkey ids...
        ...finds index in owned monkey ids array corresponding to desired monkey id, and replaces it with the last element in the array, then pops the last element
    */
    function _burnMonkey(uint256 _id) private {
        //remove monkey ownerToMonkeyIds mapping

        address monkeyOwner = ownerOf(_id);
        uint256[] storage monkeyIds = ownerToMonkeyIds[monkeyOwner];

        if (monkeyIds.length == 0) {
            revert NoMonkeysOwned();
        }

        if (monkeyIds.length == 1) {
            delete ownerToMonkeyIds[monkeyOwner];
        } else {
            uint256 monkeyIdIndex = 0;
            for (uint256 i = 0; i < monkeyIds.length; i++) {
                if (monkeyIds[i] == _id) {
                    monkeyIdIndex = i;
                    break;
                }
            }

            monkeyIds[monkeyIdIndex] = monkeyIds[monkeyIds.length - 1];
            monkeyIds.pop();
        }
        amountBurned++;

        delete monkeys[_id];

        _burn(_id);
    }

    //================================================================================================
    // ATTACK LOGIC
    //================================================================================================

    /**
        @dev called by user to request an attack on a monkey
        @notice requires that the caller is the owner of the monkey
        @notice requires that the monkey is not on cooldown
        @notice requires that the caller is an EOA (not a contract)
        @notice generates random number and calls _completeAttack
     */
    function requestAttack(
        uint32 _monkeyId
    ) external payable nonReentrant returns (uint256) {
        // cant call if request is already pending
        // needs to have one monkey in wallet to attack

        if (ownerOf(_monkeyId) != msg.sender) {
            revert NotOwnerOfMonkey();
        }

        if (!monkeyAttackIsOpen) {
            revert AttacksAreClosed();
        }

        // [!] check if caller is an EOA (optional - review)
        if (msg.sender != tx.origin) {
            revert EOAsOnly(msg.sender);
        }

        //enforce cooldown, set last attack timestamp at end of function with other mappings...
        if (getMonkeyCooldownSecondsRemaining(_monkeyId) > 0) {
            revert AttackOnCooldown();
        }

        //set that the monkey has attempted an attack
        monkeys[_monkeyId].hasAttacked = true;

        //set new last attack timestamp
        monkeys[_monkeyId].lastAttackTimestamp = uint32(block.timestamp);

        uint256 randomNumber = IRandomizer(config.randomizerAddress())
            .getRandomNumber(msg.sender, block.timestamp, requestNonce);

        _completeAttack(_monkeyId, randomNumber);
        ++requestNonce;
    }

    //------------------------------------------------------------------------------------------------
    // ATTACK-RELATED PRIVATE FUNCTIONS
    //------------------------------------------------------------------------------------------------

    function _completeAttack(uint256 _monkeyId, uint256 _randomNumber) private {
        //reveal random number and perform attack

        //perform attack
        MonkeyEntry storage monkey = monkeys[_monkeyId];

        uint256 verdict = _getAttackVerdict(_randomNumber);
        address attackSender = msg.sender;

        //carry out actions based on attackVerdict / values defined above
        if (verdict == 1) {
            IStolenPool(config.bananStolenPoolAddress()).attack(
                attackSender,
                monkey.tier,
                _monkeyId
            ); //input what stolen pool needs to calculate attack size
            emit AttackResult(
                _monkeyId,
                attackSender,
                "Attack succeeded. No HP Lost."
            );
        } else if (verdict == 2) {
            //subtract health points
            _manageMonkeyHealthPoints(_monkeyId);
            emit AttackResult(
                _monkeyId,
                attackSender,
                "Attack failed. 1 HP Lost."
            );
        } else {
            revert InvalidAttackVerdict(verdict);
        }
    }

    /**
     *  @dev subtracts health points from monkey, and burns it if it reaches 0 health points
     */
    function _manageMonkeyHealthPoints(uint256 _monkeyId) private {
        MonkeyEntry storage monkey = monkeys[_monkeyId];
        monkey.healthPoints -= monkeyAttackHpDeductionAmount;
        emit MonkeyHealthPointsUpdated(_monkeyId, monkey.healthPoints);
        if (monkey.healthPoints == 0) {
            _burnMonkey(_monkeyId);
        }
    }

    /**
     * @dev outputs a verdict based on the random number and monkey hit rate
     */
    function _getAttackVerdict(
        uint256 _randomNumber
    ) private view returns (uint256) {
        uint256 verdict;
        uint256 randValModAttackSuccess = _randomNumber %
            PERCENTAGE_DENOMINATOR;
        if (randValModAttackSuccess <= monkeyHitRate) {
            verdict = 1;
        } else {
            verdict = 2;
        }
        return verdict;
    }

    //================================================================================================
    // PUBLIC GET FUNCTIONS FOR FRONTEND, ETC.
    //================================================================================================

    function monkeyIdToTier(uint256 _monkeyId) public view returns (uint256) {
        return monkeys[_monkeyId].tier;
    }

    function monkeyIdToHealthPoints(
        uint256 _monkeyId
    ) public view returns (uint256) {
        return monkeys[_monkeyId].healthPoints;
    }

    function monkeyIdToLastAttackTimestamp(
        uint256 _monkeyId
    ) public view returns (uint256) {
        return monkeys[_monkeyId].lastAttackTimestamp;
    }

    function getMonkeyIdsByOwner(
        address _monkeyOwner
    ) public view returns (uint256[] memory) {
        return ownerToMonkeyIds[_monkeyOwner];
    }

    function getMonkeyHealthPoints(
        uint256 _monkeyId
    ) public view returns (uint256) {
        return monkeys[_monkeyId].healthPoints;
    }

    function getMonkeyHasAttacked(
        uint256 _monkeyId
    ) public view returns (bool) {
        return monkeys[_monkeyId].hasAttacked;
    }

    function getMonkeyCooldownSecondsRemaining(
        uint256 _monkeyId
    ) public view returns (uint256) {
        MonkeyEntry storage monkey = monkeys[_monkeyId];
        if (monkey.lastAttackTimestamp == 0) {
            return 0;
        } else {
            //this should never revert. if it does, it means the monkeyIdToLastAttackTimestamp[_monkeyId] is somehow in the future, which should be impossible
            return
                monkeyAttackCooldownSeconds >
                    (block.timestamp - monkey.lastAttackTimestamp)
                    ? monkeyAttackCooldownSeconds -
                        (block.timestamp - monkey.lastAttackTimestamp)
                    : 0;
        }
    }

    function getSecondsUntilNextBatchStarts() public view returns (uint256) {
        //number of batches since start time
        uint256 numBatchesSincestartTimestamp = Math.mulDiv(
            (block.timestamp - startTimestamp),
            1,
            monkeyMintSecondsBetweenBatches
        );

        // get the number of seconds that have passed since the start of the last batch, then seconds until next batch starts
        uint256 secondsSinceLastBatchEnded = (block.timestamp -
            startTimestamp) -
            Math.mulDiv(
                numBatchesSincestartTimestamp,
                monkeyMintSecondsBetweenBatches,
                1
            );
        uint256 secondsUntilNextBatchStarts = monkeyMintSecondsBetweenBatches -
            secondsSinceLastBatchEnded;

        return secondsUntilNextBatchStarts;
    }

    function getNumberOfRemainingMintableMonkeys()
        public
        view
        returns (uint256)
    {
        uint256 batchNumber = getBatchNumber();
        return
            batchNumberToNumRerolls[batchNumber] +
            monkeyBatchSize -
            batchNumberToAmountMinted[batchNumber];
    }

    function getBatchNumber() public view returns (uint256) {
        // get number of batches that have passed since the first batch
        uint256 numBatchesSincestartTimestamp = Math.mulDiv(
            (block.timestamp - startTimestamp),
            1,
            monkeyMintSecondsBetweenBatches
        );

        return numBatchesSincestartTimestamp;
    }

    //================================================================================================
    // SETTERS (those not handled by the config manager contract via structs)
    //================================================================================================

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function setConfigManagerAddress(
        address _configManagerAddress
    ) external onlyOwner {
        config = IConfig(_configManagerAddress);
    }

    modifier onlyConfig() {
        if (msg.sender != address(config)) {
            revert CallerIsNotConfig();
        }
        _;
    }

    function setMonkeyMintIsOpen(bool _monkeyMintIsOpen) external onlyConfig {
        monkeyMintIsOpen = _monkeyMintIsOpen;
    }

    function setMonkeyBatchSize(uint16 _monkeyBatchSize) external onlyConfig {
        monkeyBatchSize = _monkeyBatchSize;
    }

    function setMonkeyMintSecondsBetweenBatches(
        uint32 _monkeyMintSecondsBetweenBatches
    ) external onlyConfig {
        monkeyMintSecondsBetweenBatches = _monkeyMintSecondsBetweenBatches;
    }

    function setMonkeyMaxPerWallet(
        uint8 _monkeyMaxPerWallet
    ) external onlyConfig {
        monkeyMaxPerWallet = _monkeyMaxPerWallet;
    }

    function setMonkeyMintPriceInBanans(
        uint128 _monkeyMintPriceInBanans
    ) external onlyConfig {
        monkeyMintPriceInBanans = _monkeyMintPriceInBanans;
    }

    function setMonkeyMintBananFeePercentageToBurn(
        uint16 _monkeyMintBananFeePercentageToBurn
    ) external onlyConfig {
        monkeyMintBananFeePercentageToBurn = _monkeyMintBananFeePercentageToBurn;
    }

    function setMonkeyMintBananFeePercentageToStolenPool(
        uint16 _monkeyMintBananFeePercentageToStolenPool
    ) external onlyConfig {
        monkeyMintBananFeePercentageToStolenPool = _monkeyMintBananFeePercentageToStolenPool;
    }

    function setMonkeyMintTier1Threshold(
        uint16 _monkeyMintTier1Threshold
    ) external onlyConfig {
        monkeyMintTier1Threshold = _monkeyMintTier1Threshold;
    }

    function setMonkeyMintTier2Threshold(
        uint16 _monkeyMintTier2Threshold
    ) external onlyConfig {
        monkeyMintTier2Threshold = _monkeyMintTier2Threshold;
    }

    function setMonkeyHP(uint8 _monkeyHP) external onlyConfig {
        monkeyHP = _monkeyHP;
    }

    function setMonkeyHitRate(uint16 _monkeyHitRate) external onlyConfig {
        monkeyHitRate = _monkeyHitRate;
    }

    function setMonkeyAttackIsOpen(
        bool _monkeyAttackIsOpen
    ) external onlyConfig {
        monkeyAttackIsOpen = _monkeyAttackIsOpen;
    }

    function setAttackCooldownSeconds(
        uint32 _attackCooldownSeconds
    ) external onlyConfig {
        monkeyAttackCooldownSeconds = _attackCooldownSeconds;
    }

    function setAttackHPDeductionAmount(
        uint8 _attackHPDeductionAmount
    ) external onlyConfig {
        monkeyAttackHpDeductionAmount = _attackHPDeductionAmount;
    }

    function setAttackHPDeductionThreshold(
        uint16 _attackHPDeductionThreshold
    ) external onlyConfig {
        monkeyAttackHpDeductionThreshold = _attackHPDeductionThreshold;
    }

    //================================================================================================
    // ERC721 OVERRIDES
    //================================================================================================

    //erc721 overrides
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public pure override {
        revert TisSoulbound();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public pure override {
        revert TisSoulbound();
    }

    // overrides with uri assigned based on tier
    function tokenURI(
        uint256 _id
    ) public view override returns (string memory) {
        return monkeys[_id].tokenURI;
    }

    //=========================================================================
    // WITHDRAWALS
    //=========================================================================

    function withdrawERC20FromContract(
        address _to,
        address _token
    ) external onlyOwner {
        bool os = IERC20(_token).transfer(
            _to,
            IERC20(_token).balanceOf(address(this))
        );
        if (!os) {
            revert ForwardFailed();
        }
    }

    function withdrawEthFromContract() external onlyOwner {
        address out = config.treasuryAddress();
        require(out != address(0));
        (bool os, ) = payable(out).call{value: address(this).balance}("");
        if (!os) {
            revert ForwardFailed();
        }
    }
}
