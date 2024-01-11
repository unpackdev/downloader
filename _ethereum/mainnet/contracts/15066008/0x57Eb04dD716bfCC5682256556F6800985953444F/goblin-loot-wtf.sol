//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
       ,-, ,                 .           
        )|/  ,-. ,-. ,-. ,-. |-. ,-. ,-. 
         |\  | | ,-| | | `-. | | | | | | 
        ,' ` ' ' `-^ ' ' `-' ' ' `-' ' ' 

          *             (       %    \# *           
            **&#%   *     &          \*(&&  @***.   
             #%%&*     \      *(*   (&#%&&\#%(      
  *& (&&(  *  %&*    #       ##&*(     *&%%         
 \***&&%#   #&                %&      #&#&&         
    %&%                        (*     %#(&          
    &*  *%     %&%###%\\#*&&&&#       *  &&     **  
 * &\ &    &%&.# &@&&   .\@....@  .&      &    * *  
        .&*&\%. (**\@\%\* @  @#. (    %     *(& #*\ 
       && ............#&@\@... .&&#**  &     *&#\*  
      & #& @.........@ @* #.....**#\ \* &  #*#%     
     @@&(\&.........&.&\\(\&.....  &*  \@   ( *&  % 
     @(\\\\@&.......%&\\\\(.*.##(&%&(\\\&           
     @& @&&&@\&@@*\*(&%&&&&*\\\\(((&#\\\%*          
    #\\&\&&*\(#&&\\\#*#\&&%\\\\\#&@%&#\\&           
    @# (% .   %*& ..... ...... #  .&&((&            
     %* ...#&. * . (@. . ...*&#%%& &                
         &*..* (.@.% .%. &%.                        
          &..* \#&(\..% *& *&#(((#&#                
             @&    *#&& &#\\@&&&&&&\\&&             
                     & \%&%\\\\\\\\#&&\\\((         
                    # #(  *(%\\%#\\\\  &*#%         
                    & @  ( * *( (\ \   &\(\%        
                    &%%  & \*\ (\#&#   &. \&        
                    &&   \( *%.% *\*   ((**&        
                   *&&(   .%*%*#(#   # \***(*       
                   &&&   .&(*    ##    \&(#(&       
                   &.#     #     #     \&\\%@       
                   % (     .  (**      \@  \&       
*/

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

/*
* @author Knanshon
* @title ERC721a smart contract for goblin-loot.wtf NFT collection
* @notice Enables the minting of NFTs in the collection, and management of minting and funds
*/
contract GoblinLootWTF is ERC721A, Ownable {
    using SafeMath for uint256;

    /// @notice The total number of possible NFTs in this collection
    uint256 public constant MAX_SUPPLY = 9999;

    /// @notice Maximum number of tokens mintable in one transaction
    uint256 public constant MAX_PER_MINT = 20;

    /// @notice Number of initial tokens mintable for free
    uint256 public constant FREE_MINT_AMOUNT = 5000;

    /// @notice The mint price per token
    uint256 private _mintPrice;

    /// @notice The base token URI used as a prefix by tokenURI().
    string private _baseTokenUri;

    /// @notice Contract URI used as collection metadata
    string private _contractMetadataUri;

    /// @notice Set up the contract with defaults
    constructor() ERC721A("goblin-loot.wtf", "GOBLOOT") {
        _contractMetadataUri = "https://ipfs.io/ipfs/bafkreif7cvz266ig24yf4tutastbcug5bbiswrhzdsm637e2qmjomrgudm";
        _baseTokenUri = "https://goblin-loot-metadata-proxy.herokuapp.com/api/token-metadata/";
        _mintPrice = 0.025 ether;
    }

    /// @notice Mint using ERC721a gas optimisations
    /// @param quantity The number of consecutive NFT tokens to mint
    function mint(uint256 quantity) external payable {
        uint256 totalMinted = totalSupply();
        uint256 price = 0;
        uint256 newTotal = totalMinted.add(quantity);

        if (newTotal > FREE_MINT_AMOUNT) {
            if (totalMinted < FREE_MINT_AMOUNT ) {
                uint256 payableQuantity = newTotal.sub(FREE_MINT_AMOUNT);
                price = payableQuantity.mul(_mintPrice);
            }
            else {
                price = quantity.mul(_mintPrice);
            }
        }

        require(price <= msg.value, "Needs more moolah!");
        require(quantity > 0, "Quantity iz 1 or more innit!");
        require(quantity <= MAX_PER_MINT, "Too many you is greedy");
        require(newTotal < MAX_SUPPLY, "Not dat many iz left!");

        _safeMint(msg.sender, quantity);
    }

    /// @notice Withdraw specified funds from the contract to the sender if available
    /// @param amount The amount to withdraw
    function withdraw(uint256 amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= amount, "Insufficient funds");
        payable(msg.sender).transfer(amount);
    }

    /// @notice Receive function keeps eth sent to it 
    receive() external payable { }

    /// @notice OpenSea store-front-level metadata
    /// @return string The uri of the metadata
    function contractURI() external view returns (string memory) {
        return _contractMetadataUri;
    }

    /// @notice Get the base uri for all tokens
    /// @return string the base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    /// @notice Sets the base token uri
    /// @param baseTokenUri The base uri for all tokens
    function setBaseTokenURI(string memory baseTokenUri) external onlyOwner {
        _baseTokenUri = baseTokenUri;
    }

    /// @notice Sets the price per token
    /// @param mintPrice The mint price per token for non-free token ids
    function setMintPrice(uint256 mintPrice) external onlyOwner {
        _mintPrice = mintPrice;
    }

    /// @notice Set the store-front-level metadata uri
    /// @param contractMetadataUri The store-front-level metadata uri
    function setContractMetadataURI(string memory contractMetadataUri) external onlyOwner {
        _contractMetadataUri = contractMetadataUri;
    }
}