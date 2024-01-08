// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//@version 0.3.0

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./VRFConsumerBase.sol";

contract MFMT_VRFBingo_WLv2 is ERC721Enumerable, Ownable, ReentrancyGuard, VRFConsumerBase {
    
    //Team
    address tm0 = 0x5d9f5a2d4B8AA3C4f40d42CAf0fC492A6B0Beed3;   //0
    address tm1 = 0xb4ce5faeB2228Bf48Ea7f5545eA0CD5d53F95a16;   //1
    address tm2 = 0xa6119DC1F2Fc434130A8b3724F09DFd27ACcF599;   //2
    address tm3 = 0xf83ECDa13505d20E21AB0edcF1A9883477D8dc64;   //3
    
    //Presale verification Setup
    using ECDSA for bytes32;
    address signerAdmin = 0x88EbCC12aa77674E0795F2AC0E4e3e418391E65c;
    bytes32 private hashSecret = 0xb891fdff1f58d05a6ba75ae7e0fc9d95bf50b9397e86d863f9904a82ae4dd7bd;
    
    //Mainnet VRF Setup
    address LinkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address VRFCoordinator = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    bytes32 internal keyHash;
    uint internal fee;

    /* Player Reward Setup */

    //Minted token ID to player
    mapping (uint => address) public mintToAddress;

    //Batches to entries of tokenIds
    mapping (uint => uint[]) private mintEntries;

    //Minted token IDs to reward status
    enum ChosenStatus { nulled, pending, wasChosen }
    ChosenStatus chosen;
    mapping (uint => ChosenStatus) public chosenMints;

    //Past rewarded token IDs for accounting
    mapping (uint => bool) public pastRewardMints;

    /* Accounting events */
    event RequestedRandom(uint currentTokenId, bytes32 requestId);
    event WinnerChosen(uint batch, uint tokenId, uint windex);
    event RewardPayed(address winner, uint tokenId);

    /* ERC721 Sale Setup */
    string baseTokenURI;

    uint public constant MAX_TOKENS = 10_000;                   //10,000 Tokens
    uint public constant TXN_MINT_LIMIT = 19;                   //19 per txn, 950000000 gwei
    uint public mintPrice = 0.05 ether;                         //0.05 ether, 50000000 gwei
    uint private reward = mintPrice * 10;                       //Reward 10x

    /* Batching Rate Setup */
    uint private constant MAGIC_NUMBA = 25;                     //How many randomNumbas via expansion
    uint private constant BATCH_SIZE = 40;                      //Number of tokens in a batch
    uint constant ROUNDS_PER_CALL = 5;                          //Number of batches processed per fulfillment.
    uint public currentBatch = 1;                               //Current batch pointer
    uint public nextProcBatch = 1;                              //Last time pointers equivalent

    bool public preSaleOn;                                      //default false, toggle to open presale first
    bool public salePaused = true;                              //set true, toggle to open public sale next

    constructor(string memory _baseTokenURI, string memory name, string memory symbol) payable
    VRFConsumerBase(VRFCoordinator, LinkToken)
    ERC721(name, symbol)
    {
      setBaseURI(_baseTokenURI);
      keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
      fee = 2 * 10 ** 18;                                       //2 LINK
    }
    
    function presaleMint(
        uint _amount,
        bytes32 _payload,
        bytes memory _signature,
        uint _nonce
    ) external payable {
        require( preSaleOn == true,                         "PNO" );
        require( hashTransaction(_nonce, msg.sender) == _payload, "HCF" );
        require( matchSignerAdmin(_payload, _signature),    "USP" );
        _mint(_amount);
    }
    
    function publicMint(uint _amount) external payable {
        require( !salePaused,                               "CIP" );
        _mint(_amount);
    }

    function _mint(uint _amount) internal {
        //Local version of state
        uint _supply = totalSupply();
        uint _batchCounter = currentBatch;

        require( _supply + _amount <= MAX_TOKENS,           "XTS" );
        require( _amount <= TXN_MINT_LIMIT,                 "XTL" );
        require( msg.value >= mintPrice * _amount,          "WEA" );

        for(uint i; i < _amount; i++){
            uint tokenId = _supply + i;

            _safeMint(msg.sender, tokenId);                  //Optimistic Mint
            mintToAddress[tokenId] = msg.sender;             //Account mint to player
            chosenMints[tokenId] = ChosenStatus.pending;     //Account status
            mintEntries[_batchCounter].push(tokenId);        //Assign it to a batch within Entries mapping, keyed by entry offset.

            //Check our batch fullness
            if (mintEntries[_batchCounter].length == BATCH_SIZE) {
               /**
                 * @dev Check if batch is filled &
                 * issue a VRF call if enough to assess.
                */

                if (_batchCounter % ROUNDS_PER_CALL == 0 ) {
                    bytes32 _receipt = callVRF();
                    //Log receipt for the current supply/tokenId
                    emit RequestedRandom(_supply, _receipt);
                }
                //Next Batch
                _batchCounter++;
            } //call check
        } //mint loop
        //store result of local loop processing
        currentBatch = _batchCounter;
    }

    function callVRF() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee);
        return requestRandomness(keyHash, fee);
    }

    //In case of stuckage, call VRF direct and emit event
    function nudgeVRF() external onlyOwner {
        bytes32 _receipt = callVRF();
        uint _supply = totalSupply();
        //Log receipt
        emit RequestedRandom(_supply, _receipt);
    }

    //In case of stuckage, nudge with last randomNumba from calldata
    //Users can verify this was correct on-chain
    function nudgeChoose(uint randomNumba) external onlyOwner {
        require( nextProcBatch <= (MAX_TOKENS / BATCH_SIZE),        "FBR");
        require( mintEntries[nextProcBatch].length == BATCH_SIZE,   "NBR");
        expandedAndChoose(randomNumba);
    }

    //200k gas maximum execution
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        expandedAndChoose(randomness);
    }

    function expandedAndChoose(uint randomness) internal {
        uint[] memory expandedVals = expandRanged(randomness, MAGIC_NUMBA);
        chooseWinners(expandedVals);
    }

    function expandRanged(uint _randomNumba, uint _n) internal pure returns (uint[] memory expandedValues) {
    //1-dim fixed-size array with length MAGIC_NUMBA.
    expandedValues = new uint[](_n);
    for (uint i = 0; i < _n; i++) {
        //BATCH_SIZE is the modulo for ranged expansion (0..BATCH_SIZE -1)
        expandedValues[i] = uint(keccak256(abi.encode(_randomNumba, i))) % (BATCH_SIZE -1);
    }
    return expandedValues;
    }

    /**
    * For each round, process a full batch
    * locating winning tokens with the random expanded values as indices,
    * then keeping account of winners for later claim.
    **/
    function chooseWinners(uint[] memory expandedVals) private {
        //Local version of state
        uint expand_length = expandedVals.length;
        uint _procBatch = nextProcBatch;
        //5% of mints
        uint _numerator = BATCH_SIZE/20;
        uint _start;
        uint _end;

        //Process the next full batches for winners
        //Runs ROUNDS_PER_CALL times from 0.
        for (uint b = 0; b < ROUNDS_PER_CALL; b++) {
            uint[] memory slicedRandoms = new uint[](_numerator);
            uint this_batch = _procBatch + b;

            //Take a chunk and move along the list by the offset each loop
            if (b == 0) {
                _start = expand_length - _numerator;
                _end = expand_length - 1;
            } else {
                _start = _start - _numerator;
                _end = _end - _numerator;
            }

            //Populate target indices - redo with exampleBytes[:5] to save on loop
            uint r = 0;
            for (uint s = _start; s <= _end; s++ ) {
                slicedRandoms[r] = expandedVals[s];
                r++;
            }

            for (uint i = 0; i < _numerator; i++) {
                uint winDex = slicedRandoms[i];
                //Find which tokenID is in this position
                uint winToken = mintEntries[this_batch][winDex];

                //Verify token entry not already chosen or been claimed in past
                if (chosenMints[winToken] == ChosenStatus.wasChosen
                    || pastRewardMints[winToken] == true) {
                    //Offset the double-pick
                    winToken = mintEntries[this_batch][(BATCH_SIZE -1) - winDex]; //Always valid index!
                }

                //Set token as winner & emit Event
                chosenMints[winToken] = ChosenStatus.wasChosen;
                emit WinnerChosen(this_batch, winToken, winDex);
            }
            if (_start == 0) break; //end of values, do not slice further.
        } //end batch loop

        nextProcBatch = _procBatch + ROUNDS_PER_CALL; //store result of local processing, ROUNDS_PER_CALL
    }

    function getMintStatus(uint _tokenId) external view returns (ChosenStatus) {
        return chosenMints[_tokenId];
    }

    function getMintEntry(uint batch, uint entry) external view returns (uint _tokenId) {
        return mintEntries[batch][entry];
    }

    function walletOfTokenOwner(address _tokenOwner) external view returns(uint[] memory) {
        uint tokenCount = balanceOf(_tokenOwner);

        uint[] memory tokensId = new uint[](tokenCount);
        for(uint i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_tokenOwner, i);
        }
        return tokensId;
    }

    /**
     * Player-initiated withdrawal
     * Array of token IDs checked against accounting structures
     * Pays out here if pass, revert early or skip on funny business
     */
    function withdrawReward(uint[] memory _tokenIds) external nonReentrant() {
        //Local version of state
        uint _length = _tokenIds.length;
        uint _reward = reward;

        require( msg.sender == tx.origin,                       "NDC");
        require( address(this).balance >= _reward * _length,    "P2L");
        //For each of the players tokens
        for (uint i = 0; i < _length; i++) {
            uint _tokenId = _tokenIds[i];
            //Must be original minter, otherwise skip
            if (msg.sender != mintToAddress[_tokenId]) continue;
            //Must be marked winner and not previously claimed
            if (chosenMints[_tokenId] == ChosenStatus.wasChosen && pastRewardMints[_tokenId] == false ) {
                //Optimistic accounting for status, reward history separately.
                pastRewardMints[_tokenId] = true;

                //address _winner = mintToAddress[_tokenId];
                //Pay out the reward to winner
                payable(msg.sender).transfer(_reward);
                //Log payout event
                emit RewardPayed(msg.sender, _tokenId);
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function pubSaleToggle() external onlyOwner {
        preSaleOn = false;
        salePaused = !salePaused;
    }

    function preSaleToggle() external onlyOwner {
        preSaleOn = !preSaleOn;
    }

    /**
    * Contract balance payout to team via owner withdrawal
    */
    function withdrawProceeds() external onlyOwner {
        uint cincoCut = address(this).balance/20;
        uint quinceCut = cincoCut * 3;
        uint cuarentaCut = (address(this).balance/5) * 2;

        //Fallthrough payouts
        payable(tm0).send(quinceCut);                           //15%
        payable(tm1).send(cincoCut);                            //5%
        payable(tm2).send(cuarentaCut);                         //40%
        payable(tm3).send(cuarentaCut);                         //40%
        payable(msg.sender).transfer(address(this).balance);    //Remainder, if any failures, to owner
    }

    /**
     * @dev Recover any ERC20 tokens sent to contract, in this case LINK
     */
    function withdrawTokens(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0));

        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    /** Presale offline signing verification **/
    function hashTransaction(uint _nonce, address _sender) internal view returns (bytes32) {
        bytes32 _hash = keccak256(abi.encode(_sender, hashSecret, _nonce)).toEthSignedMessageHash();
    	return _hash;
	}

	function matchSignerAdmin(bytes32 _payload, bytes memory _signature) internal view returns (bool) {
		return signerAdmin == _payload.recover(_signature);
	}
}