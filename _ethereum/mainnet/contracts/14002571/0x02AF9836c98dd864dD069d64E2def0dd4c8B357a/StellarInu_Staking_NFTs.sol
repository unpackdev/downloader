/***
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: cryptobymaxflowO2@gmail.com
 *
 * Purpose: Chain ID #1-5 OpenSea compliant contract
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IMAX721.sol";
import "./ContractURI.sol";

contract StellarInuNFTs is ERC721, ERC721URIStorage, ContractURI, IMAX721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;
  Counters.Counter private _tokenIdCounter;
  Counters.Counter private _teamMintCounter;
  uint private mintFees;
  uint private constant mintSize = 3500;
  uint private teamMintSize;
  uint private constant totalChoices = 5;
  uint private thresholdAmount;
  string private base;
  ERC20 private ERC20Address;
  address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
  bool private enableMinter;
  mapping(address => bool) public hasClaimed;

  // @notice all events within contract, will be explained in functions
  event UpdatedBaseURI(string _old, string _new);
  event UpdatedMintFees(uint _old, uint _new);
  event UpdatedThresholdAmount(uint _old, uint _new);
  event UpdatedMintSize(uint _old, uint _new);
  event UpdatedMintStatus(bool _old, bool _new);
  event UpdatedTeamMintSize(uint _old, uint _new);
  event UpdatedERC20Address(ERC20 _old, ERC20 _new);
  event UpdatedTotalChoices(uint _old, uint _new);

  constructor() ERC721("Stellar Inu Elemental NFTs", "SNFT") {}

/***
 *    ███╗   ███╗██╗███╗   ██╗████████╗
 *    ████╗ ████║██║████╗  ██║╚══██╔══╝
 *    ██╔████╔██║██║██╔██╗ ██║   ██║   
 *    ██║╚██╔╝██║██║██║╚██╗██║   ██║   
 *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 */

  // @notice this is the mint function, mint Fees in ERC20,
  //  that locks tokens to contract, inable to withdrawl, public
  //  nonReentrant() function. Must have IERC20 approval prior
  //  to minting! Call it within the application.
  // @param uint amount - number of tokens minted
  // ERC165 datum publicMint(uint256,uint256) => 0x98ae99a8
  function publicMint(uint amount) public nonReentrant() {
    // @notice using Checks-Effects-Interactions
    // @notice Checks Phase
    require(enableMinter, "Minter not active");
    require(_tokenIdCounter.current() + amount <= mintSize, "Can not mint that many");
    // @notice Effects Phase
    // @notice this transfers ERC20 token to 0xdEaD (ERC20.sol), contract
    //  must be approved prior to minting, use approve methods in web app
    uint tokenAmount = amount * mintFees;
    ERC20Address.transferFrom(_msgSender(), DEAD_ADDRESS, tokenAmount);
    // @notice Interactions Phase
    for (uint i = 0; i < amount; i++) {
      // @notice mintID() will use a psuedo-random number and plug it
      //  into a string with the return automatically, then Counter.count
      //  will auto increment the TokenID numbers
      _safeMint(_msgSender(), _tokenIdCounter.current());
      _setTokenURI(_tokenIdCounter.current(), mintID());
      _tokenIdCounter.increment();
    }  
  }

  // @notice this is the free mint if you hold a balance above a threshold
  //  stated above. Threshold is set by onlyOwner!
  function claimNFT() public nonReentrant() {
    // @notice using Checks-Effects-Interactions
    // @notice Checks Phase
    require(enableMinter, "Minter not active");
    require(ERC20Address.balanceOf(_msgSender()) >= thresholdAmount, "Do not hold enough ERC20 tokens to claim.");
    require(_tokenIdCounter.current() < mintSize, "Can not mint that many");
    require(!hasClaimed[_msgSender()], "Can not claim a second time");
    // @notice Effects Phase
    hasClaimed[_msgSender()] = true;
    // @notice Interactions Phase
    // @notice mintID() will use a psuedo-random number and plug it
    //  into a string with the return automatically, then Counter.count
    //  will auto increment the TokenID numbers
    _safeMint(_msgSender(), _tokenIdCounter.current());
    _setTokenURI(_tokenIdCounter.current(), mintID());
    _tokenIdCounter.increment();
  }

  // @notice this is the team mint function, no mint Fees in ERC20,
  //  public onlyOwner function. More comments within code
  // @param address _address - address to "airdropped" or team mint token
  // ERC165 datum teamMint(address) => 0xb6a1dba1
  function teamMint(address _address) public onlyOwner {
    // @notice using Checks-Effects-Interactions
    require(enableMinter, "Minter not active");
    require(teamMintSize != 0, "Team minting not enabled");
    require(_tokenIdCounter.current() < mintSize, "Can not mint that many");
    require(_teamMintCounter.current() < teamMintSize, "Can not team mint anymore");
    // @notice mintID() will use a psuedo-random number and plug it
    //  into a string with the return automatically, then Counter.count
    //  will auto increment the TokenID numbers
    _safeMint(_address, _tokenIdCounter.current());
    _setTokenURI(_tokenIdCounter.current(), mintID());
    _tokenIdCounter.increment();
    _teamMintCounter.increment();
  }

  // @notice this takes current information and creates a Psuedo-Random number
  //  for the x-types of NFT's you can get. Consider _tokenIdCounter.current()
  //  as a nonce, using block.timestamp, block.difficulty, and _msgSender() then
  //  modulo division by total number of NFT's
  function mintID() internal view returns (string memory) {
    uint value = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _msgSender(), address(this), _tokenIdCounter.current()))) % totalChoices;
    return value.toString();
  }

  // @notice Function to receive ether, msg.data must be empty
  receive() external payable {
  }

  // @notice Function to receive ether, msg.data is not empty
  fallback() external payable {
  }

  // @notice this is a public getter for ETH blance on contract
  // ERC165 datum getBalance() => 0x12065fe0
  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

