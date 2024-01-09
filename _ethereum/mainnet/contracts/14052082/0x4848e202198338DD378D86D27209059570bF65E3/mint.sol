pragma solidity ^0.8.7;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";

interface Ipayment {
  function get_seed(uint256 seedIndex) external view returns (uint256);
}

interface IStaking {
  function stakeMany(address account, uint16[] calldata tokenIds) external;
  function randomHunterOwner(uint256 seed) external view returns (address);
}

contract MintContract is ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable  {
  using AddressUpgradeable for address;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; 
  using CountersUpgradeable for CountersUpgradeable.Counter;


  event tokenStolen (address owner,  address thief, uint256 tokenId);

  string public baseURI;
  uint256 public MAX_TOKENS;    
  uint16  public minted;                                                 

  
  mapping (address => bool) private whitelistedContracts;                        

  IStaking public stakingContract;                                            
  Ipayment public PaymentContract;
                         


  function initialize(uint256 _maxTokens) initializer public {

   __ERC721_init("HeadGame", "HG");
   __ERC721Enumerable_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    _pause();

    MAX_TOKENS = _maxTokens;

  }


  
  function mint(address recipient) external payable whenNotPaused {
    address msgSender = _msgSender();
    require(minted + 1 <= MAX_TOKENS, "All tokens minted");
    require(whitelistedContracts[msgSender], "Only admins can call this");                                  
    minted++;
    
    if (tx.origin != recipient && recipient != address(stakingContract))  emit tokenStolen(msgSender,recipient,minted);
    _safeMint(recipient, minted);
    
  }

  function getTokenTraits(uint256 tokenId) public view blockExternalContracts returns (bool) {
    uint256 last_seed = PaymentContract.get_seed(tokenId);
    require(last_seed != 0, "seed is not ready");
    uint256 seed = uint256(keccak256(abi.encodePacked(last_seed,tokenId)));   
    return (seed & 0xFFFF) % 10 != 0;
  }

  function getTokenIds(address _owner) public view blockExternalContracts returns (uint256[] memory _tokensOfOwner) {
      _tokensOfOwner = new uint256[](balanceOf(_owner));
      for (uint256 i;i<balanceOf(_owner);i++){
          _tokensOfOwner[i] = tokenOfOwnerByIndex(_owner, i);
      }
  }

  /** ERC 721 Functions  */
  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721Upgradeable) {
        if(!whitelistedContracts[_msgSender()]) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721EnumerableUpgradeable)  blockExternalContracts returns (uint256) {
    return super.tokenOfOwnerByIndex(owner, index);
  }

  function balanceOf(address owner) public view virtual override(ERC721Upgradeable) blockExternalContracts returns (uint256) {
    return super.balanceOf(owner);
  }

  function ownerOf(uint256 tokenId) public view virtual override(ERC721Upgradeable) blockExternalContracts returns (address) {
      return super.ownerOf(tokenId);
  }

  function tokenByIndex(uint256 index) public view virtual override(ERC721EnumerableUpgradeable) blockExternalContracts returns (uint256) {
    return super.tokenByIndex(index);
  }

  function safeTransferFrom(address from,address to, uint256 tokenId) public virtual override(ERC721Upgradeable){
        super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data ) public virtual override(ERC721Upgradeable) {
      super.safeTransferFrom(from, to, tokenId, _data);
  }

  /** ADMIN FUNCTIONS */

  function setBaseURI(string memory newUri) public onlyOwner {
      baseURI = newUri;
  }

  function setWhitelistContract(address contract_address, bool status) public onlyOwner{
      whitelistedContracts[contract_address] = status;
  }

  function setStaking(address _staking) external onlyOwner {
    stakingContract = IStaking(_staking);
  }


  function setInit(address _staking, address _payment) public onlyOwner {
    stakingContract = IStaking(_staking);
    PaymentContract = Ipayment(_payment);

  }
  
  function setURI(string memory _newBaseURI) external onlyOwner {
		  baseURI = _newBaseURI;
  }


  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  // Security Functions. 
  modifier requireContractsSet() {
      require(address(PaymentContract) != address(0) && address(stakingContract) != address(0), "Contracts are not set");
      _;
  }

  modifier blockExternalContracts() {
    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
      _;
      
    } else {

      _;

    }
    
  }

}