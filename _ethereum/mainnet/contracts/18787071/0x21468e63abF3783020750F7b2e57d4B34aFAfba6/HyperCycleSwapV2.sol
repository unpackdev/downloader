// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721Enumerable.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IHYPCSwapV2.sol";
import "./IHYPC.sol";

/**
    @title  HyperCycle SwapV2 contract.
    @author Barry Rowe, David Liendo, Rodolfo Cova
    @notice This contract is an updated version of the c_HyPC/SwapV1 contract for HyperCycle. While the
            original contract allowed a user to swap 2^19 (524288) HyPC (ERC20) for a c_HyPC.19 token
            (ERC721), this contract allows for swapping lower powers of 2 of HyPC (known as the level 
            of the c_HyPC token), to get a correspondingly lower c_HyPC token. As an example swapping 
            2^19 HyPC will give a c_HyPC at level 19, while swapping 2^18 HyPC will give a c_HyPC at 
            level 18, and so on.

            Once HyPC is swapped for a c_HyPC NFT, it can assign a number or a string to the token.
            This acts as a way to have HyPC backing an assignment string or number, and will typically
            be used for HyperCycle licenses inside a separate contract. Unlike with the V1 contract
            system, V2's assignments focus on assigning numbers to the c_HyPC tokens instead of strings, 
            so that these assignments can be aggregated together to give more flexibility over the
            amount of backing that is given to a license number. This total backing amount can then
            be returned by the getAssignmentTargetNumber function. Assigning a string can be done 
            instead, though this is primarily a backwards compatibility option for contracts using
            swapV1 interfaces.

            Finally, the actual c_HyPC license numbers themselves are part of a branch of a binary
            tree with integers at each node, using the convention that the left child of a node will
            have two times the number of its parent while the right child has this number plus one.
            Each c_HyPC token is guaranteed to have a unique number in this tree. This impacts the
            swapping logic in that while we can ensure that there will always be enough c_HyPCs that
            can be swapped for in the contract, we can not guarantee that they will be high level
            tokens. For instance, if there are 4096 level 19 tokens, and then 8192 level 18 tokens
            are swapped for, then there would be no more level 19 tokens left to swap for in the
            future since they all needed to be split to create the 8192 level 18 tokens. Even if
            we allowed for merging (ie: unsplitting) of tokens, then we wouldn't be able to guarantee
            that neighboring c_HyPC in the tree would be available to merge together to recreate
            a parent token.

            To help mitigate this, we first have the aggregation of targetNumbers for assignments
            as previously mentioned. Secondly, we also have limits on how many tokens can be split
            down to the lower levels at a time, with only at most `LEVEL_LIMIT` amount of tokens being 
            allowed on a level after a splitting operation. In order to fill up more tokens inside
            the contract at that level then those tokens would have to be swapped with HyPC. This 
            means that to fill up level 18 for instance with 8192 tokens, then a user would have 
            to lock away nearly the entire supply of HyPC (2^31) into the swap contract itself, 
            all at once.

            Finally, to help with reducing the number of transactions needed to fill up the levels
            array (and thereby available tokens to be swapped), by default, the tokens available
            to be swapped for on a given level will only be minted by the contract when a user
            asks to swap for a given token. So, the root level 19 tokens when added to the contract
            via the addRootToken call, are in actuality only allocated for that level and are not
            physically minted into an actual ERC721 token until they are actually swapped for with
            a swap call.
*/

/* Modifier Errors */
///@dev Error for when requiring the owner of the tokenNumber to call the function.
error SenderMustOwnToken();
///@dev Error for when trying to interact with levels lower than MIN_LEVEL.
error TokenLevelTooLow();
///@dev Error for when trying to interact with levels higher than MAX_LEVEL.
error TokenLevelTooHigh();

///@dev Error for when a virtual/real token is not held by the contract at the given level.
error InvalidTokenLevelIndex();
///@dev Error for when trying to get burn data from a non-burned token.
error TokenNotBurned();
///@dev Error for when trying to use a token that's not yet minted.
error TokenNotMinted();

