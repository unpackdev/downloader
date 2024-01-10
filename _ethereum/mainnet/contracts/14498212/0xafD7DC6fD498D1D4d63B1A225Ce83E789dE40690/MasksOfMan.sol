//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./Utils.sol";
import "./IERC20.sol";
import "./Counters.sol";

/**

                    ███████████████
              ▓▓████████████████████████▒▒              
            ████████████████████████████████            
        ▒▒████████████████████████████████████          
      ▒▒████████████████████████████████████████        
      ████████████████████████████████████████████      
    ████████████████████████████████████████████████    
  ▓▓████████████████████████████████████████████████    
  ████████████████████████████████████████████████████  
  ████████████████████████████████████████████████████  
███████████████    █████████████████    ██████████████▓▓
███████████████████████████ ████████████████████████████
███████████████████████████ ████████████████████████████
███████████████████████████ ████████████████████████████
███████████████████████████ ████████████████████████████
███████████████████████████ ████████████████████████████
███████████████████████████ ████████████████████████████
██████████████████████████████████████████████████████▒▒
  ████████████████████████████████████████████████████  
  ███████████████████████      ███████████████████████  
    ████████████████████████████████████████████████    
    ██████████████████████████████████████████████▓▓    
      ████████████████████████████████████████████      
        ████████████████████████████████████████        
          ████████████████████████████████████          
            ██████████████████████████████▓▓            
                ████████████████████████                
                    ▒▒████████████▒▒                    

     
 */

contract MasksOfMan is ERC721Tradable, ERC2981ContractWideRoyalties {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    uint256 public mintCost = 0.1 ether;
    bool private revealed = false;
    string private prefix;
    address payable private payableAddress;
    uint256 private maxTokens = 5984;

    error InvalidMintValue();
    error OutOfStock();
    error InvalidBurnAmount();
    error TransferFailed();

    /** (-|.|-) **/

    constructor(address proxyRegistryAddress)
        ERC721Tradable("Masks Of Man", "MASKS", proxyRegistryAddress)
    {
        payableAddress = payable(msg.sender);
        _setRoyalties(msg.sender, 500);
    }

    /** |+.+| **/

    function mint(uint256 masksToMint) external payable {
        if(msg.value != mintCost * masksToMint) {
            revert InvalidMintValue();
        }
        if (_tokenIds.current() + masksToMint > maxTokens) {
            revert OutOfStock();
        }
        for (uint256 i = 0; i < masksToMint; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }
    }

    /** [*:*] **/

    function totalMinted() external view returns (uint256) {
        return _tokenIds.current();
    }

    /** {"="} **/

    function available() external view returns (uint256) {
        return maxTokens - _tokenIds.current();
    }

    /** ('o') **/

    function burnExtra(uint256 newMaxTokens) external onlyOwner {
        if (newMaxTokens > maxTokens || newMaxTokens <= _tokenIds.current()) {
            revert InvalidBurnAmount();
        }
        maxTokens = newMaxTokens;
    }

    /** | ø ø | **/

    function withdraw() external onlyOwner {
        payableAddress.transfer(address(this).balance);
    }

    /** (~v~) **/

    function withdrawToContract() external onlyOwner {
        // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = payableAddress.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /** { o o } **/

    function withdrawERC20(address tokenContract) external onlyOwner {
        IERC20 tc = IERC20(tokenContract);
        tc.transfer(payableAddress, tc.balanceOf(address(this)));
    }

    /** / ^ ^ \ **/

    function reveal(string memory prefix_) external onlyOwner {
        prefix = prefix_;
        revealed = true;
    }

    /** ( ~ o ~ ) **/

    function setPayableAddress(address payable newPayableAddress) external onlyOwner {
        _setRoyalties(newPayableAddress, 500);
        payableAddress = newPayableAddress;
    }

    /** \ o o / **/

    function setMintCost(uint256 newMintCost) external onlyOwner {
        mintCost = newMintCost;
    }

    /**  >v^v< **/

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!revealed) {
            return "ipfs://Qmb8enuJ6CXpECUHDAUNe5Ze9Xar9vo3tYiio5DdaFHaia";
        } else {
            return string(abi.encodePacked(prefix, Utils.toString(tokenId))); 
        }
    }
}
