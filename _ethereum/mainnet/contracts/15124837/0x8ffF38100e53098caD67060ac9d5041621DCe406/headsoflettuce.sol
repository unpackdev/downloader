// SPDX-License-Identifier: MIT

/*
 **************************************************************************

 Jinzo Heads of Lettuce

 * Global supply-chain issues have recently been challenging.
   Jinzo, a web3-native degen, restaurantoor, and friend to many,
   once spent upwards of $92 USD on a box of lettuce for his restaurant. 
   Jinzo just wanted to share his tasty delights with the world.

 * In this same spirit -
   and with careful consideration of current supply-chain dynamics -
   *** I have decided to drop-off 777 mysterious heads of lettuce for free ***

 * These heads are claimable, collectible, and utilizable via this smart contract.
   The truth about their history may be earth-shattering...
   but can only be obtained by those that hold 2 or more heads (in a month or two).

 **************************************************************************

 Jinzo Heads of Lettuce

 * No fancy website
 * No socials.
 * Just a smart contract with lettuce and hidden truths.
 * Original art.
 * cc0
 * 1 per wallet.
 * SUPPLY: whatever comes first- 777 mints or 2 hours without a new mint
 * Reserved: 0
 * Reveal: Instant

 **************************************************************************

 Jinzo Heads of Lettuce

 * if you are chill like an iceberg :  you will mint ONE AND ONLY ONE (from mint).
 * if you want more heads of lettuce :  you will paste the contract address into opensea.
 * if you follow these rules         :  you will be spoiled with great delights.

 * Stealth launch has begun
   Official links will be viewable through getOfficialLinks in the view API
   The most important utility is the friends made along the way

 * cooler heads prevail,
    - anonlettuce.eth

 */

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IHistoricalContract.sol";

contract JinzoHeadsOfLettuce is ERC721A, Ownable {

    uint256 public headMax = 777; // can be lowered but not raised

    mapping(address => bool) public addressHasMinted;

    string public baseURI;
    string public baseExtension = ".json";

    bool public publicSaleActive; 
    bool public specialPeriodActive;

    uint256 lastMintTimestamp;

    constructor(string memory _baseURI) ERC721A("Jinzo Heads of Lettuce", "HEADSOFLETTUCE") {
        baseURI = _baseURI;
        lastMintTimestamp = block.timestamp + 2 hours;
    }

    function mint() external { // free, 1 per wallet
        require(_totalMinted() < headMax, "no more");
        require(publicSaleActive, "public sale inactive");
        // require that the last mint was less than 2 hours ago
        uint256 _currentTimestamp = block.timestamp;
        if(lastMintTimestamp != _currentTimestamp) {
            require(lastMintTimestamp + 2 hours > _currentTimestamp, "you waited too long");
            lastMintTimestamp = _currentTimestamp;
        }
        require(!addressHasMinted[_msgSender()], "you already minted");
        addressHasMinted[_msgSender()] = true;
        _safeMint(_msgSender(), 1);
    }

    mapping(address => bool) public canSummonAlpha;
    mapping(uint256 => bool) public hasBeenUsed;
    IHistoricalContract public historicalContract;
    function initializeSummoningAbilities(uint256 _id1, uint256 _id2) external {
        require(specialPeriodActive);
        require(ownerOf(_id1) == _msgSender() && ownerOf(_id2) == _msgSender(), "not yours");
        require(!hasBeenUsed[_id1] && !hasBeenUsed[_id2], "one or both of these have been used");
        hasBeenUsed[_id1] = true;
        hasBeenUsed[_id2] = true;
        canSummonAlpha[_msgSender()] = true;
        historicalContract.lettuceMint(_msgSender());
    }

    function checkSummoningAbilities(address _addr) external view returns(bool) {
        return canSummonAlpha[_addr];
    }

    function mintGift(address _addr, uint256 _amount) external onlyOwner {
        require(_totalMinted() < headMax, "no more");
        _safeMint(_addr, _amount);
    }

    function setPublicSaleActive(bool _intended) external onlyOwner {
        require(publicSaleActive != _intended, "This is already the value");
        publicSaleActive = _intended;
        lastMintTimestamp = block.timestamp;
    }

    function setSpecialPeriodActive(bool _intended) external onlyOwner {
        require(specialPeriodActive != _intended, "This is already the value");
        specialPeriodActive = _intended;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseExtension(string calldata _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function setHeadsMax(uint256 _newHeadMax) external onlyOwner { 
        require(_newHeadMax < headMax, "supply cap can only be lowered");
        headMax = _newHeadMax;
    }

    function createOfficialLink(string memory _link) external onlyOwner {
        officialLinks.push(_link);
    }
    function setOfficialLink(uint256 _i, string memory _newLink) external onlyOwner {
        officialLinks[_i] = _newLink;
    }

    // SOURCE OF TRUTH
    string public lettuceTalk = "check back soon"; // view API for most recent alpha
    function setLettuceWords(string memory _newWords) external onlyOwner {
        lettuceTalk = _newWords;
    }

    function setHistoricalContract(address _addr) external onlyOwner {
        historicalContract = IHistoricalContract(_addr);
    }
  
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), baseExtension));
    }

    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Failed to send ether");
    }

    function donate() public payable {
        (bool thanks, ) = owner().call{value: address(this).balance}("");
        require(thanks);
	}

    string[] officialLinks; // SOURCE OF TRUTH
    function getOfficialLinks() external view returns(string[] memory){
        return officialLinks; 
    }

    /* 
     
     Jinzo Heads of Lettuce

     * Artist Royalty: 7.5% of secondary sales
     * Jinzo and the hardworking team at MVHQ will receive a 15% cut.
     * The MVHQ community fund will also receive a 15% cut.
     * *** MVHQ and the team had no prior knowledge of the lettuce arrival. ***

     * cooler heads prevail,
     - anonlettuce.eth

     */

}