/***
 *     ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗ 
 *    ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
 *    ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
 *    ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
 *    ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
 *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
 * This section will have all the internals set to onlyOwner
 */

  // @notice this will set the fees required to mint using
  //  publicMint(), must enter in whole tokens.
  // @param uint _newFee - fee you set, in whole ERC20 tokens
  //  as you see below, ERC20.decimals() is called in calculation.
  // ERC165 datum setMintFees(uint256) => 0x06b6f7e9
  function setMintFees(uint _newFee) public onlyOwner {
    require(address(ERC20Address) != address(0), "ERC20 token address not set.");
    uint oldFee = mintFees;
    mintFees = _newFee * 10**ERC20Address.decimals();
    emit UpdatedMintFees(oldFee, mintFees);
  }

  // @notice this will set the threshold required to mint using
  //  claimNFT(), must enter in whole tokens.
  // @param uint _newFee - fee you set, in whole ERC20 tokens
  //  as you see below, ERC20.decimals() is called in calculation.
  // ERC165 datum setFreeThreshold(uint256) => 0x06b6f7e9
  function setFreeThreshold(uint _threshold) public onlyOwner {
    require(address(ERC20Address) != address(0), "ERC20 token address not set.");
    uint old = thresholdAmount;
    thresholdAmount = _threshold * 10**ERC20Address.decimals();
    emit UpdatedThresholdAmount(old, thresholdAmount);
  }

  // @notice this will enable publicMint()
  // ERC165 datum enableMinting() => 0xe797ec1b
  function enableMinting() public onlyOwner {
    require(address(ERC20Address) != address(0), "ERC20 token address not set.");
    require(mintFees != 0, "ERC20 token mintFee not set.");
    require(totalChoices != 0, "mintID() will fail without totalChoices set");
    require(thresholdAmount != 0, "ERC20 token threshold not set for claimNFT().");
    bool old = enableMinter;
    enableMinter = true;
    emit UpdatedMintStatus(old, enableMinter);
  }

  // @notice this will disable publicMint()
  // ERC165 datum disableMinting() => 0x7e5cd5c1
  function disableMinting() public onlyOwner {
    bool old = enableMinter;
    enableMinter = false;
    emit UpdatedMintStatus(old, enableMinter);
  }

  // @notice will set the ERC20 value of token, and emit an event
  // @param address _token - address of the token to change
  // ERC165 datum setERC20Address(address) = > 0x26a4e8d2
  function setERC20Address(address _ERC20Address) public onlyOwner {
    ERC20 old = ERC20Address;
    ERC20Address = ERC20(_ERC20Address);
    emit UpdatedERC20Address(old, ERC20Address);
  }

  // @notice this will set the base URI for tokenURI() later on
  // @param string memory _base - new IPFS string base of tokenURI
  //  remember must trail with a "/"
  // ERC165 datum setBaseURI(string) => 0x55f804b3
  function setBaseURI(string memory _base) public onlyOwner {
    string memory old = base;
    base = _base;
    emit UpdatedBaseURI(old, base);
  }

  // @notice will set the ContractURI for OpenSea
  // @param string memory _contractURI - IPFS URI for contract
  // ERC165 datum setContractURI(string) => 0x938e3d7b
  function setContractURI(string memory _contractURI) public onlyOwner {
    _setContractURI(_contractURI);
  }

  // @notice will set "team minting" by onlyOwner role
  // @param uint _amount - set number to mint
  // ERC165 datum setTeamMinting(uint256) => 0xb1362ba1
  function setTeamMinting(uint _amount) public onlyOwner {
    uint old = teamMintSize;
    teamMintSize = _amount;
    emit UpdatedTeamMintSize(old, teamMintSize);
  }

  // @notice function useful for accidental ETH transfers to contract (to user address)
  //  wraps _user in payable to fix address -> address payable
  // @param address _user - user address to input
  // @param uint _amount - amount of ETH to transfer
  // ERC165 datum sweepETHToAddress(address,uint256) => 0xccf8f511
  function sweepETHToAddress(address _user, uint _amount) public onlyOwner {
    payable(_user).transfer(_amount);
  }

  // @notice function useful for accidental ERC20 token transfers to contract 
  //  (to user address) 
  // @param address _user - user address to input
  // @param uint _amount - amount of token to transfer
  // @param address _token - token contract address
  // ERC165 datum sweepERCToAddress(address,uint256,address) => 0xe08b1b63
  function sweepERCToAddress(address _user, uint _amount, address _token) public onlyOwner {
    IERC20(_token).transferFrom(address(this), _user, _amount);
  }

  ///
  /// @dev these are all the Interface Overrides/Getters
  ///

  // @notice this is a getter for ERC20 token set for this minter
  function ERC20TokenAddress() public view returns (address) {
    return address(ERC20Address);
  }

  // @notice this is a getter for ERC20 token set for this minter
  function ERC20TokenName() public view returns (string memory) {
    return ERC20Address.name();
  }

  // @notice this is a getter for threshold amount
  function ERC20TokenThresholdAmountForClaimNFT() public view returns (uint) {
    return thresholdAmount;
  }

  // @notice solidity override for _baseURI(), used in conjunction with
  //  tokenURI() as abi.encodePacked(base, tokenID) or in this case of
  //  using ERC721URIStorage, whatever is set.
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice solidity required override for supportsInterface(bytes4)
  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721) returns (bool) {
    return (
      interfaceId == type(ERC721URIStorage).interfaceId  ||
      interfaceId == type(ContractURI).interfaceId  ||
      interfaceId == type(IMAX721).interfaceId  ||
      interfaceId == type(ReentrancyGuard).interfaceId  ||
      interfaceId == type(Ownable).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }

  // @notice will return status of Minter
  function minterStatus() external view override(IMAX721) returns (bool) {
    return enableMinter;
  }

  // @notice will return minting fees
  function minterFees() external view override(IMAX721) returns (uint) {
    return mintFees;
  }

  // @notice will return maximum mint capacity
  function minterMaximumCapacity() external view override(IMAX721) returns (uint) {
    return mintSize;
  }

  // @notice will return maximum "team minting" capacity
  function minterMaximumTeamMints() external view override(IMAX721) returns (uint) {
    return teamMintSize;
  }
  // @notice will return "team mints" left
  function minterTeamMintsRemaining() external view override(IMAX721) returns (uint) {
    return teamMintSize - _teamMintCounter.current();
  }

  // @notice will return "team mints" count
  function minterTeamMintsCount() external view override(IMAX721) returns (uint) {
    return _teamMintCounter.current();
  }

  // @notice will return current token count
  function totalSupply() external view override(IMAX721) returns (uint) {
    return _tokenIdCounter.current();
  }

  // @notice _burn override
  function _burn(uint tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  // @notice tokenURI override
  function tokenURI(uint tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }
}
