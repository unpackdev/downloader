// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

// @name:    Jungle POP
// @symbol:  JPOP
// @desc:    7,777 Jungle POP
// @project: https://twitter.com/Junglepop_NFT
// @url:     https://www.jungle-pop.io/
// @code:    MT Blockchain Services

/* * * * * * * * * * * * * * * * * * *
*      ██╗██████╗  ██████╗ ██████╗   *
*      ██║██╔══██╗██╔═══██╗██╔══██╗  *
*      ██║██████╔╝██║   ██║██████╔╝  *
* ██   ██║██╔═══╝ ██║   ██║██╔═══╝   *
* ╚█████╔╝██║     ╚██████╔╝██║       *
*  ╚════╝ ╚═╝      ╚═════╝ ╚═╝       *
* * * * * * * * * * * * * * * * * * */

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract JunglePOP is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  /* set variables */
  bool public collection_revealed = false;
  bool public free_whitelist_sale = false;
  bool public whitelist_sale = false;
  bool public public_sale = false;
  uint256 public cost = 0.065 ether;
  uint256 public max_supply = 7777;
  uint256 public max_per_wallet = 2;
  uint256 public free_max_per_wallet = 1;
  bytes32 public free_whitelist_merkle_root;
  bytes32 public whitelist_merkle_root;
  string public baseURI;
  string public revealURI = "https://ipfs.io/ipfs/QmfVJp62ATN4k63mBbe7YkYZnd3nwnh5TEhYn59ntqDjUD";

  /* address mapping */
  mapping(address => uint256) block_address;
  mapping(address => uint256) public wallet_minted;
  mapping(address => uint256) public free_wallet_minted;
  mapping(address => bool) public is_whitelisted;
  
  /* constructor */
  constructor() ERC721A("JunglePOP", "JPOP") {}

  /* secure buy */
  modifier saleModifier(uint8 purchase_type) {
    require(tx.origin == msg.sender, "contracts_not_allowed_to_mint");
    require(block_address[msg.sender] < block.timestamp, "no_mint_on_the_same_block");

    if(purchase_type == 1) {
      require(free_whitelist_sale, "free_whitelist_sale_not_activated");
    } 

    if(purchase_type == 2) {
      require(whitelist_sale, "whitelist_sale_not_activated");
    } 

    if(purchase_type == 3) {
      require(public_sale, "public_sale_not_activated");
    }
    _;
  }

  /* free whitelist sale */
  function freeWhitelistBuy(uint256 _token_amount, bytes32[] calldata _merkle_proof) external payable saleModifier(1) nonReentrant {
    uint256 supply = totalSupply();
    require(_token_amount > 0, "quantity_is_required");
    require(_token_amount + supply <= max_supply, "max_supply_exceedeed" );
    require(free_wallet_minted[msg.sender] + _token_amount <= free_max_per_wallet, "free_max_per_wallet_exceeded");
    require(wallet_minted[msg.sender] + _token_amount <= max_per_wallet, "max_per_wallet_exceeded");

    if(!is_whitelisted[msg.sender]) {
      bytes32 leaf_node = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkle_proof, free_whitelist_merkle_root, leaf_node), "invalid_free_whitelist_merkle_proof");
    }

    free_wallet_minted[msg.sender] += _token_amount;
    wallet_minted[msg.sender] += _token_amount;
    _safeMint(msg.sender, _token_amount);
  }

  /* whitelist sale */
  function whitelistBuy(uint256 _token_amount, bytes32[] calldata _merkle_proof) external payable saleModifier(2) nonReentrant {
    require(msg.value >= cost * _token_amount, "insufficient_funds");
    uint256 supply = totalSupply();
    require(_token_amount > 0, "quantity_is_required");
    require(_token_amount + supply <= max_supply, "max_supply_exceedeed" );
    require(wallet_minted[msg.sender] + _token_amount <= max_per_wallet, "max_per_wallet_exceeded");

    if(!is_whitelisted[msg.sender]) {
      bytes32 leaf_node = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkle_proof, free_whitelist_merkle_root, leaf_node), "invalid_free_whitelist_merkle_proof");
    }

    wallet_minted[msg.sender] += _token_amount;
    _safeMint(msg.sender, _token_amount);
  }

  /* public mint */
  function publicBuy(uint256 _token_amount) external payable saleModifier(3) nonReentrant {
    require(msg.value >= cost * _token_amount, "insufficient_funds");
    uint256 supply = totalSupply();
    require(_token_amount > 0, "quantity_is_required");
    require(_token_amount + supply <= max_supply, "max_supply_exceedeed" );
    require(wallet_minted[msg.sender] + _token_amount <= max_per_wallet, "max_per_wallet_exceeded");

    wallet_minted[msg.sender] += _token_amount;
    _safeMint(msg.sender, _token_amount);
  }

  /* token return */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "non_existant_token");
    if (collection_revealed) {
      return string(abi.encodePacked(baseURI, _tokenId.toString()));
    } else {
      return revealURI;
    }
  }

  /* functions */
  function set_base_uri(string memory _new_base_uri) public onlyOwner {
    baseURI = _new_base_uri;
  }

  function set_reveal_uri(string memory _new_reveal_uri) public onlyOwner {
    revealURI = _new_reveal_uri;
  }

  function set_free_whitelist_sale_state(bool _new_free_whitelist_sale_state) public onlyOwner {
    free_whitelist_sale = _new_free_whitelist_sale_state;
  }

  function set_whitelist_sale_state(bool _new_whitelist_sale_state) public onlyOwner {
    whitelist_sale = _new_whitelist_sale_state;
  }

  function set_public_sale_state(bool _new_public_sale_state) public onlyOwner {
    public_sale = _new_public_sale_state;
  }

  function set_collection_revealed(bool _new_collection_revealed_state) public onlyOwner {
    collection_revealed = _new_collection_revealed_state;
  }

  function set_max_supply(uint256 _new_max_supply) public onlyOwner {
    max_supply = _new_max_supply;
  }

  function set_cost(uint256 _new_cost) public onlyOwner {
    cost = _new_cost;
  }

  function set_max_per_wallet(uint256 _new_max_per_wallet) public onlyOwner {
    max_per_wallet = _new_max_per_wallet;
  }

  function set_free_max_per_wallet(uint256 _new_free_max_per_wallet) public onlyOwner {
    free_max_per_wallet = _new_free_max_per_wallet;
  }

  function set_free_whitelist_merkle_root(bytes32 _new_free_whitelist_merkle_root) public onlyOwner {
    free_whitelist_merkle_root = _new_free_whitelist_merkle_root;
  }

  function set_whitelist_merkle_root(bytes32 _new_whitelist_merkle_root) public onlyOwner {
    whitelist_merkle_root = _new_whitelist_merkle_root;
  }

  /* withdraw */
  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    payable(0xD45dd68C8cA3fa971Bc0e767F227C935997A7bE5).transfer(balance);
  }
}