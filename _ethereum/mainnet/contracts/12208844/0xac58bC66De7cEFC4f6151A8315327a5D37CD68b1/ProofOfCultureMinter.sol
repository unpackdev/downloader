pragma solidity ^0.7.5;
pragma abicoder v2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";

contract ProofOfCultureMinter is Ownable {
  using LibSafeMath for uint256;

  struct _HashtagContainer {
    string originalHashtag;
    string normalizedHashtag;
    uint256 timestamp;
  }

  uint256 public hashtagTokenType;

  uint256 public batchOrderLimit;

  ERC1155Mintable public mintableErc1155;

  uint256 public constant MAX_NFT_SUPPLY = 9999;

  address payable public treasury;

  string[] public claimedHashtags;

  mapping(uint256 => _HashtagContainer) public tokenIdToHashtagContainer;
  mapping(string => uint256) public normalizedHashtagToTokenId;

  mapping(string => string) public normalizedHashtagToImageURI;
  mapping(uint256 => string) public tokenIdToImageURI;

  // platform supporter vars
  uint256 public constant supporterTokenCap = 15; // THIS WILL NEVER CHANGE!! WE ONLY MINT A SET AMOUNT FOR SUPPORTERS
  uint256 public currentSupporterTokenCount;

  // image change counts
  mapping(uint256 => uint256) public tokenIdToImageChangeCount;

  // admin toggles
  bool public saleStarted;
 
  constructor(
    address _mintableErc1155,
    address payable _treasury,
    uint256 _hashtagTokenType,
    uint256 _batchOrderLimit
  ) {
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    hashtagTokenType = _hashtagTokenType;
    batchOrderLimit = _batchOrderLimit;
  }

  event UpdatedRegistry(
    uint256 tokenId,
    string hashtag
  );

  event Received(address, uint);


  /**
  * @dev Gets the total supply, which is the sum of all hashtags minted.
  
         Note that NFTs have a maxIndex but FTs don't, so we just keep track of the total here.
  */
  function totalSupply() public view returns (uint256) {
    return mintableErc1155.maxIndex(hashtagTokenType);
  }

  /**
  * @dev Returns all claimed hashtags as an array
  */
  function getAllClaimedHashtags() public view returns (string[] memory) {
    return claimedHashtags;
  }

  /**
  * @dev Return original (not normalized) hashtags that a given address owns. Leverages nfTokensOf but returns the hashtags instead of the token IDs
  */
  function hashtagsOf(address _address) public view returns (string[] memory) {
    uint256[] memory tokenIds = mintableErc1155.nfTokensOf(_address);
    string[] memory hashtags = new string[](tokenIds.length);
    for(uint i=0; i<tokenIds.length; i++){
      uint256 tokenId = tokenIds[i];
      hashtags[i] = tokenIdToHashtagContainer[tokenId].originalHashtag;
    }
    return hashtags;
  }

  /**
  * @dev Validate hashtag.
         - string must start with a '#'
         - string length must be min 2 chars (# + one char)
         - string length must be max 31 chars (1 + 30)
         - string must be alphanumeric + underscore (aside from the first hashtag)
  */
  function validateHashtag(string memory _hashtag) public pure returns (bool) {
    bytes memory b = bytes(_hashtag);
    if(b.length < 2) return false;
    if(b.length > 31) return false;

    bytes1 firstChar = b[0];
    if (!(firstChar == 0x23)) return false; // make sure the first character is a '#'

    for(uint i=1; i<b.length; i++){
        bytes1 char = b[i];

        if(
            !(char >= 0x30 && char <= 0x39) && //9-0
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) && //a-z
            !(char == 0x5F) //_
        )
            return false;
    }

    return true;
  }

  /**
  * @dev Normalize hashtag by making uppercase into lowercase.
         Examples:
         - #BlackLivesMatter   => #blacklivesmatter
         - #BLM                => #blm
         - #NFTsAreAwesome123  => #nftsareawesome123
  */
  function normalizeHashtag(string memory _hashtag) public pure returns (string memory) {
    bytes memory b = bytes(_hashtag);
    require(b.length >= 2, "Hashtag cannot be less than 2 chars");
    require(b.length <= 31, "Hashtag cannot be more than 31 chars");

    bytes1 firstChar = b[0];
    require(firstChar == 0x23, "Hashtag must start with a '#'");

		bytes memory bLower = new bytes(b.length);

		for (uint i = 0; i < b.length; i++) {
			// Uppercase character...
			if ((uint8(b[i]) >= 65) && (uint8(b[i]) <= 90)) {
        // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(b[i]) + 32);
      } else {
        bLower[i] = b[i];
      }
		}
		return string(bLower);
  }

  /**
  * @dev Gets the price up to 9999 tokens.
         As we put in a lot of artistic work into each token, we are taking a 
         constant pricing model, instead of the bonding curve model popularly seen
         in this space recently.
  */
  function getPrice() public view returns (uint256) {
    require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

    return 1000000000000000000; // 1ETH
  }

  /**
  * @dev Set address of treasury - the address that will receive all payments
  */
  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  /**
  * @dev Set batch order limit
  */
  function setBatchOrderLimit(uint256 _batchOrderLimit) external onlyOwner() {
    batchOrderLimit = _batchOrderLimit;
  }

  /**
  * @dev Set Image URL for Token Id in batch.
  *      Note that we will only use this after individually crafting the image.
  *      The image will be hosted on IPFS and seeded properly for perpetuity so the image can remain accessible.
  *
  *      If for any reason we have to update the image after the first time, we refund the original price of the art
  *      to the current owner of the token.
  */
  function setBatchImageURIsForTokens(uint256[] calldata _ids, string[] calldata _image_uris) external onlyOwner() {
    require(_ids.length == _image_uris.length, "Batch arrays must be of the same length");

    for (uint256 i = 0; i < _ids.length; ++i) {
      // Cache value to local variable to reduce read costs.
      uint256 id = _ids[i];
      string memory image_uri = _image_uris[i];

      // If this image has already been changed once, then we should refund the original price to the current owner
      uint256 imageChangeCount = tokenIdToImageChangeCount[id];
      if (imageChangeCount == 1) {
        address payable owner = payable(mintableErc1155.ownerOf(id));
        owner.transfer(1000000000000000000); // refund the 1ETH
      }

      tokenIdToImageURI[id] = image_uri;

      // also set it for the hashtag
      _HashtagContainer memory container = tokenIdToHashtagContainer[id];
      normalizedHashtagToImageURI[container.normalizedHashtag] = image_uri;

      tokenIdToImageChangeCount[id] += 1;
    }
  }

  /**
  * @dev Set saleStarted boolean to start or end sale
  */
  function setSaleStarted(bool _saleStarted) external onlyOwner() {
    saleStarted = _saleStarted;
  }

  /**
  * @dev Mint signature hashtags for our platform supporters (up to a certain limit that is a constant).
  */
  function mintSignatureTokens(string[] memory _hashtags) external onlyOwner() {
    require(currentSupporterTokenCount.safeAdd(_hashtags.length) <= supporterTokenCap, "Exceeds supporterTokenCap");
    for (uint i = 0; i < _hashtags.length; i++) {
      string memory hashtag = _hashtags[i];

      if (!validateHashtag(hashtag)) {
        continue; // skip if this is not a valid hashtag
      }

      string memory normalizedHashtag = normalizeHashtag(hashtag);
      if (normalizedHashtagToTokenId[normalizedHashtag] != 0) {
        continue; // skip if this hashtag already exists
      }

      // mint the NFT
      address[] memory dsts = new address[](1);
      dsts[0] = msg.sender;
      uint256 index = mintableErc1155.maxIndex(hashtagTokenType) + 1;
      uint256 tokenId  = hashtagTokenType | index;
      mintableErc1155.mintNonFungible(hashtagTokenType, dsts);

      // bookkeeping
      _HashtagContainer memory hc;
      hc.normalizedHashtag = normalizedHashtag;
      hc.originalHashtag = hashtag;
      hc.timestamp = block.timestamp;
      tokenIdToHashtagContainer[tokenId] = hc;
      normalizedHashtagToTokenId[normalizedHashtag] = tokenId;

      claimedHashtags.push(hashtag);

      emit UpdatedRegistry(tokenId, hashtag);

      currentSupporterTokenCount += 1;
    }
  }

  /**
  * @dev Mint multiple hashtags at once. We will try our best to mint all but
         if they have already been claimed, then we will refund the money back.

         Note that this function is inefficient because each mint actually emits a transfer
         event and this doesn't scale. 25 should be OK, but for anything more, consider the
         EIP2309 extension of ERC721.
  */
  function mint(address _dst, string[] memory _hashtags) public payable {
    require(saleStarted, "Sale has not started yet");
    require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

    uint numberOfNfts = _hashtags.length;
    require(numberOfNfts > 0, "numberOfNfts cannot be 0");
    require(numberOfNfts <= batchOrderLimit, "You may not buy more than the batch limit at once");
    require(totalSupply().safeAdd(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
    require(getPrice().safeMul(numberOfNfts) <= msg.value, "Ether value sent is not correct");

    // set price upfront before minting - we will need to use this to calculate refunds
    uint256 pricePerHashtag = getPrice();

    // Keep track of which hashtags we were able to mint
    uint mintedCount = 0;
    for (uint i = 0; i < numberOfNfts; i++) {
      string memory hashtag = _hashtags[i];

      if (!validateHashtag(hashtag)) {
        continue; // skip if this is not a valid hashtag
      }

      string memory normalizedHashtag = normalizeHashtag(hashtag);
      if (normalizedHashtagToTokenId[normalizedHashtag] != 0) {
        continue; // skip if this hashtag already exists
      }

      // mint the NFT
      address[] memory dsts = new address[](1);
      dsts[0] = _dst;
      uint256 index = mintableErc1155.maxIndex(hashtagTokenType) + 1;
      uint256 tokenId  = hashtagTokenType | index;
      mintableErc1155.mintNonFungible(hashtagTokenType, dsts);

      // bookkeeping
      _HashtagContainer memory hc;
      hc.normalizedHashtag = normalizedHashtag;
      hc.originalHashtag = hashtag;
      hc.timestamp = block.timestamp;
      tokenIdToHashtagContainer[tokenId] = hc;
      normalizedHashtagToTokenId[normalizedHashtag] = tokenId;
      mintedCount++;

      claimedHashtags.push(hashtag);

      emit UpdatedRegistry(tokenId, hashtag);
    }

    // Only charge for the hashtags that we were able to mint, and refund the rest
    uint256 actualTotalPrice = pricePerHashtag.safeMul(mintedCount);
    treasury.transfer(actualTotalPrice);
    msg.sender.transfer(msg.value - actualTotalPrice);
  }

  receive() external payable {
      emit Received(msg.sender, msg.value);
  }
}