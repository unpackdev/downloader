// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC20.sol";

import "./IIdolMain.sol";
import "./IIdolMarketplace.sol";
import "./ICurvePool.sol";
import "./OfferingRefundContract.sol";

import "./console.sol";

/**
  @notice IdolMintContract is a contract used for the initial mint of the God NFTs. It allocates 90%
    of the Gods for public minting through a dutch auction protocol, and reserves 10% of the Gods
    for the creators of the protocol as well as other supporters and stakeholders. IdolMintContract
    is intended to be torn down once the mint event has completed and once its balance has been
    deposited into the IdolMain rewards protocol.
*/
contract IdolMintContract is Ownable, ReentrancyGuard {
  // publicGodsMinted tracks the number of Gods that have been minted by the public through the
  // mintGods function.
  uint public publicGodsMinted;

  // reservedGodsMinted tracks the number of reserved Gods that have been minted through the
  // mintReservedGods function.
  uint public reservedGodsMinted;

  // MAX_GODS_TO_MINT specifies the maximum number of Gods that can be minted (both public and
  // reserved.)
  uint public constant MAX_GODS_TO_MINT = 10000;

  // MAX_GODS_PER_ADDRESS specifies the maximum number of Gods that a single address can mint.
  uint public constant MAX_GODS_PER_ADDRESS = 20;

  // NUM_RESERVED_NFTS specifies the maximum number of Gods that can be minted through the
  // mintReservedGods function.
  uint public constant NUM_RESERVED_NFTS = 1000;

  // publicSaleDuration specifies the length of the dutch auction (in seconds) before the minting
  // price hits publicSaleGodEndingPrice.
  uint256 public publicSaleDuration;

  // publicSaleStartTime tracks the time (as a UNIX timestamp) when the public sale was started.
  uint256 public publicSaleStartTime;

  // publicSaleGodStartingPrice specifies the price that the dutch auction mint should start at.
  uint256 public publicSaleGodStartingPrice;

  // publicSaleGodEndingPrice specifies the minimum price that Gods can be minted at once the
  // full duration of the dutch auction has elapsed.
  uint256 public publicSaleGodEndingPrice;

  // publicSaleStarted specifies whether the minting event has been started.
  bool public publicSaleStarted = false;

  // publicSalePaused specifies whether the minting event has been paused.
  bool public publicSalePaused = false;

  // publicSalePausedElapsedTime specifies, if the sale was paused, what the elapsed sale
  // time was at the time of pausing.
  uint256 public publicSalePausedElapsedTime;

  // godIdOffset is pseudo-random offset from 0-10000 generated when the contract is constructed
  // and used to assign god IDs for each mint.
  uint256 public immutable godIdOffset;

  // addressReferencesSet is a boolean flag which tracks that the proper setup functions for the
  // contract have been run. It must be true before startPublicSale is called.
  bool public addressReferencesSet = false;

  // CURVE_POOL_ADDRESS holds the address of the curve pool that we use to exchange ETH for stETH.
  address constant CURVE_POOL_ADDRESS = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;

  // LIDO_STAKING_ADDRESS holds the address of the Lido staking contract that we also can use to
  // exchange ETH for stETH.
  address constant LIDO_STAKING_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

  IIdolMain public idolMain;
  IIdolMarketplace public idolMarketplace;
  ICurvePool public immutable stethPool;
  ERC20 public immutable steth;
  OfferingRefundContract public immutable offeringRefundContract;

  event PublicSaleStart(
    uint256 indexed _saleDuration,
    uint256 indexed _saleStartTime
  );

  event PublicSalePaused(
    uint256 indexed _currentPrice,
    uint256 indexed _timeElapsed
  );

  event PublicSaleResumed(
    uint256 indexed _saleResumeTime
  );

  event IdolsMinted(
    address indexed _minter,
    uint256 indexed _mintPrice,
    uint256 indexed _numMinted
  );

  /**
    @notice IdolMintContract's constructor takes in two hashes, one of which represents the hash of
      the Idol NFT metadata, and one of which is the hash of some discord-community-generated
      input. The two hashes are used to calculate the godIdOffset, which specifies which ID from
      0-10000 to start minting at.
    @param _metadataHash The hash of the master metadata file which corresponds to the 10k Idol NFT
      images that have been uploaded.
    @param _discordGeneratedHash The hash of some discord-community-generated input which is used
      to effectively randomize the value of godIdOffset prior to the start of the mint.
    @param _stethAddress The address of the stETH ERC20 contract.
    @param _offeringRefundContractAddress The address of the OfferingRefundContract we will be
      sending refunds to.
  */
  constructor(
    string memory _metadataHash,
    string memory _discordGeneratedHash,
    address _stethAddress,
    address payable _offeringRefundContractAddress
  ) {
    godIdOffset = uint256(keccak256(abi.encodePacked(_metadataHash, _discordGeneratedHash))) % MAX_GODS_TO_MINT;
    stethPool = ICurvePool(CURVE_POOL_ADDRESS);
    steth = ERC20(_stethAddress);
    offeringRefundContract = OfferingRefundContract(_offeringRefundContractAddress);
  }

  /**
    @notice startPublicSale is called to start the dutch auction for minting Gods to the public.
    @param _saleDuration The duration of the sale, in seconds, before reaching the minimum minting
      price.
    @param _saleStartPrice The initial minting price, which progressively lowers as the dutch
      auction progresses.
    @param _saleEndPrice Lower bound for the minting price, once the full duration of the dutch
      auction has elapsed.
   */
  function startPublicSale(uint256 _saleDuration, uint256 _saleStartPrice, uint256 _saleEndPrice)
    external
    onlyOwner
    beforePublicSaleStarted
  {
    require(_saleStartPrice > _saleEndPrice, "_saleStartPrice must be greater than _saleEndPrice");
    require(addressReferencesSet, "External reference contracts must all be set before public sale starts");
    publicSaleDuration = _saleDuration;
    publicSaleGodStartingPrice = _saleStartPrice;
    publicSaleGodEndingPrice = _saleEndPrice;
    publicSaleStartTime = block.timestamp;
    publicSaleStarted = true;
    emit PublicSaleStart(_saleDuration, publicSaleStartTime);
  }

  /**
    @notice setAddressReferences sets references to the main, marketplace, and virtueToken addresses
      so that the contracts all know about each other. This is all done from the mint contract so
      that the addresses will no longer be updateable once the mint event has started.
    @param _idolMainAddress The address of IdolMain.
    @param _idolMarketplaceAddress The address of the marketplace.
    @param _virtueTokenAddress The address of the VIRTUE token ERC20 contract.
   */
  function setAddressReferences(
    address _idolMainAddress,
    address _idolMarketplaceAddress,
    address _virtueTokenAddress
  )
    external
    onlyOwner
    beforePublicSaleStarted
  {
    addressReferencesSet = true;

    idolMain = IIdolMain(_idolMainAddress);
    require(steth.approve(_idolMainAddress, 2**255-1));

    idolMarketplace = IIdolMarketplace(_idolMarketplaceAddress);

    idolMain.setVirtueTokenAddr(_virtueTokenAddress);
    idolMain.setIdolMarketplaceAddr(_idolMarketplaceAddress);
    idolMarketplace.setVirtueTokenAddr(_virtueTokenAddress);
  }

  /**
    @notice pausePublicSale is called to pause the progression of the mint event. In happy-path
      circumstances we shouldn't need to call this, but it is included as a precaution in case
      something goes wrong during the mint.
  */
  function pausePublicSale()
    external
    onlyOwner
    whenPublicSaleActive
  {
    uint256 currentSalePrice = getMintPrice();
    uint256 elapsedTime = getElapsedSaleTime();

    publicSalePausedElapsedTime = elapsedTime;

    publicSalePaused = true;
    emit PublicSalePaused(currentSalePrice, elapsedTime);
  }

  function resumePublicSale()
    external
    onlyOwner
  {
    require(publicSalePaused, "Can only resume when the sale is paused");

    publicSalePaused = false;
    publicSaleStartTime = block.timestamp - publicSalePausedElapsedTime;

    emit PublicSaleResumed(block.timestamp);
  }

  /**
    @notice getElaspedSaleTime is a view function that tells us how many seconds have elapsed since
      the public sale was started.
  */
  function getElapsedSaleTime() internal view returns (uint256) {
    if (publicSalePaused) {
      return publicSalePausedElapsedTime;
    }
    return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
  }

  /**
    @notice getRemainingSaleTime is a view function that tells us how many seconds are remaining
      before the dutch auction hits the minimum price.
  */
  function getRemainingSaleTime() external view returns (uint256) {
    if (publicSaleStartTime == 0) {
      // If the public sale has not been started, we just return 1 week as a placeholder.
      return 604800;
    }

    if (publicSalePaused) {
      return publicSaleDuration - publicSalePausedElapsedTime;
    }

    if (getElapsedSaleTime() >= publicSaleDuration) {
      return 0;
    }

    return (publicSaleStartTime + publicSaleDuration) - block.timestamp;
  }

  /**
    @notice getMintPrice returns the price to mint a God at the current time in the dutch auction.
  */
  function getMintPrice() public view returns (uint256) {
    if (!publicSaleStarted) {
      return 0;
    }
    uint256 elapsed = getElapsedSaleTime();
    if (elapsed >= publicSaleDuration) {
      return publicSaleGodEndingPrice;
    } else {
      int256 tempPrice = int256(publicSaleGodStartingPrice) +
        ((int256(publicSaleGodEndingPrice) -
          int256(publicSaleGodStartingPrice)) /
          int256(publicSaleDuration)) *
        int256(elapsed);
      uint256 currentPrice = uint256(tempPrice);
      return
        currentPrice > publicSaleGodEndingPrice
          ? currentPrice
          : publicSaleGodEndingPrice;
    }
  }

  /**
    @notice mintGods is a payable function which allows the sender to pay ETH to mint God NFTs
      at the current price specified by getMintPrice.
    @param _numGodsToMint The number of gods to be minted, which is capped at a maximum of 5 Gods
      per transaction.
  */
  function mintGods(uint256 _numGodsToMint)
    external
    payable
    whenPublicSaleActive
    nonReentrant
  {
    require(
      publicGodsMinted + _numGodsToMint <= MAX_GODS_TO_MINT - NUM_RESERVED_NFTS,
      "Minting would exceed max supply"
    );
    require(_numGodsToMint > 0, "Must mint at least one god");
    require(
      idolMain.balanceOf(msg.sender) + _numGodsToMint <= MAX_GODS_PER_ADDRESS,
      "Requested number would exceed the maximum number of gods allowed to be minted for this address."
    );

    uint256 individualCostToMint = getMintPrice();
    uint256 costToMint = individualCostToMint * _numGodsToMint;
    require(costToMint <= msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < _numGodsToMint; i++) {
      uint idToMint = (publicGodsMinted + i + godIdOffset) % MAX_GODS_TO_MINT;
      idolMain.mint(msg.sender, idToMint, false);
    }

    publicGodsMinted += _numGodsToMint;

    if (msg.value > costToMint) {
      Address.sendValue(payable(msg.sender), msg.value - costToMint);
    }
    emit IdolsMinted(msg.sender, individualCostToMint, _numGodsToMint);
  }

  /**
    @notice mintReservedGods is used by the contract owner to mint a reserved pool of 1000 Gods
      for owners and supporters of the protocol.
    @param _numGodsToMint The number of Gods to mint in this transaction.
    @param _mintAddress The address to mint the reserved Gods for.
    @param _lock If true, specifies that the minted reserved Gods cannot be sold or transferred for
      the first year of the protocol's existence.
  */
  function mintReservedGods(uint256 _numGodsToMint, address _mintAddress, bool _lock)
    external
    onlyOwner
    nonReentrant
  {
    require(
      reservedGodsMinted + _numGodsToMint < NUM_RESERVED_NFTS,
      "Minting would exceed max reserved supply"
    );
    require(_numGodsToMint > 0, "Must mint at least one god");

    for (uint256 i = 0; i < _numGodsToMint; i++) {
      uint idToMint = (reservedGodsMinted + i + godIdOffset + MAX_GODS_TO_MINT - NUM_RESERVED_NFTS) % MAX_GODS_TO_MINT;
      idolMain.mint(_mintAddress, idToMint, _lock);
    }
    reservedGodsMinted += _numGodsToMint;
  }

  /**
    @notice sendToOfferingRefundContract sends ETH to the OfferingRefundContract so that it can be
      distributed to the addresses that are eligible for a refund.
  */
  function sendToOfferingRefundContract(uint _totalRefundAmount) onlyOwner external nonReentrant {
    Address.sendValue(payable(address(offeringRefundContract)), _totalRefundAmount);
  }

  /**
    @notice swap is used to swap the contract's ETH into stETH via Curve.
    @param _slippageBps The acceptable slippage percent, in basis points.
   */
  function swap(uint _slippageBps)
    onlyOwner
    external
    returns(uint result)
  {
    return stethPool.exchange{ value: address(this).balance }(0, 1, address(this).balance, address(this).balance * _slippageBps / 10000);
  }

  function swapLido(uint _slippageBps)
    onlyOwner
    external
  {
    uint minSteth = steth.balanceOf(address(this)) + address(this).balance * _slippageBps / 10000;
    Address.sendValue(payable(LIDO_STAKING_ADDRESS), address(this).balance);
    require(steth.balanceOf(address(this)) >= minSteth, "steth balance not high enough after sending to LIDO_STAKING_ADDRESS");
  }

  /**
    @notice depositStethIdolMain deposits all of this contract's stETH into the IdolMain contract.
  */
  function depositStethIdolMain()
    onlyOwner
    external
  {
    idolMain.depositSteth(steth.balanceOf(address(this)));
  }

  /**
    @notice getTotalMinted returns the total number of public + reserved God NFTs minted.
  */
  function getTotalMinted() external view returns (uint) {
    return reservedGodsMinted + publicGodsMinted;
  }

  /**
    @notice setBaseURI sets the baseURI for the God NFTs.
  */
  function setBaseURI(string memory uri) external onlyOwner {
    idolMain.setBaseURI(uri);
  }

  /**
    @notice Tears down the contract and allocates any remaining funds to the original
      contract owner. Should only be called after the mint completes and the contract's balance
      has been converted to Steth and deposited into IdolMain, or in a disaster scenario
      where we need to tear down the contract and refund minting fees.
  */
  function tearDown() external onlyOwner {
    selfdestruct(payable(owner()));
  }

  modifier beforePublicSaleStarted {
    require(!publicSaleStarted, "Public sale has already started");
    _;
  }

  modifier whenPublicSaleActive {
    require(publicSaleStarted && !publicSalePaused, "Public sale is not active");
    _;
  }
}
