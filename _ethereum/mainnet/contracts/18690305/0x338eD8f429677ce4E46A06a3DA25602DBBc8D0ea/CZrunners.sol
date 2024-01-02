// SPDX-License-Identifier: MIT


  //                                             .    ...                                             
  //                                       .        . .                                               
  //                                       .   .*///*,..,/////   ,                                      
  //                                       *((((((((((((((((((,..                                     
  //                                     .*((((((((((((((((((((/.                                     
  //                                    ,*/(((((((((((((((((((((*                                     
  //                                    *(((((/**,,*////**,,*//(/                                     
  //                                    ,((((//*/*/**.,..***///*/                                     
  //                                  *,/((((///,**//*(////*//(/(*                                    
  //                                   /*/((((((((/*/#((//((((/(**                                    
  //                                    /#(((/(/////***/////((((*                                     
  //                                       ((//(////*,***(//(((                                       
  //                                       /(((/(////(((/////((                                       
  //                                        (////(((///((((/(                                         
  //                                        (//****//**///*(                                          
  //                                       /((///******//((( .                                        
  //                                  .%    *((((////((//((*   .                                      
  //                            ..      %     .(((/////((*     #                                      
  //             .        ...  .          %      .###((,      (          .                            
  //                  ..                   /     *  ,                                                
  //                 ...                      .    ,./                       .                        
  //                ..                       ##((                             .                       
  //               ..                       #((*     *##(*      (%%           .                       
  //              .                       (#((*    ##((/         *%             .                     
  //             .                       %#((/  (##((.   #(#                   ..                     
  //             .                     .%#((( /#(#(* .##(((                                           
  //                                ###########(( /(((((                        ..                    
  //            ..                ###(#(((#(##(((((((                            .                    
  //            .                #((((((//(/(((((/  ../#####*                                         
  //           /#%%%%##(*,. .  (#(((((/////////(((((////.               ..***/(###                    
  //           ######(((((/*. #(((((////////////,                       ..*/(((##(/                   
  //          (((((((////*,.#(((((///////////                         .  .,*/((((((                   
  //          (((((((///*(#(/////////////                             .  .,*//(((((                   
  //          (((//((((#((///////**///,                               .  .,*///(((((                  
  //         ,*(####((((////*/*****/                                      ,*////(((((                 
  //         ((((((((((//////**///                                        ,*/////((((                 
  //         /(////////////**//*                                          .*/////(((((                
  //         ,///*************                                            .,*/////((((                
  //          (////********,                                               ,*////(((((/               
  //           ,/*****                                                     .**///((((((               
  //                                                                        ,*////(((((               
  //                                                                        .,*///(((((               
  //                                                                         ,**///((((//
                                                                                     

// Developer: Fazel Pejmanfar, Twitter: @Pejmanfarfazel

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";

