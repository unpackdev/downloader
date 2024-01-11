// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

/// ============ Imports ============
import "./Counters.sol";
import "./ERC721.sol"; 
import "./Ownable.sol"; 

///@title LifeOutGenesis
///@notice Token ERC721 for the life Out 
contract LifeOutGenesis is ERC721, Ownable {   

    ///============================================
    ///============= Errors =======================
    
    ///@notice NFT per address limit exceeded
    ///@param user Caller address 
    ///@param balanceOf User NFT balance
    error NftLimitPerDirection(address user, uint256 balanceOf); 

    ///@notice The sent value of ETH is not correct to make the purchase
    ///@param user Caller address 
    ///@param amountSent Amount sent by the user 
    error IncorrectPayment(address user, uint256 amountSent);
   
    ///@notice No funds to transfer
    ///@param owner Caller address
    error NotFondsToTranfer(address owner);

    ///@notice Error transferring funds to account
    ///@param owner Caller address
    error UnsuccessfulPayout(address owner);

    ///@notice Invoked token number does not exist    
    error TokenDoesNotExist();
    
    ///@notice The sale not started
    ///@param user Caller address
    error SaleNotStarted(address user);

    ///@notice No token available for sale
    ///@param user Caller address
    error NftSoldOut(address user);
   

    /// ===========================================
    /// ============ Immutable storage ============
    /// @notice Available NFT supply
    uint256 public constant AVAILABLE_SUPPLY = 999;
   
    ///@notice Maximum number of nft to buy per address
    uint256 public constant LIMIT_NFT_BY_ADDRES = 3;

    /// ===========================================
    /// ============ Mutable storage ==============  
    ///@notice Type of variable used for handling numeric sequences
    using Counters for Counters.Counter;

    ///@notice String with the base for the tokenURI
    string public baseURI;   

    ///@notice used to know if the sale of NFT has started
    bool public startSale;   

     /// @notice Cost to mint each NFT 
    uint256 public mintCost;
 
    /// @notice Number of NFTs minted
    Counters.Counter public tokenIdCounter;    

    
    /// ======================================================
    /// ============ Constructor =============================
    constructor() ERC721("Life Out Genesis", "LOFG") {

        tokenIdCounter.increment();
        baseURI = "ipfs://QmamB3AZV9LtsfxTS2tCjJ9ckkAj3iYwXP9rMQojyrk5gH/";   
        mintCost = 0.3 ether;
    }

    /// ========================================================
    /// ============= Event ====================================
    /// @notice Emitted after a successful Withdraw Proceeds
    /// @param owner Address of owner 
    /// @param amount Amount of proceeds claimed by owner
    event WithdrawProceeds(address indexed owner, uint256 amount );

    /// @notice Emitted after a successful Mint Nft
    /// @param user Address of the user Mint
    /// @param tokenId Number token Mint
    event MintLifeOutGenesis(address indexed user, uint256 tokenId); 

    /// @notice Emitted after a successful change starSale variable
    /// @param owner Address of owner
    /// @param date Date when change 
    event SetStartSale(address indexed owner, uint256 date);

    ///@notice Emitted after a successful change mintCost variable
    ///@param owner Address of owner
    ///@param amount new value per NFT 
    event SetMintCost(address indexed owner, uint256 amount);

    
    /// =========================================================
    /// ============ Functions ==================================  

    //****************************************************** */
    // ************* functions set parameter *************** */
    ///@notice start public sale
    ///@param value value in bowling for sale
    function setStartSale(bool value) external onlyOwner {
        startSale = value;
        emit SetStartSale(msg.sender, block.timestamp);
    }
  
    ///@notice Sets baseURI of NFT
    ///@param setBaseUri string whit baseURI
    function setBaseURI(string memory setBaseUri) external onlyOwner {
        baseURI = setBaseUri;
    }

    ///@notice Allows set price mint by owner
    ///@param newMintCost value price mint
    function setMintCost(uint256 newMintCost) external onlyOwner {
        mintCost = newMintCost;
        emit SetMintCost(msg.sender, newMintCost);
    }

    ///@notice return tokenURI for each token
    ///@param tokenId the id of the token you want the tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {   
        if (!_exists(tokenId)){
            revert TokenDoesNotExist();
        }     
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }
      
  
    //************************************************* */
    //************** mint function********************* */  
    ///@notice buy from NFT
    ///@param amountNft number of NFTs you want to buy
    function mintLifeOutGenesis(uint256 amountNft) external payable {

        if(!startSale){
            revert SaleNotStarted(msg.sender);
        }

        if (msg.value != mintCost * amountNft) {
            revert IncorrectPayment(msg.sender, msg.value);
        }

        if(amountNft > (LIMIT_NFT_BY_ADDRES - balanceOf(msg.sender))){
            revert NftLimitPerDirection(
                msg.sender,
                balanceOf(msg.sender));                
        }                

        for(uint i; i < amountNft ; i++){
            
            if(tokenIdCounter.current() > AVAILABLE_SUPPLY){
                revert NftSoldOut(msg.sender);
            }   

            emit MintLifeOutGenesis(msg.sender, tokenIdCounter.current());            
            _safeMint(msg.sender, tokenIdCounter.current());        
            tokenIdCounter.increment();
        }          
   
    }

    //****************************************************** */
    //***************** withdraw function******************* */
    ///@notice withdraw funds by owner
    function withdrawProceeds() external onlyOwner {
        uint256 balance = address(this).balance;        
        if (balance == 0){ revert NotFondsToTranfer(msg.sender);}        
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        if (!sent){revert UnsuccessfulPayout(msg.sender);}        
        emit WithdrawProceeds(msg.sender, balance);
    }    
}