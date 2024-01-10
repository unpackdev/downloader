// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

/*
                                                                                    .^7.            
                                                                                  ~YG7.             
                                                                              :75B@G:      :7!      
                                         :^!7?JYYYYYYJ??7!~^.             :~JG#@@@P.    :?G#?.      
                                    :!JPB&&&#&#&@@@@@@@@@&&&B5Y7!??JJJY5PB#&@&&&&Y  :~?P&&P^        
:.                              .~YG#&@@B?^:...:^7YB&&&&&&&&&&&&@@@@@@@@&&&&&&&&J~JG#&@@G^          
B#7                          :75#&@&&&B!           .5@&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&&@#J.           
!&#!~^.                  .^?P#@@&&&&&#^             .B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@B?:.!5J~.       
 J@PJ#&BP5J?!^:. .:::^~75B&@&&&&&&&&@5               Y@&&&&&&&&&&&&&&&&&&&&&&&&&&&#?~?P#@P.         
 .B&~:Y&@@@@&&#BB###&&&@@&&&&&&&&&&&&P          ^7JY.7@&&&&&&&&&&&&&&&&&&&&&&&&&&&#G#@@P~           
  !@B. ^P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&Y.YBBBJ  ^B@@&^ ?&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&J  .^^^::     
   P@Y   7#@&&&&&&&&&&&&&&&&&&&&&&&&&&5 ~GGP!~BY:~^:.:?&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#5!75#&B?~^    !
   ^&&^   :G@&&&&&&&&&&&&&&&&&&&&&&&&&Y^...  ~5Y^ :J.P@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@7    .!57
    ?@G     5@&&&&&&&&&&&&&&&&&&&&&&&&&&G:Y!....:^!G^^&&##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&Y~^   :?#@5 
     P@7     5@&&&&&&&&&&&&&&&&&&&&&&&@@@~~5?7!!!?J~ J@7.:B@&&&&&&&&&&&&&&&&&&&&&&&&&&&J^~!?YG&@&?  
     ~&#:     G&&&&&&&&&&&&&&&&&&&&&&&?7BP~:^!!~^^.:G@P.  .~P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@#B5~   
      5@5     ^&&&&&&&&&&&&&&&&&&&&&&P  .YBGY!^^~!?5J^ .^7??B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5!^:     
      ^&&~     P@&&&&&&&&&&&&&&&&&&&J  ..  :~!?YP5!.:75##GG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&G5?:     
       J@G     ?@&&&&&&&&&&&&&&&&&&&#PG#BBGPJ^..::..:~!~: .5&&&&&&&&&&&&&&&&&&&&&&&&&&&&BJ^:        
       .B@!    !&&&&&&&&&&&&&&&&&&&&&@&?:^!~:.^YB#BPY7^   ?@&&&&&&&&&&&&&&&&&&&&&&&@&&G!.           
        !@#:   ~&&&&&&&&&&&&&&&&&&&&&&&P!   !G&@&&&&@@&B?!P&&&&&&&&&&&&&&&&&&&&&&BP?!:              
         5@5   ~&&&&&&&&&&&&&&&&&&&&&&&@G:.J@&&&&&@@@@@@@@@@@@@&&&&&&&&&&@@@@&&#P7.                 
         :#&~  !@&&&&&&&&&&&&&&&&&&&&&&&&&#&@@@&#G5Y?77!!!77?Y5PGB####&&B57!!!^.                    
          ?@B. ?@&&&&&&&&&&&&&&&&&&&&&&&&@&#PJ!^.                ...::::.                           
           G@J Y@&&&&&&&&&&&&&&&&&&&&&&&#GJ^                                                        
           ~&&^G&&&&&&&&&&&&&&&&&&&&@@#PP?^                                                         
            5@GG&&@@@@@@@&&@@@@@@&#BPY?!:                                                           
            :#@?:~7?JY55PPPP55Y?!~:                                                                 
             7@#.                                                                                   
              P@Y                                                                                   
              ^&&~                                                                                  
               J@G                                                                                  
               .B@?                                                                                 
                !@#:                                                                                
                 P@5                                                                                
                 :#@!                                                                               
                  J@B.     
*/

/// @title ERC-721 token for Wicked Pirate Bone Crew.
/// @author @ItsCuzzo

