/***
 *    ░█████╗░░█████╗░███╗░░██╗██████╗░██╗░░░██╗  ░█████╗░██████╗░███████╗░█████╗░████████╗░█████╗░██████╗░
 *    ██╔══██╗██╔══██╗████╗░██║██╔══██╗╚██╗░██╔╝  ██╔══██╗██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗
 *    ██║░░╚═╝███████║██╔██╗██║██║░░██║░╚████╔╝░  ██║░░╚═╝██████╔╝█████╗░░███████║░░░██║░░░██║░░██║██████╔╝
 *    ██║░░██╗██╔══██║██║╚████║██║░░██║░░╚██╔╝░░  ██║░░██╗██╔══██╗██╔══╝░░██╔══██║░░░██║░░░██║░░██║██╔══██╗
 *    ╚█████╔╝██║░░██║██║░╚███║██████╔╝░░░██║░░░  ╚█████╔╝██║░░██║███████╗██║░░██║░░░██║░░░╚█████╔╝██║░░██║
 *    ░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝
 *
 *    
 *
 *
 *  “Growing up, I slowly had this process of realizing that all the things around me that people had told me 
 *  were just the natural way things were, the way things always would be, they weren’t natural at all. 
 *  They were things that could be changed, and they were things that, more importantly, were wrong and should change,
 *  and once I realized that, there was really no going back.”
 * 
 *    ― Aaron Swartz (1986-2013)
 *
 *
 * Version: VARIANT_BASE_NOTPROV_NOTAIRDROP_ERC721A_NOTENUMERABLE_CONTEXTV2
 *
 * Purpose: ERC-721 template for no-code users.
 *          Placeholder for pre-reveal information. 
 *          Guaranteed mint royalties with PaymentSplitter.
 *          EIP-2981 compliant secondary sale royalty information.
 *          Whitelist functionality. Caps whitelist users and invalidates whitelist users after mint.
 *          Deployable to ETH, AVAX, BNB, MATIC, FANTOM chains.
 *          
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./ERC2981Collection.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract CandyCreatorV1A is ERC721A, ERC2981Collection, PaymentSplitter, Ownable {
  
  // @notice basic state variables
  string private base;
  bool private mintingActive;
  bool private lockedPayees;
  uint256 private maxPublicMints = 1;
  uint256 private mintPrice;
  uint256 private mintSize;
  uint256 private revealTime;
  string private placeholderURI;

  // @notice Whitelist functionality 
  bool private whitelistActive;
  bytes32 public whitelistMerkleRoot;
  uint64 private maxWhitelistMints = 1;

  event UpdatedRevealTimestamp(uint256 _old, uint256 _new);
  event UpdatedMintPrice(uint256 _old, uint256 _new);
  event UpdatedMintSize(uint _old, uint _new);
  event UpdatedMaxWhitelistMints(uint _old, uint _new);
  event UpdatedMaxPublicMints(uint _old, uint _new);
  event UpdatedMintStatus(bool _old, bool _new);
  event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);
  event UpdatedWhitelistStatus(bool _old, bool _new);
  event UpdatedPresaleEnd(uint _old, uint _new);
  event PayeesLocked(bool _status);
  event UpdatedWhitelist(bytes32 _old, bytes32 _new);

  // @notice Contract constructor requires as much information 
  // about the contract as possible to avoid unnecessary function calls 
  // on the contract post-deployment. 
  constructor(string memory name, 
              string memory symbol, 
              string memory _placeholderURI,
              uint256 _mintPrice,
              uint256 _mintSize,
              address _candyWallet,
              bool _multi,
              address [] memory splitAddresses,
              uint256 [] memory splitShares) 
              ERC721A(name, symbol) {
                placeholderURI = _placeholderURI;
                setMintPrice(_mintPrice);
                setMintSize(_mintSize);
                addPayee(_candyWallet, 500);
                if(!_multi) {
                  addPayee(_msgSender(), 9500);
                  lockPayees();
                } else {
                  for (uint i = 0; i < splitAddresses.length; i++) {
                    addPayee(splitAddresses[i], splitShares[i]);
                  }
                  lockPayees();
              }
  }

/***
 *    ███╗   ███╗██╗███╗   ██╗████████╗
 *    ████╗ ████║██║████╗  ██║╚══██╔══╝
 *    ██╔████╔██║██║██╔██╗ ██║   ██║   
 *    ██║╚██╔╝██║██║██║╚██╗██║   ██║   
 *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 */

  // @notice this is the mint function, mint Fees in ERC20,
  //  requires amount * mintPrice to be sent by caller
  // @param uint amount - number of tokens minted
  function whitelistMint(bytes32[] calldata merkleProof, uint64 amount) external payable {
    // @notice using Checks-Effects-Interactions
    require(mintingActive, "Minting not enabled");
    require(whitelistActive, "Whitelist not required, use publicMint()");
    require(_msgValue() == mintPrice * amount, "Wrong amount of Native Token");
    require(totalSupply() + amount <= mintSize, "Can not mint that many");
    require(amount <= maxWhitelistMints, "Exceeds maximum whitelist mints");
    require(
          MerkleProof.verify(
              merkleProof,
              whitelistMerkleRoot,
              keccak256(abi.encodePacked(_msgSender()))
          ),
          "Address not whitelisted"
    );
    uint64 numWhitelistMinted = _getAux(_msgSender()) + amount;
    require(numWhitelistMinted <= maxWhitelistMints, "Not enough whitelist slots.");
    _mint(_msgSender(), amount, '', false);
    _setAux(_msgSender(), numWhitelistMinted); 
  }

  // @notice this is the mint function, mint Fees in ERC20,
  //  requires amount * mintPrice to be sent by caller
  // @param uint amount - number of tokens minted
  function publicMint(uint256 amount) external payable {
    require(!whitelistActive, "publicMint() disabled because whitelist is enabled");
    require(mintingActive, "Minting not enabled");
    require(_msgValue() == mintPrice * amount, "Wrong amount of Native Token");
    require(totalSupply() + amount <= mintSize, "Can not mint that many");
    require(amount <= maxPublicMints, "Exceeds public transaction limit");
    _mint(_msgSender(), amount, '', false);
  }


