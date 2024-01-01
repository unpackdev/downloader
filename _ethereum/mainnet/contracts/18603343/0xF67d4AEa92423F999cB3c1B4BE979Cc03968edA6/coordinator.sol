// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*
                               5 
                                          d 
                                                   1 
                                                          0 
                                                             0 
                                                              1 
                                                           6 
                                                      0 
                                               88 
                                        16 
                               10 
                        06 
                 b5 
            d5 
        0f 
       5f8 
       f57 
          000 
             561 
                 4801 
                     0523 
                          0604 
                             0x608 
                                50033 
                                  300081 
                                   f6c634 
                                  5964736 
                                 aaacb98 
                               fb3051e1 
                            d069be33 
                          9d9d21038 
                       66e11b402 
                    f6af11ce2a 
                  884b6ffce73 
                 67358221220 
                6fea26469706 
                9050929150505 
                81846100da565b 
                35f83015261012a 
                 208201905081810 
                  92915050565b5f60 
                   0ca565b8401915050 
                   0a2565b61010781610 
                    100fe818560208601610 
                    ee8185610092565b93506 
                    6100e482610088565b6100 
                    f8301169050919050565b5f 
                    250505050565b5f601f19601 
                   0190506100a4565b5f8484015 
                  0bf578082015181840152602081 
                  092915050565b5f5b83811015610 
                 0919050565b5f82825260208201905 
                000000815250905090565b5f8151905 
                c206d69737320796f752e000000000000 
               26020017f476f6f64627965212049276c6 
               35b606060405180604001604052806017815 
               0516100429190610112565b60405180910390f 
              1461002d575b5f80fd5b61003561004b565b604 
              b5060043610610029575f3560e01c80630f59f83a 
              1d5f395ff3fe608060405234801561000f575f80fd5 
              08060405234801561000f575f80fd5b50610168806100 
             9be33fb3051e1aaacb985964736f6c634300081500330x6 
             8221220884b6ffce73f6af11ce2a66e11b4029d9d21038d06 
             5261012a81846100da565b90509291505056fea264697066735 
            a565b840191505092915050565b5f6020820190508181035f8301 
           610092565b93506100fe8185602086016100a2565b610107816100c 
           f19601f8301169050919050565b5f6100e482610088565b6100ee8185 
          151818401526020810190506100a4565b5f8484015250505050565b5f601 
          0565b5f82825260208201905092915050565b5f5b838110156100bf5780820 
         69737320796f752e000000000000000000815250905090565b5f8151905091905 
         040518060400160405280601781526020017f476f6f64627965212049276c6c206d 
       0fd5b61003561004b565b6040516100429190610112565b60405180910390f35b60606 
      561000f575f80fd5b5060043610610029575f3560e01c80630f59f83a1461002d575b5f8 
     0x608060405234801561000f575f80fd5b506101688061001d5f395ff3fe608060405234801 

            Perpetual | by Takens Theorem | coordinator contract v1.0
*/

contract IERC1155 {function balanceOf(address, uint256) external view returns (uint256){}}
contract IERC721 {function ownerOf(uint256) external view returns (address){}}