/* Constructor Errors */
///@dev Error when deploying a contract with a zero address token.
error InvalidToken();
///@dev Error for when deploying a contract with a startingNumber of 0.
error InvalidStartingNumber();
///@dev Error for when deploying a contract with the endingNumber less than the startingNumber.
error InvalidEndingNumber();
///@dev Error for when deploying a contract with the endingNumber greater or equal to 2*startingNumber.
error InvalidNumberRange();


/* addRootToken Errors*/
///@dev Error for when trying to add a root token to the contract past the endRootNumber.
error TooManyRootTokens();

/* splitHeldToken Errors */
///@dev Error for when skipLevels during the split call is 0.
error SkipLevelsMustBePositive();
///@dev Error for when trying to split a token beyond the MIN_LEVEL limit.
error TokenLevelTooLowToSplit();
///@dev Error for when trying to split a token and the next level has too many tokens already.
error CreatingTooManyTokens();
///@dev Error for when skipLevels is too large.
error SkipLevelsTooLarge();


contract HyperCycleSwapV2 is ERC721Enumerable, ERC721Holder, Ownable, ReentrancyGuard, IHYPCSwapV2 {
    /// @dev The HyPC ERC20 contract
    IHYPC private immutable _hypcToken;

    /** @dev The soft limit of how many tokens to be created at a level.
    *   The limit is soft since the split call will only add at most this number
    *   of tokens at the given limit. The number of tokens can be increased
    *   beyond this number through redemptions.
    */
    uint256 public constant LEVEL_LIMIT = 16;

    /// @dev The level for created root tokens.
    uint256 public constant MAX_LEVEL = 19;

    /// @dev The lowest level token that can be created.
    uint256 public constant MIN_LEVEL = 10;

    /// @dev The number of decimals of the HyPC token.
    uint256 public constant SIX_DECIMALS = 10 ** 6;

    /// @dev The token data storing the assignment data for each c_HyPC.
    struct TokenData {
        string assignedString;
        uint256 assignedNumber;
        uint256 level;
        bool minted;
    }

    struct RootData {
        /// @dev The first token number to be added
        uint256 startRootNumber;
        /// @dev The next token to be added to the contract from the addRootTokens call.
        uint256 currentRootNumber;
        /// @dev The last root token to be created, inclusive.
        uint256 endRootNumber;
    }

    /// @dev Main mapping for token data of each cHyPC token.
    mapping(uint256 => TokenData) public nftTokens;

    /// @dev The aggregated amount of HyPC tokens backing a given assignedNumber.
    mapping(uint256 => uint256) public assignedNumbers;

    /// @dev The aggregated amount of HyPC tokens backing a given assignedString.
    mapping(string => uint256) public assignedStrings;
   
    /// @dev The last block time that assignNumber/assignString function was called for a tokenId.
    mapping(uint256 => uint256) public _lastBlockAssigned;

    /// @dev The list of token numbers available at different levels.
    mapping(uint256 => uint256[]) public levels;

    /// @dev Backwards compatibility with SwapV1 contract integrations that used the
    ///      nfts[0] element to get the token to be returned from a swap call.
    uint256[] public nfts;

    /// @dev global root token metadata
    RootData private _rootData;

    /// @dev The total HyPC locked into this contract from swaps.
    uint256 public totalLocked;

    //Events
    /// @dev   The event for when adding a new rootToken to level 19.
    /// @param rootNumber: The token number being added.
    event AddRootToken(uint256 rootNumber);

    /// @dev   The event for splitting a token from a parent level to a sub-level.
    /// @param tokenNumber: The token itself being split down.
    /// @param level: The level of the tokenNumber token.
    /// @param skipLevels: The number of levels below the tokenNumber level for the new tokens.
    ///                    Two to the power of this number is the number of tokens created.
    event SplitHeldTokens(uint256 tokenNumber, uint256 level, uint256 skipLevels);

    /// @dev   The event for swapping HyPC for a c_HyPC token.
    /// @param tokenNumber: The tokenNumber swapped for.
    /// @param level: The level of c_HyPC token swapped for.
    /// @param hypcAmount: The amount of HyPC locked for this swap.
    event Swap(uint256 tokenNumber, uint256 level, uint256 hypcAmount);

    /// @dev   The event for redeeming a c_HyPC token for HyPC token.
    /// @param level: The level of c_HyPC token redeemed.
    /// @param tokenNumber: The tokenNumber redeemed.
    /// @param hypcAmount: The amount of HyPC unlocked for this redemption.
    event Redeem(uint256 level, uint256 tokenNumber, uint256 hypcAmount);

    /// @dev   The event for assigning a target number to a c_HyPC token.
    /// @param tokenNumber: The token being given the assignment.
    /// @param targetNumber: The number being assigned to this token.
    /// @param backingAmount: The amount of backing HyPC used in this assignment.
    /// @param totalAmount: The total amount assigned to this targetNumber now.
    event AssignNumber(uint256 tokenNumber, uint256 targetNumber, uint256 backingAmount, uint256 totalAmount);

    /// @dev   The event for assigning a target string to a c_HyPC token.
    /// @param tokenNumber: The token being given the assignment.
    /// @param targetString: The string being assigned to this token.
    /// @param backingAmount: The amount of backing HyPC used in this assignment.
    event AssignString(uint256 tokenNumber, string targetString, uint256 backingAmount);

    /// @dev   The event for burning a token with a string.
    /// @param tokenNumber: The c_HyPC token being burnt.
    /// @param burnString: The string being assigned on burn.
    event Burn(uint256 tokenNumber, string burnString);

    //Modifiers
    /// @dev   Check if the caller owns the given c_HyPC token.
    /// @param tokenNumber: The c_HyPC token ID.
    modifier isOwnerOf(uint256 tokenNumber) {
        if (ownerOf(tokenNumber) != _msgSender()) revert SenderMustOwnToken();
        _;
    }

    /// @dev   Checks if the index is available in the levels array at this level.
    /// @param level: The token height for this check (MIN_LEVEL to MAX_LEVEL).
    /// @param index: The array index to check at this level.
    modifier validHeldToken(uint256 level, uint256 index) {
        if (level < MIN_LEVEL) revert TokenLevelTooLow();
        if (level > MAX_LEVEL) revert TokenLevelTooHigh();
        if (levels[level].length <= index ) revert InvalidTokenLevelIndex();
        _;
    }

    /// @dev   Checks if this tokenNumber has been minted and then burned.
    /// @param tokenNumber: The c_HyPC token ID.
    modifier isMintedAndBurned(uint256 tokenNumber) {
        if (_exists(tokenNumber) || !nftTokens[tokenNumber].minted) revert TokenNotBurned();
        _;
    }

    /// @dev   Checks if this tokenNumber has been minted.
    /// @param tokenNumber: The c_HyPC token ID.
    modifier isMinted(uint256 tokenNumber) {
        if (!nftTokens[tokenNumber].minted) revert TokenNotMinted();
        _;
    }

    /**
        @dev   The constructor takes in the HyPC token, the starting root c_HyPC number
               and the ending root c_HyPC numbers to be created. Valid starting and ending
               numbers should be between consecutive powers of 2 (eg: [8,16) ) to ensure all 
               root tokens are at the same level inside the binary tree, however, for token 
               uniqueness it is only required that that the ending number is less than two
               times the starting number.
        @param hypcTokenAddress: The address for the HyPC token contract
        @param startingNumber: The first root c_HyPC to be created.
        @param endingNumber: The last root c_HyPC number that can be created.
    */
    constructor(address hypcTokenAddress, uint256 startingNumber, uint256 endingNumber) ERC721('c_HyPC', 'c_HyPC') {
        if (hypcTokenAddress == address(0)) revert InvalidToken();
        if (startingNumber == 0) revert InvalidStartingNumber();
        if (endingNumber < startingNumber) revert InvalidEndingNumber();
        if (endingNumber >= 2*startingNumber) revert InvalidNumberRange();

        _hypcToken = IHYPC(hypcTokenAddress);
        _rootData.startRootNumber = startingNumber; //67108864;
        _rootData.endRootNumber = endingNumber; //67108864+4095 = 67112959;
        _rootData.currentRootNumber = startingNumber;
    }

    /// @notice Allows the owner of the contract to add more root tokens into the contract.
    ///         This is limited to the owner to allow for future upgrades if needed so a
    ///         later number range can be reserved for a new contract and the ownership
    ///         of this contract transferred to a null address.
    /// @param  tokens: The number of tokenNumbers to add to the highest level (19).
    function addRootTokens(uint256 tokens) external onlyOwner {
        uint256 currentRootNumber = _rootData.currentRootNumber;
        if (tokens > 1+_rootData.endRootNumber - _rootData.startRootNumber) revert TooManyRootTokens();

        //@dev _rootData.endRootNumber is inclusive, so we need to add 1 to it for this check.
        if (currentRootNumber + tokens > _rootData.endRootNumber + 1) revert TooManyRootTokens();

        uint256 endLimit = currentRootNumber+tokens;
        for (uint256 i=currentRootNumber; i < endLimit; i++) {
            levels[MAX_LEVEL].push(i);
            nftTokens[i] = TokenData('', 0, MAX_LEVEL, false);

            emit AddRootToken({
                rootNumber: i
            });
        }

        _rootData.currentRootNumber += tokens;
        _updateNFTArray(MAX_LEVEL);
    }

    /// @notice This splits a token inside the contract (either minted or not yet minted),
    ///         at the given level and index location inside the levels[level] array. The
    ///         skipLevels allows for the created tokens to be fully split down multiple levels
    ///         to avoid taking to do multiple contract calls.
    /// @param  level: The level of the token to split.
    /// @param  skipLevels: The number of levels to split down.
    function splitHeldToken(uint256 level, uint256 skipLevels) external validHeldToken(level, 0) {
        //@dev underflow check
        if (skipLevels > level) revert SkipLevelsTooLarge();

        if (skipLevels == 0) revert SkipLevelsMustBePositive();
        uint256 levelMinusSkipLevels = level-skipLevels;
        if (levelMinusSkipLevels < MIN_LEVEL) revert TokenLevelTooLowToSplit();

        uint256 tokensToCreate = 2 ** skipLevels;
        if (levels[levelMinusSkipLevels].length + tokensToCreate > LEVEL_LIMIT) revert CreatingTooManyTokens();

        uint256[] storage _targetLevel = levels[level];
        //@dev Remove the token at [0] by swapping it with the last element
        uint256 tokenNumber = _targetLevel[0];
        _targetLevel[0] = _targetLevel[_targetLevel.length - 1];
        _targetLevel.pop();
        _updateNFTArray(level);

        if (nftTokens[tokenNumber].minted) {
            _burn(tokenNumber);
        }

        //@dev add new tokens to the lower level.
        uint256 endLimit = tokenNumber*tokensToCreate+tokensToCreate;
        for (uint256 i=tokenNumber*tokensToCreate; i < endLimit; i++) {
            levels[levelMinusSkipLevels].push(i);
            nftTokens[i] = TokenData('', 0, levelMinusSkipLevels, false);
        }

        emit SplitHeldTokens({
            tokenNumber: tokenNumber, 
            level: level, 
            skipLevels: skipLevels
        });
    }

    /// @dev   Internal function that updates the nfts[0] entry for backwards compatibility with
    ///        swapV1 contract callers, like the PoolV1/V2 contracts.
    /// @param level: The level of tokens that was being split, redeemed, or swapped.
    function _updateNFTArray(uint256 level) internal {
        if (level == MAX_LEVEL) {
            if (levels[MAX_LEVEL].length > 0) {
                if (nfts.length == 0) {
                    nfts.push(levels[MAX_LEVEL][0]);
                } else {
                    nfts[0] = levels[MAX_LEVEL][0];
                }
            } else {
                if (nfts.length > 0) {
                    nfts.pop();
                }
            }
        }
    }

    /// @dev   Wrapper around the main _swapV2 call.
    /// @param level: The level of token to swap for.
    function swapV2(uint256 level) external validHeldToken(level, 0) nonReentrant {
        _swapV2(level);
    }

    /// @notice The main swap function. This asks for the token at the index location of the levels[level]
    ///         array. The tokens in this array, while allocated to this level, may not have been minted
    ///         yet (if it was not swapped for previously), so if it wasn't minted yet, the token will
    ///         be minted to the sender, otherwise it will be transferred to them. This call will request
    ///         2^level amount of HyPC to get the corresponding c_HyPC.
    /// @param  level: The level of the token to swap for.
    function _swapV2(uint256 level) internal {
        //accept the HyPC here and deposit into the contract.
        uint256 amount = 2 ** level;
        totalLocked += amount;

        uint256[] storage _targetLevel = levels[level];
        ///@dev Remove the token at [0] by swapping it with the last element
        uint256 tokenNumber = _targetLevel[0];
        _targetLevel[0] = _targetLevel[_targetLevel.length - 1];
        _targetLevel.pop();
        _updateNFTArray(level);

        //Send this token from this contract to the user.
        //If the token wasn't minted yet, mint it, otherwise send it.
        TokenData storage _targetToken = nftTokens[tokenNumber];

        if (_targetToken.minted) {
            _safeTransfer(address(this), _msgSender(), tokenNumber, "");
        } else {
            _targetToken.minted = true;
            _safeMint(_msgSender(), tokenNumber);
        }
        _hypcToken.transferFrom(_msgSender(), address(this), amount * SIX_DECIMALS);

        emit Swap({
            tokenNumber: tokenNumber, 
            level: level, 
            hypcAmount: amount
        });
    }

    /// @notice The function that redeems a c_HyPC token for the amount of tokens that were deposited
    ///         for it.
    /// @param  tokenNumber: The c_HyPC token to be redeemed.
    function redeem(uint256 tokenNumber) external nonReentrant isOwnerOf(tokenNumber) {
        _unassign(tokenNumber);

        uint256 level = nftTokens[tokenNumber].level;
        levels[level].push(tokenNumber);
        _updateNFTArray(level);
        
        uint256 amount = 2 ** level;
        totalLocked -= amount;
        safeTransferFrom(_msgSender(), address(this), tokenNumber);
        _hypcToken.transfer(_msgSender(), amount * SIX_DECIMALS);

        emit Redeem({
            level: level, 
            tokenNumber: tokenNumber, 
            hypcAmount: amount
        });
    }

    //Assigning functions
    /// @notice The function to assign a targetNumber to a c_HyPC token.
    /// @param  tokenNumber: The c_HyPC to be assigned the targetNumber.
    /// @param  targetNumber: The targetNumber to be assigned.
    function assignNumber(uint256 tokenNumber, uint256 targetNumber) external isOwnerOf(tokenNumber) {
        _unassign(tokenNumber);

        if (targetNumber > 0) {

            TokenData storage _targetToken = nftTokens[tokenNumber];
            _targetToken.assignedNumber = targetNumber;
            assignedNumbers[targetNumber] += 2 ** (_targetToken.level);
            
            emit AssignNumber({
                tokenNumber: tokenNumber,
                targetNumber: targetNumber,
                backingAmount: 2 ** (_targetToken.level),
                totalAmount: assignedNumbers[targetNumber]
            });
        }
    }

    /// @notice Wrapper around the _assignString function.
    /// @param  tokenNumber: The c_HyPC to be assigned the targetNumber.
    /// @param  data: The target string to be assigned.
    function assignString(uint256 tokenNumber, string memory data) external isOwnerOf(tokenNumber) {
        _assignString(tokenNumber, data);
    }

    /// @notice The function to assign a targetString to a c_HyPC token. Mainly for backwards
    ///         compatibility with SwapV1 supporting contracts.
    /// @param  tokenNumber: The c_HyPC to be assigned the targetNumber.
    /// @param  data: The target string to be assigned.
    function _assignString(uint256 tokenNumber, string memory data) internal {
        _unassign(tokenNumber);

        TokenData storage _targetToken = nftTokens[tokenNumber];
        _targetToken.assignedString = data;
        assignedStrings[data] += 2 ** (_targetToken.level);

        emit AssignString({
            tokenNumber: tokenNumber,
            targetString: data,
            backingAmount: 2 ** (_targetToken.level)
        });
    }

    /// @notice The function to burn a c_HyPC token with a burn string.
    /// @param  tokenNumber: The c_HyPC to be burned.
    /// @param  data: The burn string to use.
    function burn(uint256 tokenNumber, string memory data) external isOwnerOf(tokenNumber) {
        _assignString(tokenNumber, data);
        _burn(tokenNumber);
        emit Burn(tokenNumber, data);
    }

    /// @dev   Internal function to remove an existing token assignment cleanly.
    /// @param tokenNumber: the c_HyPC token to clear the assignment of.
    function _unassign(uint256 tokenNumber) internal {
        TokenData storage _targetToken = nftTokens[tokenNumber];
        _lastBlockAssigned[tokenNumber] = block.timestamp;

        //if previously assigned, decrease the assignedNumber value
        if (_targetToken.assignedNumber > 0) {
            //unassign the assigned number
            assignedNumbers[_targetToken.assignedNumber] -= 2 ** (_targetToken.level);
            delete _targetToken.assignedNumber;
        }
        //if previously assigned, decrease the assignedNumber value
        if (bytes(_targetToken.assignedString).length > 0) {
            //unassign the assigned string
            assignedStrings[_targetToken.assignedString] -= 2 ** (_targetToken.level);
            delete _targetToken.assignedString;
        }
    }

    // Backwards compatibility for v2 pools
    /// @notice Wrapper around _assignString for backwards compatibility.
    /// @param  tokenNumber: The c_HyPC to be assigned the targetNumber.
    /// @param  data: The target string to be assigned.
    function assign(uint256 tokenNumber, string memory data) external isOwnerOf(tokenNumber) {
        //assign a string
        _assignString(tokenNumber, data);
    }

    /// @notice Wrapper around the _swapV2 function to swap for the first level 19 token,
    ///         for backwards compatibility.
    function swap() external nonReentrant validHeldToken(MAX_LEVEL, 0) {
        _swapV2(MAX_LEVEL);
    }

    //Getters
    /// @notice Copy of getAssignmentString. Mainly for backwards compatibility.
    /// @dev    Copies the getAssignmentString code to lower gas usage
    /// @param  tokenNumber: The c_HyPC token to get the assignment of.
    function getAssignment(uint256 tokenNumber) external view returns (string memory) {
        return _getAssignmentString(tokenNumber);
    }

    /// @notice Function to get the number of tokens available to be swapped for at a given level.
    /// @param  level: The level to get the number of tokens available to be swapped for.
    function getLevelLength(uint256 level) external view returns (uint256) {
        return levels[level].length;
    }

    /// @notice Function to get the tokenId to be swapped for at level and index.
    /// @param  level: The level of the token we want to swap for.
    /// @param  index: The index inside the level array that we want to swap for.
    function getAvailableToken(uint256 level, uint256 index) external view validHeldToken(level, index) returns (uint256) {
        return levels[level][index];
    }

    /// @notice Function to get the assigned string to a c_HyPC token. Mainly for backwards
    ///         compatibility.
    /// @param  tokenNumber: The c_HyPC token to get the assignment of.
    function getAssignmentString(uint256 tokenNumber) external view returns (string memory) {
        return _getAssignmentString(tokenNumber);
    }

    function _getAssignmentString(uint256 tokenNumber) internal view returns (string memory) {
        return nftTokens[tokenNumber].assignedString;
    }



    /// @notice Function to get the assigned number to a c_HyPC token.
    /// @param  tokenNumber: The c_HyPC token to get the assignment of.
    function getAssignmentNumber(uint256 tokenNumber) external view returns (uint256) {
        return nftTokens[tokenNumber].assignedNumber;
    }

    /// @notice Function to get total backing amount for this targetNumber from assignments.
    /// @param  targetNumber: The target number to get the total backing amount of.
    function getAssignmentTargetNumber(uint256 targetNumber) external view returns (uint256) {
        return assignedNumbers[targetNumber];
    }

    /// @notice Function to get total backing amount for this targetString from assignments.
    /// @param  targetString: The target string to get the total backing amount of.
    function getAssignmentTargetString(string memory targetString) external view returns (uint256) {
        return assignedStrings[targetString];
    }

    /// @notice Function to get the last block that this token was assigned at.
    ///
    function getLastAssigned(uint256 tokenId) external view returns (uint256) {
        return _lastBlockAssigned[tokenId];
    }

    /// @notice Function to get the burn data for a burned c_HyPC token.
    /// @param  tokenNumber: The c_HyPC token to get the burn data of.
    function getBurnData(uint256 tokenNumber) external view isMintedAndBurned(tokenNumber) returns (string memory) {
        return nftTokens[tokenNumber].assignedString;
    }

    /// @notice Function to get the token level for a given tokenNumber.
    /// @param  tokenNumber: The c_HyPC token to get the level of.
    function getTokenLevel(uint256 tokenNumber) external view isMinted(tokenNumber) returns (uint256) {
        return nftTokens[tokenNumber].level;
    }
}
