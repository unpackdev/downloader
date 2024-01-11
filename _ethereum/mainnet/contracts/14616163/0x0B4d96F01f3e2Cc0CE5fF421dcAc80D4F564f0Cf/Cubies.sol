// SPDX-License-Identifier: GPL-3.0
// Copyright (c) Cubies 2022

pragma solidity ^0.8.13;

/*
 * Import ERC721A, Ownable, MerkleProof, ReentrancyGuard, Strings
 */

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

/*
 * Create contract Cubies as ERC721A, Ownable and ReentrancyGuard
 */

contract Cubies is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

/*
 * Define default boolean values
 * @reveal : collection is revealed y/n
 */

  bool public       reveal                              = false;

/*
 * Define default integer values
 * @wl_cost : whitelist mint price (ether)
 * @pub_cost : public mint price (ether)
 * @wl_supply : whitelist mint max supply
 * @max_supply : max supply
 * @sale_mode : 0 = disabled, 1 = whitelist, 2 = public
 * @wl_max_w : cublist max per wallet
 * @pub_max_w : public max per wallet
 * @vipcub_bonus : cubyheart/cubychamp max per wallet bonus
 */

  uint256 public    wl_cost                             = 0.059 ether;
  uint256 public    pub_cost                            = 0.069 ether;
  uint256 public    wl_supply                           = 5000;
  uint256 public    max_supply                          = 7777;
  uint8 public      sale_mode                           = 0;
  uint8 public      wl_max_w                            = 2;
  uint8 public      pub_max_w                           = 3;
  uint8 public      vipcub_bonus                        = 1;

/*
 * Define default hash values
 * @cublist_hash : cublist wallets merkletree root hash
 * @cubyheart_hash : cubyheart wallets merkletree root hash
 * @cubychamp_hash : cubychamp wallets merkletree root hash
 */

  bytes32 public    cublist_hash                        = 0xcf2405bba2204e96479cd0ed572eac38ab75ce0d29d8c3d61ed5d171d761fc4b;
  bytes32 public    cubyheart_hash                      = 0xc52db4ee8e1309ba14b9dd33e08c7ce44770fc4851894e6490c0305d78c49cde;
  bytes32 public    cubychamp_hash                      = 0xb9770b6ccc60fbe5741be8d641ec439d17d85ae8ca2c8f5890b1252887d0406b;

/*
 * Define default string values
 * @baseURI : return revealed collection metadata url
 * @revealURI : return not revealed collection metadata url
 */

  string public     baseURI;
  string public     revealURI                           = "https://ipfs.io/ipfs/QmUUYLdeLoqsBkhupkprzTf4H9vhLTGp1sUWD4KGAMxmpR";

/*
 * Define integer address mapping values
 * @w_mt : sender mint amount
 * @free_w_mt : sender free mint amount
 * @allowed_free_mt : number of free mint allowed
 */

  mapping(address => uint256) public                    w_mt;
  mapping(address => uint256) public                    free_w_mt;
  mapping(address => uint256) public                    allowed_free_mt;

/*
 * Define boolean address mapping values
 * @is_cublist : is cublist member y/n 
 * @is_cubyheart : is cubyheart member y/n 
 * @is_cubychamp : is cubychamp member y/n
 */

  mapping(address => bool) public                       is_cublist;
  mapping(address => bool) public                       is_cubyheart;
  mapping(address => bool) public                       is_cubychamp;
  
/*
 * Define token constructor values
 * @name : Cubies
 * @symbol : CUB
 */

  constructor() ERC721A("Cubies", "CUB") {}

/*
 * fmint function : free mint
 * @_amount : mint quantity
 */

  function fMint(uint256 _amount) external payable nonReentrant {
    require(sale_mode > 0, "free_off");
    require(_amount > 0, "no_amount");
    require(_amount + totalSupply() <= max_supply, "sup_ex");
    require(free_w_mt[msg.sender] + _amount <= allowed_free_mt[msg.sender], "free_max_w_ex");
    free_w_mt[msg.sender] = free_w_mt[msg.sender] + _amount;
    _safeMint(msg.sender, _amount);
  }