contract coordinator {

  /* 
    mint timing
  */
  uint256 public mint_period = 216000; // mint wait per token in # blocks
  uint256 public vanish_threshold = 12; // number of mint periods until contract selects among renders

  /* 
    relevant addresses, contracts where there are takens tokens
  */
  address takens = 0xA88E4a192f3ff5e46dcC96EFefB38dfEC7bb250C;
  address[] public collections; // 721 contracts with minted tokens
  address public layer_two_recipient = takens; // recipient for small fee to register L2 tokens 
  uint256 prefix = 76239962253391602540897856100159297712186421936948015313417445; // openstore takens prefix
  address openstore = 0x495f947276749Ce646f68AC8c248420045cb7b5e; // opensea's openstore 1155
  bool public openstore_on = true; // in case want to drop openstore
  address ko_v3 = 0xABB3738f04Dc2Ec20f4AE4462c3d069d02AE045B; // knownorigin v3
  address layer_two = 0xE2364f1792C397255451Ba84b942c3F903806aF0; // layer_two 721
  address gl_space = 0x9A3B5feE68ba47A49D4D560f7f8eB816a67F969b; // superrare space: g/l w/ hex6c

  /* 
    tracking standalone 721s
  */
  mapping(address => bool) public takens_nfts; // takens 721 projects
  mapping(address => mapping(uint256 => mapping(uint256 => bool))) public minted; // prior token/mint status
  
  /* 
    for knownorigin (ko) tracking    
  */
  mapping(uint256 => bool) public takens_ko_ids; // ko tokens to verify creator == takens

  /* 
    for layer_two registration tracking
  */
  mapping(uint256 => bool) public layer_two_ids; // layer_two registrations; see below
  uint256 public layer_two_reg_fee = 2e16;  // fee in wei for use in register_layer_two

  /* 
    rendering addrs sent to tokenURI on new 721 collection
  */
  address[] public renders; // rendering contracts (addr.showcase())
  uint256 public last_render; // last block # when renderer added, used for dead man's switch

  modifier takens_or_collection {
    require(msg.sender == takens || msg.sender == collections[collections.length-1]);
    _;
  }

  // *****
  // WRITE
  // *****

  /* 
    update minting period / vanish; see definition above
  */
  function update_periods(uint256 new_period, uint256 new_vanish) external takens_or_collection { 
    mint_period = new_period; 
    vanish_threshold = new_vanish; 
  } 

  /* 
    main 721 collection to mint to
  */
  function update_collection(address new_collection) external takens_or_collection {
    collections.push(new_collection);
  }

  /* 
    standalone prior 721s
  */
  function mod_takens_nft(address new_addr, bool val) external takens_or_collection {
      takens_nfts[new_addr] = val;
  }

  /* 
    de/activate os's openstore eligibility 
  */
  function toggle_openstore() external takens_or_collection {
    openstore_on = !openstore_on;
  }

  /* 
    contracts that render visuals w/ showcase(); assigned to 721 tokens
  */
  function add_render(address render_addr) external takens_or_collection {
    renders.push(render_addr);
    last_render = block.number; // for dead man's switch: # passed mint periods since
  }
  
  function del_render(uint256 index) external takens_or_collection {
    renders[index] = renders[renders.length-1];
    renders.pop();
  }

  /*
    summoned by new 721; tracks mint period + sends renderer to new 721 (see update_collection)
  */
  function mint_takens(address minter_addr, address nft_addr, uint256 token_id) external takens_or_collection returns (address) {
    require(mint_ready(minter_addr, nft_addr, token_id));
    minted[nft_addr][token_id][block.number / mint_period] = true;
    return select_render(minter_addr, nft_addr, token_id); // select & pass a rendering contract addr
  }  

  /* 
    specify knownorigin token id's made by takens
  */
  function update_ko_ids(uint256[] memory token_ids, bool val) external takens_or_collection {
    for (uint256 i = 0; i < token_ids.length; i++) {
      takens_ko_ids[token_ids[i]] = val;
    }    
  }

  /* 
    allow a layer_two token to create mints through coordinator
  */
  function register_layer_two(uint256 token_id) external payable {
    require(msg.value == layer_two_reg_fee && !layer_two_ids[token_id]);     
    layer_two_ids[token_id] = true;
    bool sent = payable(layer_two_recipient).send(msg.value); 
    require(sent);
  }

  function update_layer_two_fee(uint256 new_fee) external takens_or_collection {
    layer_two_reg_fee = new_fee; // wei
  }  

  function update_layer_two_recipient(address new_recipient) external takens_or_collection {
    layer_two_recipient = new_recipient;
  }  

  // ****
  // READ
  // ****

  /* 
    check if the contract + token from takens 
  */
  function is_takens(address nft_addr, uint256 token_id) view public returns (bool) {
    if (nft_addr == openstore && openstore_on) {
      return token_id / 1e15 == prefix; 
    } else if (nft_addr == ko_v3) {
      return takens_ko_ids[token_id];
    } else if (nft_addr == layer_two) {
      return layer_two_ids[token_id];
    } else if (nft_addr == gl_space) {
      return token_id>2 && token_id<6;
    } else {
      return takens_nfts[nft_addr]; // nb: for standard 721s, tokenid not needed
    }
  }  

  /* 
    and does the mint target own the relevant token?
  */
  function is_owner(address minter_addr, address nft_addr, uint256 token_id) view public returns (bool) {
    if (nft_addr == openstore) {
      return IERC1155(openstore).balanceOf(minter_addr, token_id) == 1;
    } else {
      return IERC721(nft_addr).ownerOf(token_id) == minter_addr;
    }
  }

  /* 
    check conjunction of is-takens + is-owner, then check if within new period for that combo
  */
  function mint_ready(address minter_addr, address nft_addr, uint256 token_id) view public returns (bool) {        
    require(is_takens(nft_addr, token_id)); 
    require(is_owner(minter_addr, nft_addr, token_id));
    return !minted[nft_addr][token_id][block.number / mint_period];
  }

  /* 
    convenience function - when next minting period, in minutes?
  */
  function next_mint_period() view external returns (uint256) {        
    return 12 * (mint_period * (block.number / mint_period + 1) - block.number) / 60;
  }

  /* 
    select most recent or (if vanished) random(-ish) renderer
  */
  function select_render(address minter_addr, address nft_addr, uint256 token_id) view public returns (address) {
    require(renders.length > 0);
    if ((block.number - last_render) / mint_period > vanish_threshold) {     
      return renders[uint256(keccak256(abi.encodePacked(minter_addr, nft_addr, token_id, block.number))) % renders.length]; // surprise-ish
    } else {      
      return renders[renders.length - 1]; // if renderer is recent, then use that one
    }
  }

}