contract WickedPirateBoneCrew is Ownable, ERC721A {

    using Strings for uint;

    string private _tokenURI;
    string private _contractURI;
    bytes32 private _merkleRoot;

    uint public constant MAX_SUPPLY = 9999;
    uint public constant RESERVED_TOKENS = 250;
    uint public constant WL_MAX_TOKENS = 6;
    uint public constant WL_TOKEN_PRICE = 0.07 ether;
    uint public constant PS_MAX_TOKENS = 20;
    uint public constant PS_TOKEN_PRICE = 0.08 ether;

    enum SaleState {
        PAUSED,
        WHITELIST,
        PUBLIC
    }

    SaleState public saleState;

    mapping (address => uint) public tokensClaimed;

    event Minted(address indexed _from, uint _amount);

    constructor(
        string memory tokenURI_,
        string memory contractURI_,
        address _receiver
    ) ERC721A("Wicked Pirate Bone Crew", "WPBC") {
        _tokenURI = tokenURI_;
        _contractURI = contractURI_;
        _reserveMint(_receiver);
    }

    /// @notice Function used to mint tokens during the `WHITELIST` sale state.
    /// @param numTokens The number of tokens to mint.
    /// @param merkleProof The Merkle Proof for the function caller.
    function whitelistMint(uint numTokens, bytes32[] calldata merkleProof) external payable {
        require(tx.origin == msg.sender, "Caller should not be a contract.");
        require(saleState == SaleState.WHITELIST, "Whitelist sale is not active.");
        require(WL_MAX_TOKENS >= tokensClaimed[msg.sender] + numTokens, "Token tx limit exceeded.");
        require(MAX_SUPPLY >= totalSupply() + numTokens, "Minted tokens would exceed supply.");
        require(numTokens * WL_TOKEN_PRICE == msg.value, "Incorrect Ether amount.");

		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid proof.");

        tokensClaimed[msg.sender] += numTokens;

        _safeMint(msg.sender, numTokens);

        emit Minted(msg.sender, numTokens);
    }

    /// @notice Function used to mint tokens during the `PUBLIC` sale state.
    /// @param numTokens The number of tokens to mint.
    function mint(uint numTokens) external payable {
        require(tx.origin == msg.sender, "Caller should not be a contract.");
        require(saleState == SaleState.PUBLIC, "Public sale is not active.");
        require(PS_MAX_TOKENS >= numTokens, "Token tx limit exceeded.");
        require(MAX_SUPPLY >= totalSupply() + numTokens, "Minted tokens would exceed supply.");
        require(numTokens * PS_TOKEN_PRICE == msg.value, "Incorrect Ether amount.");

        _safeMint(msg.sender, numTokens);

        emit Minted(msg.sender, numTokens);
    }

    /// @notice Function used to update the current sale state.
    /// @param newSaleState The new sale state value.
    /// @dev 0 = PAUSED, 1 = WHITELIST, 2 = PUBLIC.
    function setSaleState(uint newSaleState) external onlyOwner {
        require(uint(SaleState.PUBLIC) >= newSaleState, "Out of bounds.");
        saleState = SaleState(newSaleState);
    }

    /// @notice Function used to get the `_tokenURI` for `tokenId`.
    /// @param tokenId The `tokenId` to get the `_tokenURI` for.
    /// @return Returns the current `_tokenURI` for `tokenId`.
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(_tokenURI, tokenId.toString()));
    }

    /// @notice Function used to set a new `_tokenURI` value.
    /// @param tokenURI_ The new `_tokenURI` value.
    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    /// @notice Function used to get the current `_contractURI` value.
    /// @return Returns the current `_contractURI` value.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Function used to set a new `_contractURI` value.
    /// @param contractURI_ The new `_contractURI` value.
    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    /// @notice Function used to get the current `_merkleRoot` value.
    /// @return Returns the current `_merkleRoot` value.
    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /// @notice Function used to set a new `_merkleRoot` value.
    /// @param merkleRoot_ The new `_merkleRoot` value.
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _merkleRoot = merkleRoot_;
    }

    /// @notice Function used to withdraw contract funds.
    function withdrawBalance() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    /// @notice Function used to reserve tokens upon deployment for
    /// the team and community giveaways.
    function _reserveMint(address _to) internal {
        _safeMint(_to, RESERVED_TOKENS);
    }

}