/***
 *    ██████╗░░█████╗░██╗░░░██╗███╗░░░███╗███████╗███╗░░██╗████████╗
 *    ██╔══██╗██╔══██╗╚██╗░██╔╝████╗░████║██╔════╝████╗░██║╚══██╔══╝
 *    ██████╔╝███████║░╚████╔╝░██╔████╔██║█████╗░░██╔██╗██║░░░██║░░░
 *    ██╔═══╝░██╔══██║░░╚██╔╝░░██║╚██╔╝██║██╔══╝░░██║╚████║░░░██║░░░
 *    ██║░░░░░██║░░██║░░░██║░░░██║░╚═╝░██║███████╗██║░╚███║░░░██║░░░
 *    ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚══╝░░░╚═╝░░░
 * This section pertains to mint fees, royalties, and fund release.
 */

  // Function to receive ether, msg.data must be empty
  receive() external payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  // Function to receive ether, msg.data is not empty
  fallback() external payable {
    // From PaymentSplitter.sol
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  // @notice will release funds from the contract to the addresses
  // owed funds as passed to constructor 
  function release() external onlyOwner {
    _release();
  }

  // @notice this will use internal functions to set EIP 2981
  //  found in IERC2981.sol and used by ERC2981Collections.sol
  // @param address _royaltyAddress - Address for all royalties to go to
  // @param uint256 _percentage - Precentage in whole number of comission
  //  of secondary sales
  function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage) public onlyOwner {
    _setRoyalties(_royaltyAddress, _percentage);
    emit UpdatedRoyalties(_royaltyAddress, _percentage);
  }

  // @notice this will set the fees required to mint using
  //  publicMint(), must enter in wei. So 1 ETH = 10**18.
  // @param uint256 _newFee - fee you set, if ETH 10**18, if
  //  an ERC20 use token's decimals in calculation
  function setMintPrice(uint256 _newFee) public onlyOwner {
    uint256 oldFee = mintPrice;
    mintPrice = _newFee;
    emit UpdatedMintPrice(oldFee, mintPrice);
  }

  // @notice will add an address to PaymentSplitter by owner role
  // @param address newAddy - address to recieve payments
  // @param uint newShares - number of shares they recieve
  function addPayee(address newAddy, uint newShares) private {
    require(!lockedPayees, "Can not set, payees locked");
    _addPayee(newAddy, newShares);
  }

  // @notice Will lock the ability to add further payees on PaymentSplitter.sol
  function lockPayees() private {
    require(!lockedPayees, "Can not set, payees locked");
    lockedPayees = true;
    emit PayeesLocked(lockedPayees);
  }

