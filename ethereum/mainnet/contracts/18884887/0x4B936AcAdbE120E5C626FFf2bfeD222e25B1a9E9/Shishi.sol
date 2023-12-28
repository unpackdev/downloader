// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.16;

import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./EIP712.sol";

/// Thrown if the base token metadata URI is locked to updates.
error BaseURILocked ();

/// Thrown if an invalid signature is being supplied by the caller.
error CannotClaimInvalidSignature ();

/// Thrown if the signature supplied does not match the current time.
error NotStartedYet ();

/// Thrown if the caller is trying to overmint.
error InvalidQuantity ();

/// Thrown if the caller did not supply enough payment.
error NotEnoughPayment ();

/// Thrown if the public mint has not yet started.
error PublicMintNotStarted ();

/// Thrown if there are no more Shishis left to mint.
error OutOfStock ();

/**
  This is thrown if a particular `msg.sender` (or, additionally, a `tx.origin`
  acting on behalf of smart contract caller) has run out of permitted mints.
  This does not and is not meant to protect against Sybil attacks originated by
  multiple different accounts.
*/
error OutOfMints ();

// Thrown if sweeping funds from this contract fails.
error SweepingTransferFailed ();

/**
  @custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVM MEVM
  @title Shishi. Ever dream this girl?
  @author Tim Clancy <tim-clancy.eth>
  @author many loving friendly network spirits
  @custom:version 1.0
  
  Shishi is a generative art project by shirosama.eth; yippiee!

  @custom:date December 28th, 2023.
  @custom:terry "I am in an angel prison or some shit."
*/
contract Shishi is EIP712, ERC721ABurnable, Ownable, ReentrancyGuard {

  /**
    Store the provenance hash. This is computed as the keccak256 hash of the
    images for all Shishis, in token ID order, concatenated together and then
    hashed one last time forever. We understand that this is only a weak
    guarantee of honesty--it proves that we committed to the art and its order
    prior to beginning the mint but does nothing to trustlessly conceal the
    specific metadata of particular Shishis ahead of time. You'll just have to
    deal with that; schemes which apply provably-randomized offsets to the
    provenance data are very difficult to reconcile with instant reveals.
  */
  bytes32 constant private provenance =
    0x33f697f5034dee7c24e34d7c737bab50920b3cbd1a4854e01230b8568d910dae;

  /// A constant hash of the mint operation's signature.
  bytes32 constant private MINT_TYPEHASH = keccak256(
    "mint(address _minter,uint64 _start,uint8 _oh,uint8 _remi,uint8 _paid)"
  );

  /// Track the base token metadata URI.
  string internal baseURI;

  /// Track whether the base token metadata URI is locked to future changes.
  bool private baseURILocked;

  /// Track the total supply cap on the number of Shishis that may be minted.
  uint256 private cap;

  /// Track the address of the authorized whitelist signer.
  address private signer;

  /// Track the start time of whitelist phase two.
  uint64 private startTwo;

  /// Track the start time of the public mint.
  uint64 private startThree;

  /**
    Right about here is where I got lazy and began to regret my decision of
    doing this entire thing with fancy signatures and a single mint function.

    Thank you Vx loves and kisses mwah mwah.

    @param oh Track a caller's expended Oh I See mints.
    @param remi Track a caller's expended Milady/Remilio mints.
    @param paid Track a caller's expended paid mints.
    @param callerPub Track a caller's utilized public mints.
    @param originPub Track a transaction originator's utilized public mints.
  */
  struct MintCounts
  {
    uint8 oh;
    uint8 remi;
    uint8 paid;
    uint8 callerPub;
    uint8 originPub;
  }

  /// Store tracked inter-round receipt information.
  mapping ( address => MintCounts ) internal mintCounts;

  /// Track the number of utilized FCFS Milady/Remilio mints.
  uint256 public fcfs;

  /**
    Construct an instance of the Shishi contract.

    @param _owner The initial owner of this contract.
    @param _initialBaseURI The initial base token metadata URI to use.
    @param _cap The total supply cap on the number of Shishis.
    @param _signer The address of the initial whitelist signer.
    @param _startTwo The start time of whitelist phase two.
    @param _startThree The start time of public minting.
  */
  constructor (
    address _owner,
    string memory _initialBaseURI,
    uint256 _cap,
    address _signer,
    uint64 _startTwo,
    uint64 _startThree
  ) EIP712("Shishi", "1") ERC721A("Shishi", "SHISHI") {
    _initializeOwner(_owner);
    baseURI = _initialBaseURI;
    cap = _cap;
    signer = _signer;
    startTwo = _startTwo;
    startThree = _startThree;
    _mint(_owner, 1);
  }

  /**
    Override the starting index of the first Shishi.

    @return _ The token ID of the first Shishi.
  */
  function _startTokenId (
  ) internal view virtual override returns (uint256) {
    return 1;
  }

  /**
    Override the `_baseURI` used in our parent contract with our set value.

    @return _ The base token metadata URI.
  */
  function _baseURI (
  ) internal view virtual override returns (string memory) {
    return baseURI;
  }

  /**
    Allow the contract owner to set the base token metadata URI.

    @param _newBaseURI The new base token metadata URI to set.
    @custom:throws BaseURILocked if the base token metadata URI is locked
      against future changes.
  */
  function setBaseURI (
    string memory _newBaseURI
  ) external payable onlyOwner {
    if (baseURILocked) {
      revert BaseURILocked();
    } else {
      baseURI = _newBaseURI;
    }
  }

  /**
    Allow the contract owner to permanently lock base URI changes.
  */
  function lockBaseURI (
  ) external payable onlyOwner {
    baseURILocked = true;
  }

  /**
    Allow the contract owner to set the authorized whitelist signer.

    @param _signer The new authorized signer.
  */
  function setSigner (
    address _signer
  ) external payable onlyOwner {
    signer = _signer;
  }

  /**
    Allow the contract owner to set the whitelist phase times.

    @param _startTwo The new phase two time.
    @param _startThree The new phase three time.
  */
  function setPhases (
    uint64 _startTwo,
    uint64 _startThree
  ) external payable onlyOwner {
    startTwo = _startTwo;
    startThree = _startThree;
  }

  /**
    A private helper function to validate a signature supplied for mints.
    This function constructs a digest and verifies that the signature signer was
    the authorized address we expect.

    @param _minter The caller attempting to mint.
    @param _start The start time of the minting signature.
    @param _oh The amount of free Oh I See mints the caller is trying to claim.
    @param _remi The amount of free Milady/Remilio mints the caller is trying
      to claim.
    @param _paid The amount of paid mints the caller is trying to claim.
    @param _v The recovery byte of the signature.
    @param _r Half of the ECDSA signature pair.
    @param _s Half of the ECDSA signature pair.
  */
  function validClaim (
    address _minter,
    uint64 _start,
    uint8 _oh,
    uint8 _remi,
    uint8 _paid,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) private view returns (bool) {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            MINT_TYPEHASH,
            _minter,
            _start,
            _oh,
            _remi,
            _paid
          )
        )
      )
    );

    // The claim is validated if it was signed by our authorized signer.
    return ecrecover(digest, _v, _r, _s) == signer;
  }

  /**
    Allow the caller to mint Shishis.

    @param _quantity The number of Shishi to mint.

    @custom:throws CannotClaimInvalidSignature if an invalid signature is
      supplied by the caller.
    @custom:throws NotStartedYet if a signature is submitted too early.
    @custom:throws InvalidQuantity if a caller is trying to mint too much.
    @custom:throws NotEnoughPayment if a caller is underpaying.
    @custom:throws PublicMintNotStarted if a non-whitelisted caller is early.
    @custom:throws OutOfMints if the caller has exhausted their mint allowance.
    @custom:throws OutOfStock if all of the Shishis have been minted.
  */
  function mint (
    uint64 _start,
    uint8 _oh,
    uint8 _remi,
    uint8 _paid,
    uint8 _quantity,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external payable nonReentrant {

    // Determine mint price based on time.
    uint256 _price = 0.033 ether;
    if (block.timestamp > startThree) {
      _price = 0.04 ether;
    }

    // If a signature is provided, validate it.
    if (_start != 0) {
      bool validSignature = validClaim(
        msg.sender,
        _start,
        _oh,
        _remi,
        _paid,
        _v,
        _r,
        _s
      );
      if (!validSignature) {
        revert CannotClaimInvalidSignature();
      }

      // Validate the minting phase.
      if (block.timestamp < _start) {
        revert NotStartedYet();
      }

      // Reduce by previous utilized allowance.
      _oh -= mintCounts[msg.sender].oh;
      _remi -= mintCounts[msg.sender].remi;
      _paid -= mintCounts[msg.sender].paid;
      mintCounts[msg.sender].oh += _oh;
      mintCounts[msg.sender].remi += _remi;
      mintCounts[msg.sender].paid += _paid;

      // Validate sensible quantity.
      if (_quantity > (_oh + _remi + _paid)) {
        revert InvalidQuantity();
      }

      // Handle the special FCFS Milady/Remilio pool.
      if (block.timestamp > startTwo) {
        if (fcfs >= 300) {
          _quantity -= _remi;
        } else {
          fcfs += _remi;
        }
      }

      // Validate payment.
      uint256 _paidQuantity = _quantity - _remi - _oh;
      if (msg.value < _paidQuantity * _price) {
        revert NotEnoughPayment();
      }
    
    // If no signature is provided, we must try for the public mint.
    } else {
      if (block.timestamp < startThree) {
        revert PublicMintNotStarted();
      }

      // Validate the public mint cap.
      if (
        mintCounts[msg.sender].callerPub + _quantity > 2 ||
        mintCounts[tx.origin].originPub + _quantity > 2
      ) {
        revert OutOfMints();
      }

      // Validate payment.
      if (msg.value < _quantity * _price) {
        revert NotEnoughPayment();
      }
      mintCounts[msg.sender].callerPub += _quantity;
      mintCounts[tx.origin].originPub += _quantity;
    }

    // Prevent the overminting of Shishis.
    if (_totalMinted() + _quantity > cap) {
      revert OutOfStock();
    }

    // Mint the Shishi.
    _mint(msg.sender, _quantity);
  }

  /**
    Allow the owner to sweep Ether from the contract and send it to another
    address. This allows the owner of the shop to withdraw their funds after
    the sale is completed.

    @param _destination The address to send the swept tokens to.
    @param _amount The amount of token to sweep.

    @custom:throws SweepingTransferFailed if the balance could not transfer.
  */
  function sweep (
    address _destination,
    uint256 _amount
  ) external payable onlyOwner {
    (bool success, ) = payable(_destination).call{ value: _amount }("");
    if (!success) { revert SweepingTransferFailed(); }
  }
 }