/*
 * wlmint function : cublist
 * @_amount : mint quantity
 * @_hash : merkle leaf node hash
 */

  function wlMint(uint256 _amount, bytes32[] calldata _hash) external payable nonReentrant {
    require(sale_mode == 1, "wl_off");
    require(msg.value >= wl_cost * _amount, "ins_funds");
    require(_amount > 0, "no_amount");
    require(_amount + totalSupply() <= wl_supply , "wl_supply_ex" );
    require(w_mt[msg.sender] + _amount <= wl_max_w, "max_w_ex");
    if(!is_cublist[msg.sender]) {
      bytes32 node = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_hash, cublist_hash, node), "hash_e");
    }
    w_mt[msg.sender] = w_mt[msg.sender] + _amount;
    _safeMint(msg.sender, _amount);
  }

/*
 * chmint function : cubyheart
 * @_amount : mint quantity
 * @_hash : merkle leaf node hash
 */

  function chMint(uint256 _amount, bytes32[] calldata _hash) external payable nonReentrant {
    require(sale_mode == 1, "wl_off");
    require(msg.value >= wl_cost * _amount, "ins_funds");
    require(_amount > 0, "no_amount");
    require(_amount + totalSupply() <= wl_supply, "wl_supply_ex" );
    require(w_mt[msg.sender] + _amount <= wl_max_w + vipcub_bonus, "max_w_ex");
    if(!is_cubyheart[msg.sender]) {
      bytes32 node = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_hash, cubyheart_hash, node), "hash_e");
    }
    w_mt[msg.sender] = w_mt[msg.sender] + _amount;
    _safeMint(msg.sender, _amount);
  }

/*
 * ccmint function : cubychamp
 * @_amount : mint quantity
 * @_hash : merkle leaf node hash
 */

  function ccMint(uint256 _amount, bytes32[] calldata _hash) external payable nonReentrant {
    require(sale_mode == 1, "wl_off");
    require(msg.value >= wl_cost * _amount, "ins_funds");
    require(_amount > 0, "no_amount");
    require(_amount + totalSupply() <= wl_supply, "wl_supply_ex" );
    require(w_mt[msg.sender] + _amount <= wl_max_w + vipcub_bonus, "max_w_ex");
    if(!is_cubychamp[msg.sender]) {
      bytes32 node = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_hash, cubychamp_hash, node), "hash_e");
    }
    w_mt[msg.sender] = w_mt[msg.sender] + _amount;
    _safeMint(msg.sender, _amount);
  }

/*
 * pubmint function : public
 * @_amount : mint quantity
 * @_hash : merkle leaf node hash
 */

  function pubMint(uint256 _amount) external payable nonReentrant {
    require(sale_mode == 2, "pub_off");
    require(msg.value >= pub_cost * _amount, "ins_funds");
    require(_amount > 0, "no_amount");
    require(_amount + totalSupply() <= max_supply, "supply_ex" );
    require(w_mt[msg.sender] + _amount <= pub_max_w, "max_w_ex");
    w_mt[msg.sender] = w_mt[msg.sender] + _amount;
    _safeMint(msg.sender, _amount);
  }

/*
 * withdraw function
 */

  function withdraw() external payable onlyOwner {
    uint256 contract_balance = address(this).balance;
    uint256 cubies_withdraw = contract_balance * 96 / 100;
    uint256 cubyheart_withdraw = contract_balance * 1 / 100;
    uint256 cubychamp_withdraw = contract_balance * 3 / 100;
    payable(0x440e464d47f7D3D4Fae74403464F9a3e04F3ee4F).transfer(cubies_withdraw);
    payable(0xf3b8816F0BA7F2692d989e5eE6Ff62D9e386D941).transfer(cubyheart_withdraw);
    payable(0x4aD2ae814E4fF1146D052847aa08f4a1949DdF47).transfer(cubychamp_withdraw);
  }

