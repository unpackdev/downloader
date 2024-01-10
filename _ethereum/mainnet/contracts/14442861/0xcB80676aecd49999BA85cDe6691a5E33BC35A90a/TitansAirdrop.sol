// SPDX-License-Identifier: MIT
pragma solidity^0.8.12;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ReentrancyGuard.sol";
import "./Titan.sol";


contract TitansAirdrop is Ownable, ReentrancyGuard {
  bool public started;
      // Being able to pause the aidrop contract (just in case)
  bool public paused;
  bool public canceled;
  bool public only_whitelisted = true;
  Titan public TitanContract;
  mapping(address => bool) public titans_whitelist;
  mapping(address => bool) public user_claimed_titan;
  mapping(address => bool) public heroes_whitelist;
  mapping(address => bool) public user_claimed_hero;
  mapping(address => uint) public titan_owner;
  mapping(uint => bool) public token_minted;

  event whitelisting_disabled(string _msg);
  event user_whitelisted(address _user);
  event bulk_user_whitelisted(address[] _users);
  event titan_claimed(address _user, uint256 _id);
  event titan_revealed(string _uri);
  event airdrop_paused(string _msg);
  event airdrop_canceled(string _msg);
  event airdrop_restarted(string _msg);

    // EIP712
    string private constant domain = "EIP712Domain(string name)";
    bytes32 public constant domainTypeHash = keccak256(abi.encodePacked(domain));
    string private constant airdropType = "Airdrop(address tokenAddress,address[] receivers,bool isERC1155,uint256[] tokenIds)";
    bytes32 public constant airdropTypeHash = keccak256(abi.encodePacked(airdropType));
    bytes32 private domainSeparator;

    
    
    //
    modifier onlyUnpaused {
      require(paused == false, "Airdrops are paused!");
      _;
    }

    ////////////////////////////////////////////////
    //////// C O N S T R U C T O R
    //
    // Initalizes the EIP712 domain separator.
    //
    constructor() {
      domainSeparator = keccak256(abi.encode(
        domainTypeHash,
        keccak256("TitansNFTAirdrop")
      ));
    TitanContract = new Titan(msg.sender);
    started = true;
    }

  function isOwner(address user) public view returns (bool _isOwner){
    if(user == owner()) {
      return true;
    } else {
      return false;
    }
  }

  function disable_whitelisting() public onlyOwner{
    only_whitelisted = false;
    emit whitelisting_disabled("Whitelisting disabled");
  }

    ////////////////////////////////////////////////
    //////// F U N C T I O N S

    //
    // Whitelist Address For titans
    //
    function whitelist_user(address _user) public onlyOwner nonReentrant {
      titans_whitelist[_user] = true;
      emit user_whitelisted(_user);
    }

     //
    // Whitelist upto 10 Addresses For titans
    //

     function whitelist_bulk_users(address[] memory _user) public onlyOwner nonReentrant {
       require(_user.length <= 10, "Only 10 or less user can be whitelisted at once");
       for(uint i = 0; i < _user.length; i++) {
        titans_whitelist[_user[i]] = true;
       }
       emit bulk_user_whitelisted(_user);
    }

    //
    // Claim a Titan
    //
    function claim_titan(uint256 _id) payable onlyUnpaused nonReentrant onlyActive onlyAllowed public {
      require(_id <= 400, "There is no titan with that id");
      require(!token_minted[_id], "This titan is already minted");
      require(msg.value >= .1 ether);
      payable(owner()).transfer(msg.value);
      TitanContract.mint(msg.sender, _id);
      titan_owner[msg.sender] = _id;
      user_claimed_titan[msg.sender] = true;
      heroes_whitelist[msg.sender] = true;
      emit titan_claimed(msg.sender, _id);
    }

    //
    // Reveal Titan Collection
    //
    function set_titan_uri(string memory _uri) onlyOwner public {
      TitanContract.setURI(_uri);
      emit titan_revealed(_uri);
    }
    
  modifier onlyActive() {
    require(started, "Airdrop is not started yet");
    require(!canceled, "Airdrop is cancelled by owner");
    _;
  }

  modifier onlyAllowed() {
     require(!only_whitelisted || titans_whitelist[msg.sender] == true, "User is not selected for airdrop");
      require(!only_whitelisted || !user_claimed_titan[msg.sender], "User already claimed a titan");
      _;
  }

    //
    // Change set paused to
    //
    function setPausedTo(bool value) public onlyOwner {
      paused = value;
      if(value == true) {
        emit airdrop_paused("Airdrop is paused");
      } else {
        emit airdrop_paused("Airdrop is unpaused");
      }
    }

    //
    // Cancel airdrop
    //
    function cancel() public onlyOwner {
      canceled = true;
      emit airdrop_canceled("Airdrop is canceled");
    }

    function restart() public onlyOwner {
      started = true;
      canceled = false;
      paused = false;
      emit airdrop_restarted("Airdrop is restarted");
    }
    //
    // Kill contract
    //
    function kill() external onlyOwner {
      selfdestruct(payable(msg.sender));
    }
}