/***
 *    
 *    ░█████╗░██████╗░███╗░░░███╗██╗███╗░░██╗
 *    ██╔══██╗██╔══██╗████╗░████║██║████╗░██║
 *    ███████║██║░░██║██╔████╔██║██║██╔██╗██║
 *    ██╔══██║██║░░██║██║╚██╔╝██║██║██║╚████║
 *    ██║░░██║██████╔╝██║░╚═╝░██║██║██║░╚███║
 *    ╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝
 * This section pertains to to basic contract administration tasks. 
 */

  // @notice this will enable publicMint()
  function enableMinting() external onlyOwner {
    bool old = mintingActive;
    mintingActive = true;
    emit UpdatedMintStatus(old, mintingActive);
  }

  // @notice this will disable publicMint()
  function disableMinting() external onlyOwner {
    bool old = mintingActive;
    mintingActive = false;
    emit UpdatedMintStatus(old, mintingActive);
  }

  // @notice this will enable whitelist or "if" in publicMint()
  function enableWhitelist() external onlyOwner {
    bool old = whitelistActive;
    whitelistActive = true;
    emit UpdatedWhitelistStatus(old, whitelistActive);
  }

  // @notice this will disable whitelist or "else" in publicMint()
  function disableWhitelist() external onlyOwner {
    bool old = whitelistActive;
    whitelistActive = false;
    emit UpdatedWhitelistStatus(old, whitelistActive);
  }

  // @notice this will set a new Merkle root used to verify whitelist membership
  // together with a proof submitted to the mint function  
  // @param bytes32 _merkleRoot - generated merkleRoot hash  
  function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        bytes32 old = whitelistMerkleRoot;
        whitelistMerkleRoot = _merkleRoot;
        emit UpdatedWhitelist(old, whitelistMerkleRoot);
  }

  // @notice this will set the maximum number of tokens a whitelisted user can mint.
  // @param uint256 _amount - max amount of tokens
  function setMaxWhitelistMints(uint64 _amount) public onlyOwner {
    uint256 oldAmount = maxWhitelistMints;
    maxWhitelistMints = _amount;
    emit UpdatedMaxWhitelistMints(oldAmount, maxWhitelistMints);
  }

  // @notice this will set the maximum number of tokens a single address can mint at a time
  // during the public mint period. Keep in mind that user will be able to transfer their tokens
  // to a different address, and continue minting this amount of tokens on each transaction. 
  // If you wish to prevent this, use the whitelist. 
  // @param uint256 _amount - max amount of tokens
  function setMaxPublicMints(uint256 _amount) public onlyOwner {
    uint256 oldAmount = maxPublicMints;
    maxPublicMints = _amount;
    emit UpdatedMaxPublicMints(oldAmount, maxWhitelistMints);
  }

  // @notice this updates the base URI for the token metadata
  // it does not emit an event so that it can be set invisibly to purchasers
  // and avoid token sniping 
  // @param string _ - max amount of tokens
  function setBaseURI(string memory baseURI) public onlyOwner {
        base = baseURI;
  }

  // @notice will set mint size by owner role
  // @param uint256 _amount - set number to mint
  function setMintSize(uint256 _amount) public onlyOwner {
    uint256 old = mintSize;
    mintSize = _amount;
    emit UpdatedMintSize(old, mintSize);
  }

  // @notice this will set the reveal timestamp
  // This is more for your API and not on-chain...
  // @param uint256 _time - uinx time stamp for reveal (use with API's only)
  function setRevealTimestamp(uint256 _timestamp) public onlyOwner {
    uint256 old = revealTime;
    revealTime = _timestamp;
    emit UpdatedRevealTimestamp(old, revealTime);
  }