/*
 * tokenURI function
 * @_token_id : return the corresponding metadata for the token id
 */

  function tokenURI(uint256 _token_id) public view virtual override returns (string memory) {
    require(_exists(_token_id), "no_token_id");
    return reveal ? string(abi.encodePacked(baseURI, _token_id.toString())) : revealURI;
  }

/*
 * Replace boolean values
 * @set_reveal_state : reveal y/n
 */

  function set_reveal_state(bool _new_reveal_state) public onlyOwner {
    reveal = _new_reveal_state;
  }

/*
 * Replace integer values
 * @set_pub_cost : pub_cost uint256 value
 * @set_wl_supply : wl_supply uint256 value
 * @set_max_supply : max_supply uint256 value
 * @set_sale_mode : sale_mode uint256 value
 * @set_pub_max_w : pub_max_w uint8 value
 */

  function set_pub_cost(uint256 _new_pub_cost) public onlyOwner {
    pub_cost = _new_pub_cost;
  }

  function set_wl_supply(uint256 _new_wl_supply) public onlyOwner {
    wl_supply = _new_wl_supply;
  }

  function set_max_supply(uint256 _new_max_supply) public onlyOwner {
    max_supply = _new_max_supply;
  }

  function set_sale_mode(uint8 _new_sale_mode) public onlyOwner {
    sale_mode = _new_sale_mode;
  }

  function set_pub_max_w(uint8 _new_pub_max_w) public onlyOwner {
    pub_max_w = _new_pub_max_w;
  }

/*
 * Replace hash values
 * @set_cublist_hash : cublist_hash bytes32 hash
 * @set_cubyheart_hash : cubyheart_hash bytes32 hash
 * @set_cubychamp_hash : cubychamp_hash bytes32 hash
 */

  function set_cublist_hash(bytes32 _new_cublist_hash) public onlyOwner {
    cublist_hash = _new_cublist_hash;
  }

  function set_cubyheart_hash(bytes32 _new_cubyheart_hash) public onlyOwner {
    cubyheart_hash = _new_cubyheart_hash;
  }

  function set_cubychamp_hash(bytes32 _new_cubychamp_hash) public onlyOwner {
    cubychamp_hash = _new_cubychamp_hash;
  }

/*
 * Reaplce string values
 * @set_base_uri : baseURI string value
 * @set_reveal_uri : revealURI string value
 */

  function set_base_uri(string memory _new_base_uri) public onlyOwner {
    baseURI = _new_base_uri;
  }

  function set_reveal_uri(string memory _new_reveal_uri) public onlyOwner {
    revealURI = _new_reveal_uri;
  }

/*
 * Replace integer mapping values
 * @edit_free_w_mt_mapping : free_w_mt[address] uint256 value
 * @edit_allowed_free_mt_mapping : allowed_free_mt[address] uint256 value
 */

  function edit_free_w_mt_mapping(address _wallet, uint256 _new_free_w_mt) public onlyOwner {
    free_w_mt[_wallet] = _new_free_w_mt;
  }

  function edit_allowed_free_mt_mapping(address _wallet, uint256 _new_allowed_free_mt) public onlyOwner {
    allowed_free_mt[_wallet] = _new_allowed_free_mt;
  }

/*
 * Address boolean mapping values edit functions
 * @edit_is_cublist : is_cublist[address] boolean value
 * @edit_is_cubyheart_state : is_cubyheart[address] boolean value
 * @edit_is_cubychamp_state : is_cubychamp[address] boolean value
 */

  function edit_is_cublist_state(address _wallet, bool _new_is_cublist_state) public onlyOwner {
    is_cublist[_wallet] = _new_is_cublist_state;
  }

  function edit_is_cubyheart_state(address _wallet, bool _new_is_cubyheart_state) public onlyOwner {
    is_cubyheart[_wallet] = _new_is_cubyheart_state;
  }

  function edit_is_cubychamp_state(address _wallet, bool _new_is_cubychamp_state) public onlyOwner {
    is_cubychamp[_wallet] = _new_is_cubychamp_state;
  }

/*
 * Burn function
 * @burn : remove a token from the supply
 */

  function burn(uint256 _token_id) public onlyOwner {
    burn(_token_id);
  }
}