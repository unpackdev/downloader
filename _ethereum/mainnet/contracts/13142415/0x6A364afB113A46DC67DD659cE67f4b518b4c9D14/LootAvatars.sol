// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./VRFConsumerBase.sol";
import "./ERC721Pausable.sol";


interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract LootAvatars is VRFConsumerBase, ReentrancyGuard, ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    //Loot Contract
    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface lootContract = LootInterface(lootAddress);

    Counters.Counter private _tokenNumTracker;

    uint256 public constant MAX_ELEMENTS = 8000;
    uint256 public constant LAST_WINNER_OF_TOKEN_NUM = 7000;
    uint256 public constant ELEMENTS_PER_TIER = 1000;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public constant START_PRICE = 0 ether;
    uint256 public constant PRICE_CHANGE_PER_TIER = 0.05 ether; // price not change
    uint256 public constant BLOCKS_PER_MONTH = 199384; // assume each block is 13s, 1 month = 3600 * 24 * 30 / 13

    address public devAddress;
    string public baseTokenURI;
    bytes32 public immutable baseURIProof;

    uint256 public jackpot;
    uint256 public jackpotRemaining;
    address public phase1Winner;
    bool public phase1JackpotClaimed = false;
    uint256 public phase2StartBlockNumber;
    uint256 public phase2EndBlockNumber;
    uint256 public phase2WinnerTokenID;
    bool public phase2Revealed = false;
    bool public phase2JackpotClaimed = false;

    bytes32 internal chainlinkKeyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    bytes32 internal chainlinkRequestID;
    uint256 private chainlinkFee = 2e18;

    event CreateAvatar(uint256 indexed id);
    event WinPhase1(address addr);
    event WinPhase2(uint256 tokenID);
    event ClaimPhase1Jackpot(address addr);
    event ClaimPhase2Jackpot(address addr);
    event Reveal();
    event RevealPhase2();

    struct State {
        uint256 maxElements;
        uint256 maxByMint;
        uint256 startPrice;
        uint256 elementsPerTier;
        uint256 jackpot;
        uint256 jackpotRemaining;
        uint256 phase1Jackpot;
        uint256 phase2Jackpot;
        address phase1Winner;
        uint256 phase2EndBlockNumber;
        uint256 phase2WinnerTokenID;
        bool phase2Revealed;
        uint8 currentPhase;
        uint256 currentTier;
        uint256 currentPrice;
        uint256 totalSupply;
        bool paused;
    }

    /**
     * @dev base token URI will be replaced after reveal
     *
     * @param baseURI set placeholder base token URI before revealing
     * @param dev dev address
     * @param proof final base token URI to reveal
     */
    constructor(
        string memory baseURI,
        address dev,
        bytes32 proof
    )
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
        ERC721("LootAvatars", "LAV")
    {
        require(dev != address(0), "Zero address");
        baseTokenURI = baseURI;
        devAddress = dev;
        baseURIProof = proof;
    }

    // ******* modifiers *********

    modifier saleIsOpen {
        require(_totalSupply() < MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    modifier saleIsEnd {
        require(_totalSupply() >= MAX_ELEMENTS, "Sale not end");
        _;
    }

    modifier onlyPhase1Winner {
        require(phase1Winner != address(0), "Zero address");
        require(_msgSender() == phase1Winner, "Not phase 1 winner");
        _;
    }

    modifier onlyPhase2Winner(uint256 tokenID) {
        require(_msgSender() != address(0), "Zero address");
        require(ownerOf(tokenID) == _msgSender(), "Not phase 2 winner");
        _;
    }

    modifier onlyPhase2 {
        require(phase2EndBlockNumber > 0, "Phase 2 not start");
        _;
    }

    modifier onlyPhase2AllowReveal {
        require(phase2EndBlockNumber > 0, "Phase 2 not start");
        require(block.number >= phase2EndBlockNumber, "Phase 2 not end");
        _;
    }

    modifier onlyPhase2Revealed {
        require(phase2Revealed, "Phase 2 not end");
        _;
    }

    // ********* public view functions **********

    /**
     * @notice total number of tokens minted
     */
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @notice current tier, start from 1 to 10
     */
    function tier() public view returns (uint256) {
        return _ceil(totalMint()).div(ELEMENTS_PER_TIER);
    }

    /**
     * @notice get tier price of a specified tier
     *
     * @param tierN tier index, start from 1 to 10
     */
    function tierPrice(uint256 tierN) public pure returns (uint256) {
        require(tierN >= 1, "Out of tier range");
        require(tierN <= MAX_ELEMENTS.div(ELEMENTS_PER_TIER), "Out of tier range");
        return START_PRICE.add(PRICE_CHANGE_PER_TIER.mul(tierN.sub(1)));
    }

    /**
     * @notice get the total price if you want to buy a number of avatars now
     *
     * @param count the number of avatars you want to buy
     */
    function price(uint256 count) public view returns (uint256) {
        uint256 _totalMint = totalMint();
        require(count <= MAX_BY_MINT, "Max count");
        require(_totalMint + count <= MAX_ELEMENTS, "Max limit");
        uint256 _ceilCount = _ceil(_totalMint);
        uint256 _currentTier = _ceilCount.div(ELEMENTS_PER_TIER);
        // calculate count = a + b, a in current tier, b in next tier
        uint256 _currentTierElements = _ceilCount.sub(_totalMint);
        if (count <= _currentTierElements) {
            return tierPrice(_currentTier).mul(count);
        }
        uint256 _price0 = tierPrice(_currentTier).mul(_currentTierElements);
        uint256 _nextTierElements = count.sub(_currentTierElements);
        uint256 _price1 = tierPrice(_currentTier.add(1)).mul(_nextTierElements);
        return _price0.add(_price1);
    }

    /**
     * @notice get all token IDs of CryptoAvatars of a address
     *
     * @param owner owner address
     */
    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokensId;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice get current state
     */
    function state() public view returns (State memory) {
        uint256 currentTier = tier();
        State memory _state = State({
            maxElements: MAX_ELEMENTS,
            maxByMint: MAX_BY_MINT,
            startPrice: START_PRICE,
            elementsPerTier: ELEMENTS_PER_TIER,
            jackpot: jackpot,
            jackpotRemaining: jackpotRemaining,
            phase1Jackpot: jackpot.div(2),
            phase2Jackpot: jackpot.div(2),
            phase1Winner: phase1Winner,
            phase2EndBlockNumber: phase2EndBlockNumber,
            phase2WinnerTokenID: phase2WinnerTokenID,
            phase2Revealed: phase2Revealed,
            currentPhase: phase2EndBlockNumber == 0 ? 1 : 2,
            currentTier: currentTier,
            currentPrice: tierPrice(currentTier),
            totalSupply: _totalSupply(),
            paused: paused()
        });
        return _state;
    }

    // ********* public functions **********

    /**
     * @notice mint avatars with loot
     *
     * @notice extra eth sent will be refunded
     * 
     * @param tokenId loot token id
     */
    function mintWithLoot(uint256 tokenId) public payable nonReentrant saleIsOpen {
        require(tokenId > 0 && tokenId < 8001, "Token ID invalid");
        require(lootContract.ownerOf(tokenId) == _msgSender(), "Not the owner of this loot");
        require(!_exists(tokenId), "This token has already been minted");

        uint256 requiredPrice = price(1);
        require(msg.value >= requiredPrice, "Value below price");
        uint256 refund = msg.value.sub(requiredPrice);
        if (requiredPrice > 0) {
            _transfer(devAddress, requiredPrice.mul(90).div(100));
        }
        _mintOne(_msgSender(), tokenId);
        if (requiredPrice > 0) {
            jackpot = jackpot.add(requiredPrice.mul(10).div(100));
            jackpotRemaining = jackpot;
        }
        if (refund > 0) {
            _transfer(_msgSender(), refund);
        }
    }

    /**
     * @notice mint with multiple loots
     */
    function multiMintWithLoots(uint[] memory tokenIds) public payable nonReentrant saleIsOpen {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 0 && tokenIds[i] < 8001, "Token ID invalid");
            require(lootContract.ownerOf(tokenIds[i]) == _msgSender(), "Not the owner of this loot");
            require(!_exists(tokenIds[i]), "This token has already been minted");
        }

        uint256 requiredPrice = price(tokenIds.length);
        require(msg.value >= requiredPrice, "Value below price");
        uint256 refund = msg.value.sub(requiredPrice);
        if (requiredPrice > 0) {
            _transfer(devAddress, requiredPrice.mul(90).div(100));
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mintOne(_msgSender(), tokenIds[i]);
        }
        if (requiredPrice > 0) {
            jackpot = jackpot.add(requiredPrice.mul(10).div(100));
            jackpotRemaining = jackpot;
        }
        if (refund > 0) {
            _transfer(_msgSender(), refund);
        }
    }

    // ********* public onwer functions **********

    /**
     * @notice set dev address
     */
    function setDev(address dev) public onlyOwner {
        require(dev != address(0), "Zero address");
        devAddress = dev;
    }

    /**
     * @notice reveal the metadata of avatars
     *
     * @notice the baseURI should be equal to the proof when creating contract
     * @notice metadata is immutable from the beginning of the contract
     */
    function reveal(string memory baseURI) public onlyOwner {
        bytes32 proof = keccak256(abi.encodePacked(baseURI));
        require(baseURIProof == proof, "Invalid proof");
        baseTokenURI = baseURI;
        emit Reveal();
    }

    /**
     * @notice pause or unpause the contract
     */
    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    /**
     * @notice reveal the winner token ID of phase 2
     *
     * @notice Chainlink VRF is used to generate the random token ID
     *
     * @dev make sure to transfer LINK to the contract before revealing
     * @dev check chainlinkRequestID in callback
     */
    function revealPhase2() public onlyOwner onlyPhase2AllowReveal {
        require(!phase2Revealed, "Phase 2 revealed");
        chainlinkRequestID = getRandomNumber();
    }

    /**
     * @notice Call incase failed to generate random token ID from chainlink
     *
     * @notice community should check if owner use chainlink to reveal phase 2 jackpot,
     * @notice it's better to add timelock to this action.
     *
     * @notice if we failed to generate random from chainlink, owner should generate random token id
     * @notice in another contract under the governance of community, then manually update the winner token id
     */
    function forceRevealPhase2(uint256 tokenID) public onlyOwner onlyPhase2AllowReveal {
        require(!phase2Revealed, "Phase 2 revealed");
        require(tokenID < MAX_ELEMENTS, "Token id out of range");
        require(_exists(tokenID), "Token ID not exists");
        phase2Revealed = true;
        phase2WinnerTokenID = tokenID;
        emit WinPhase2(tokenID);
    }

    /**
     * @notice Call incase current ipfs gateway broken
     *
     * @notice community should check if owner call reveal method first,
     * @notice it's better to add timelock to this action.
     *
     * @notice IPFS CID should be unchanged
     */
    function forceSetBaseTokenURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /**
     * @notice withdraw the balance except jackpotRemaining
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance.sub(jackpotRemaining);
        require(amount > 0, "Nothing to withdraw");
        _transfer(devAddress, amount);
    }

    /**
     * @notice Requests randomness
     *
     * @dev manually call this method to check Chainlink works well
     */
    function getRandomNumber() public virtual onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK");
        return requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    /**
     * @notice set fee paid for Chainlink VRF
     */
    function setChainlinkFee(uint256 fee) public onlyOwner {
        chainlinkFee = fee;
    }

    // ********* public winner functions **********

    /**
     * @notice claim phase 1 jackpot by phase 1 winner
     */
    function claimPhase1Jackpot() public whenNotPaused onlyPhase1Winner {
        require(!phase1JackpotClaimed, "Phase 1 jackpot claimed");
        require(jackpot > 0, "No jackpot");
        uint256 phase1Jackpot = jackpot.mul(50).div(100);
        require(phase1Jackpot > 0, "No phase 1 jackpot");
        require(jackpotRemaining >= phase1Jackpot, "Not enough jackpot");
        phase1JackpotClaimed = true;
        jackpotRemaining = jackpot.sub(phase1Jackpot);
        _transfer(_msgSender(), phase1Jackpot); // phase 1 winner get 50% of jackpot
        emit ClaimPhase1Jackpot(_msgSender());
    }

    /**
     * @notice claim phase 2 jackpot by phase 2 winner
     */
    function claimPhase2Jackpot() public 
        whenNotPaused
        onlyPhase2
        onlyPhase2Revealed
        onlyPhase2Winner(phase2WinnerTokenID)
    {
        require(!phase2JackpotClaimed, "Phase 2 jackpot claimed");
        require(jackpot > 0, "No jackpot");
        uint256 phase2Jackpot = jackpot.mul(50).div(100);
        require(phase2Jackpot > 0, "No phase 2 jackpot");
        require(jackpotRemaining >= phase2Jackpot, "Not enough jackpot");
        phase2JackpotClaimed = true;
        jackpotRemaining = jackpot.sub(phase2Jackpot);
        _transfer(_msgSender(), phase2Jackpot); // phase 2 winner get 50% of jackpot
        emit ClaimPhase2Jackpot(_msgSender());
    }

    // ****** internal functions ******

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _totalSupply() internal virtual view returns (uint) {
        return _tokenNumTracker.current();
    }

    function _priceChangePerTier() internal virtual pure returns (uint256) {
        return PRICE_CHANGE_PER_TIER;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @dev check requestId, callback is in a sperate transaction
     * @dev do not revert in this method, chainlink will not retry to callback if reverted
     * @dev to prevent chainlink from controling the contract, only allow the first callback to change state
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (requestId != chainlinkRequestID) {
            return;
        }
        if (phase2Revealed) {
            return;
        }
        if (phase2EndBlockNumber == 0 || block.number < phase2EndBlockNumber) {
            return;
        }
        phase2Revealed = true;
        phase2WinnerTokenID = randomness.mod(MAX_ELEMENTS).add(1);
        require(_exists(phase2WinnerTokenID), "Token ID not exists");
        emit WinPhase2(phase2WinnerTokenID);
    }

    // ******* private functions ********

    function _mintOne(address _to, uint256 _tokenId) private {
        _tokenNumTracker.increment();
        _safeMint(_to, _tokenId);
        emit CreateAvatar(_tokenId);

        if (_totalSupply() == LAST_WINNER_OF_TOKEN_NUM) {
            phase2StartBlockNumber = block.number;
            phase2EndBlockNumber = phase2StartBlockNumber.add(BLOCKS_PER_MONTH);
            phase1Winner = _msgSender();
            emit WinPhase1(phase1Winner);
        }
    }

    function _transfer(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev return current ceil count for current supply
     *
     * @dev total supply = 0, ceil = 1000
     * @dev total supply = 1, ceil = 1000
     * @dev total supply = 999, ceil = 1000
     * @dev total supply = 1000, ceil = 2000
     * @dev total supply = 9999, ceil = 10000
     * @dev total supply = 10000, ceil = 10000
     */
    function _ceil(uint256 totalSupply) internal pure returns (uint256) {
        if (totalSupply == MAX_ELEMENTS) {
            return MAX_ELEMENTS;
        }
        return totalSupply.div(ELEMENTS_PER_TIER).add(1).mul(ELEMENTS_PER_TIER);
    }
}