/***
 *    ██████╗░██╗░░░██╗██████╗░██╗░░░░░██╗░█████╗░  ██╗░░░██╗██╗███████╗░██╗░░░░░░░██╗░██████╗
 *    ██╔══██╗██║░░░██║██╔══██╗██║░░░░░██║██╔══██╗  ██║░░░██║██║██╔════╝░██║░░██╗░░██║██╔════╝
 *    ██████╔╝██║░░░██║██████╦╝██║░░░░░██║██║░░╚═╝  ╚██╗░██╔╝██║█████╗░░░╚██╗████╗██╔╝╚█████╗░
 *    ██╔═══╝░██║░░░██║██╔══██╗██║░░░░░██║██║░░██╗  ░╚████╔╝░██║██╔══╝░░░░████╔═████║░░╚═══██╗
 *    ██║░░░░░╚██████╔╝██████╦╝███████╗██║╚█████╔╝  ░░╚██╔╝░░██║███████╗░░╚██╔╝░╚██╔╝░██████╔╝
 *    ╚═╝░░░░░░╚═════╝░╚═════╝░╚══════╝╚═╝░╚════╝░  ░░░╚═╝░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═════╝░
 */
  // @notice will return whether minting is enabled
  function mintStatus() external view  returns (bool) {
    return mintingActive;
  }

  // @notice will return whitelist status of Minter
  function whitelistStatus() external view returns (bool) {
    return whitelistActive;
  }

  // @notice will return the reveal timestamp for use by off-chain API to conditionally render
  // mint button 
  function revealTimestamp() external view returns (uint) {
    return revealTime;
  }

  // @notice will return minting fees
  function mintingFee() external view returns (uint256) {
    return mintPrice;
  }

  // @notice will return whitelist status of Minter
  function whitelistMaxMints() external view returns (uint256) {
    return maxWhitelistMints;
  }

  // @notice will return maximum tokens that are allowed to be minted during a single transaction
  // during the whitelist period
  function publicMaxMints() external view returns (uint256) {
    return maxPublicMints;
  }

  // @notice this is a public getter for ETH balance on contract
  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

  // @notice will return the planned size of the collection
  function collectionSize() external view returns (uint256) {
    return mintSize;
  }

  /***
 *    ░█████╗░██╗░░░██╗███████╗██████╗░██████╗░██╗██████╗░███████╗
 *    ██╔══██╗██║░░░██║██╔════╝██╔══██╗██╔══██╗██║██╔══██╗██╔════╝
 *    ██║░░██║╚██╗░██╔╝█████╗░░██████╔╝██████╔╝██║██║░░██║█████╗░░
 *    ██║░░██║░╚████╔╝░██╔══╝░░██╔══██╗██╔══██╗██║██║░░██║██╔══╝░░
 *    ╚█████╔╝░░╚██╔╝░░███████╗██║░░██║██║░░██║██║██████╔╝███████╗
 *    ░╚════╝░░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═════╝░╚══════╝
 */

  // @notice Solidity required override for _baseURI(), if you wish to
  //  be able to set from API -> IPFS or vice versa using setBaseURI(string)
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice Override for ERC721A _startTokenId to change from default 0 -> 1
  function _startTokenId() internal view override returns (uint256) {
    return 1;
  }

  // @notice Override for ERC721A tokenURI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json")) : placeholderURI;
  }

  // @notice solidity required override for supportsInterface(bytes4)
  // @param bytes4 interfaceId - bytes4 id per interface or contract
  // calculated by ERC165 standards automatically
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
    return (
      interfaceId == type(ERC2981Collection).interfaceId  ||
      interfaceId == type(PaymentSplitter).interfaceId ||
      interfaceId == type(Ownable).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }

}