contract CZRunners is ERC721A, Ownable, ReentrancyGuard, ERC2981 {
    string public baseURI;
    string public notRevealedUri;
    uint256 public cost = 0.0044 ether;
    uint256 public wlcost = 0.0025 ether;
    uint256 public maxSupply = 4444;
    uint256 public wlSupply = 2222;
    uint256 public MaxperWallet = 4;
    uint256 public MaxperWalletWl = 4;
    bool public paused = false;
    bool public revealed = false;
    bool public preSale = false;
    bool public publicSale = false;
    bytes32 public merkleRoot;
    mapping(address => uint256) public PublicMintofUser;
    mapping(address => uint256) public WhitelistedMintofUser;
    mapping(address => bool) public isMintedForFree;

    constructor(address _owner) ERC721A ("CZ Runners", "CZrunners") Ownable(_owner) {
_safeMint(_owner, 44);
}

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Public mint
    function mint(uint256 tokens) public payable nonReentrant {
        require(!paused, "Sale is paused");
        require(_msgSenderERC721A() == tx.origin, "BOTS Are not Allowed");
        require(publicSale, "Public Sale Hasn't started yet");
        require(tokens <= MaxperWallet, "max mint amount per tx exceeded");
        require(totalSupply() + tokens <= maxSupply, "Soldout");
        require(
            PublicMintofUser[_msgSenderERC721A()] + tokens <= MaxperWallet,
            "Max NFT Per Wallet exceeded"
        );
        require(msg.value >= cost * tokens, "insufficient funds");

        PublicMintofUser[_msgSenderERC721A()] += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev presale mint for whitelisted users
    function presalemint(uint256 tokens, bytes32[] calldata merkleProof)
        public
        payable
        nonReentrant
    {
        require(!paused, "Sale is paused");
        require(preSale, "Presale Hasn't started yet");
        require(_msgSenderERC721A() == tx.origin, "BOTS Are not Allowed");
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You are not Whitelisted"
        );
        require(
            WhitelistedMintofUser[_msgSenderERC721A()] + tokens <=
                MaxperWalletWl,
            "Max NFT Per Wallet exceeded"
        );
        require(tokens <= MaxperWalletWl, "max mint per Tx exceeded");
        require(
            totalSupply() + tokens <= wlSupply,
            "Whitelist MaxSupply exceeded"
        );

        if (!isMintedForFree[_msgSenderERC721A()]) {
            uint256 pricetopay = tokens - 1;
            require(msg.value >= wlcost * pricetopay, "insufficient funds");
            isMintedForFree[_msgSenderERC721A()] = true;
        } else {
            require(msg.value >= wlcost * tokens, "insufficient funds");
        }

        WhitelistedMintofUser[_msgSenderERC721A()] += tokens;
        _safeMint(_msgSenderERC721A(), tokens);
    }

    /// @dev use it for giveaway and team mint
    function airdrop(uint256 _mintAmount, address[] calldata destination)
        public
        onlyOwner
        nonReentrant
    {
        uint256 totalnft = _mintAmount * destination.length;
        require(
            totalSupply() + totalnft <= maxSupply,
            "max NFT limit exceeded"
        );
        for (uint256 i = 0; i < destination.length; i++) {
            _safeMint(destination[i], _mintAmount);
        }
    }

    /// @dev use it To Burn NFTs
    function burn(uint256[] calldata tokenID) public nonReentrant {
        for (uint256 id = 0; id < tokenID.length; id++) {
            require(_exists(tokenID[id]), "Burning for nonexistent token");
            require(
                ownerOf(tokenID[id]) == _msgSenderERC721A(),
                "You are not owner of this NFT"
            );
            _burn(tokenID[id]);
        }
    }

    /// @notice returns metadata link of tokenid
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /// @notice return the total number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice return all tokens owned by an address
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /// @dev to reveal collection, true for reveal
    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    /// @dev change the merkle root for the whitelist phase
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @dev change the public max per wallet
    function setMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWallet = _limit;
    }

    /// @dev change the whitelist max per wallet
    function setWlMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWalletWl = _limit;
    }

    /// @dev change the public price(amount need to be in wei)
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /// @dev change the whitelist price(amount need to be in wei)
    function setWlCost(uint256 _newWlCost) public onlyOwner {
        wlcost = _newWlCost;
    }

    /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
        maxSupply = _newsupply;
    }

    /// @dev cut the supply if we dont sold out
    function setWlsupply(uint256 _newsupply) public onlyOwner {
        wlSupply = _newsupply;
    }

    /// @dev set your baseuri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev set hidden uri
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /// @dev to pause and unpause your contract(use booleans true or false)
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /// @dev activate whitelist sale(use booleans true or false)
    function togglepreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

    /// @dev activate public sale(use booleans true or false)
    function togglepublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }

    /// @dev withdraw funds from contract
    function withdraw() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSenderERC721A()).transfer(balance);
    }

    // ERC2981 functions
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// @dev set royalty %, eg. 500 = 5%
    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
}
