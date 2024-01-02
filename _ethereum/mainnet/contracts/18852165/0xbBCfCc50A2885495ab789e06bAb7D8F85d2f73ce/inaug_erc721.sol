// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

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

            Perpetual | by Takens Theorem | asset volume 1.0
*/

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

/* 
    controls ownership detection, mint timing and renderer contract assignment
*/
interface coordinator {function mint_takens(address minter_addr, address nft_addr, uint256 token_id) external returns (address);}

/*
    showcase() renders in tokenURI to display; renderer contract assigned to each token
*/
interface renderer {function showcase(uint256 token_id) external view returns (string memory);}

contract TTPV1 is ERC721, Ownable(msg.sender) { 

    using Counters for Counters.Counter;
    Counters.Counter private token_ids;

    address public coordinator_addr; // gatekeeper: takens collectors & mint timing
    address payable public eth_recipient; // recipient of mint fee
    uint256 mint_price = 1e16; 

    /*
        rendering contracts for each mini collection; assigned at mint
    */
    mapping (uint256 => address) public render_by_token; 
    mapping (address => address) public upgraders; // for fun

    // *****
    // WRITE
    // *****

    /* 
        mint for this contract; but assign renderer from coordinator
    */
    function mint(address minter_addr, address nft_addr, uint256 token_id) external payable {
        require(msg.value == mint_price);
        bool sent = eth_recipient.send(msg.value); // nb: EOA recipient
        require(sent);
        token_ids.increment();
        uint256 new_id = token_ids.current();
        // store rendering contract address; also checks that token is ready
        render_by_token[new_id] = coordinator(coordinator_addr).mint_takens(minter_addr, nft_addr, token_id); 
        _mint(minter_addr, new_id);
    }

    /*
        for fun, fixes
    */
    function upgrade(address render_addr, address upgrade_addr) external onlyOwner {
        upgraders[render_addr] = upgrade_addr;
    }

    function update_mint_price(uint256 new_mint_price) external onlyOwner {
        mint_price = new_mint_price;
    }

    /*
        coordinator manages takens collections, ownership, mint cycles
    */
    function update_coordinator(address new_coordinator) external onlyOwner {
        coordinator_addr = new_coordinator;
    }

    /*
        recipient of mint fee; can be changed to charity etc. (EOA's only!)
    */
    function update_recipient(address new_recipient) external onlyOwner {
        eth_recipient = payable(new_recipient);
    }

    // *****
    // READ
    // *****

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        return renderer(proc(render_by_token[token_id])).showcase(token_id);
    }

    /*
        for fun, fixes
    */
    function proc(address render_addr) public view returns (address) {
        if (upgraders[render_addr] != address(0)) {
            return upgraders[render_addr];
        } else {
            return render_addr;
        }
    }

    function totalSupply() external view returns (uint256) {
        return token_ids.current();
    }

    constructor() ERC721("Perpetual / vol. 1", "TTPV1") {
        eth_recipient = payable(msg.sender);
    }    

}
