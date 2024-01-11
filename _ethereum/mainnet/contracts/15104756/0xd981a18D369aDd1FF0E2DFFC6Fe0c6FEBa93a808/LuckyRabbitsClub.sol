// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//                                ',~[{{1/`         `?(?l^'                                
//                          .^l_[?I^'...'`-t,    ._*B@,'`,i[}]-l"'                          
//                         jt"l"'''.''...'''lrI  {%&B[......'`,:,%"                        
//                        ,B%`:^.............';r+%&8M'........':;v                          
//                        >B%)................'i@B8@:...........#`                          
//                        .M%@".............'>M@%#&x...........>|                          
//                         ^BWM............:&W_#xnB`..........'&'                          
//                          1#W]...........]x.^c\c}...........1_                            
//                          .M&%'..........'z`\vz%'..........^&.                            
//                           ^8#t...........`#B8&-......... .x:                            
//                            _v*;...........IBM&. ........ ;v                              
//                             x*M'...........|B:. .........W`                              
//                             'MW[........................-|                              
//                             ~&@B`. .....................&l                              
//                           'v%%@z^. ......................!x,                            
//                          ;WzMW;.........................  .-t.                          
//                         ?cuMn'............................ .^c'                          
//                        "c(cr............`>{[?(v\<`..........'^#.                        
//                        uf(W...........^j~'    'v$@n^.........^+\                        
//                       .#{W; .........<j.       .$&&B;........l.%'                        
//                       `u)@..........`W          Bzuu%....... l./!                        
//                       '&uW..........>\         "Bzxn@`.......:'{_                        
//                        Mx8.........."W`       !%j(r|W........".t!                        
//                        }u@`.^........[$v_;,I{W%vcvt8,........^.%'                        
//                        .&&1.`'........:*@B@$$BMjj*t`........'.?)                        
//                         ,M@,."^.........^_/v*uj)l'...........,*.                        
//                          ,&%,.":............................"c.                          
//                           ^#B_.'"`.........................-f.                          
//                            .]%z;...".....................Ij,                            
//                              '[8#~'............      .`?\,                              
//                                .,{#v-,'...       .`:[)!'                                
//                                    .^I-}]???]????_:`                                    

/// @title Lucky Rabbits Club
/// @notice The Lucky Rabbits Club is a collection of 7,777 utility-enabled Lucky Rabbit NFTs designed to bring you good luck.
/// @author TMT Labs - https://twitter.com/tmtlabs - tmtlab.eth

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract LuckyRabbitsClub is ERC721A, Ownable {
    using Strings for uint256;

    bool public paused = true;
    bool public revealed = false;
    uint256 public salePrice = 77700000000000000;
    uint256 public maxMintLimit = 7;
    uint256 public maxTokens = 7777;
    string public baseUri;
    string public notRevealedUri;
    address public stakingContract;

    mapping(address => uint256) public addressMintedCount;

    constructor() ERC721A("Lucky Rabbits Club", "LRC") {}

    /// @notice Change the contract state
    /// @param _paused the new state of the contract. false/0 = unpaused, true/1 = paused
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    /// @notice Set's the BaseUri for the NFTs.
    /// @dev the BaseUri is the IPFS base that stores the metadata and images
    /// @param _baseUri the new base uri
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /// @notice Set's the BaseUri for the NFTs.
    /// @dev the BaseUri is the IPFS base that stores the metadata and images
    /// @param _notRevealedUri the new not revealed uri
    function setNotRevealedUri(string memory _notRevealedUri) public onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    /// @notice Reveal's the collection
    /// @param _reveal new state of revealed,  false/0 = not-revealed, true/1 = revealed
    function reveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }

    // Override ERC721A start token from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Returns a token's metadata uri
    /// @dev Override existing erc721 function to include not revealed uri
    /// @param _tokenId TokenId for which the URI is to be returned
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        return bytes(baseUri).length > 0
            ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"))
            : "";
    }

    // Ensures common minting requirements are met
    modifier mintCheck(uint256 _mintQty) {
        require(_mintQty > 0, "Must Mint atleast 1.");
        require(_mintQty + totalSupply() <=  maxTokens, "Exceeded the maximum available tokens.");
        _;
    }

    /// @notice Public Mint
    /// @dev ensured all the mint criteria has been met and then mints the NFTs
    /// @param _qty The number of NFTs to be minted
    function luckyMint(uint256 _qty) public payable mintCheck(_qty) {
        require(!paused, "The contract is paused.");
        require(_qty <= maxMintLimit, "Exceeded the maximum mintable limit.");
        require(addressMintedCount[msg.sender] + _qty <= maxMintLimit, "Exceeded wallet mint limit.");
        require(msg.value >= _qty * salePrice, "Not enough funds to mint.");

        mint(msg.sender, _qty);
        addressMintedCount[msg.sender] =  addressMintedCount[msg.sender] + _qty;
    }

    /// @notice Mint for Owner
    /// @dev Allows the owner to mint NFTs for partners, promotions and giveaways
    /// @param _qty The number of NFTs to be minted
    function ownerMint(uint256 _qty) public onlyOwner mintCheck(_qty) {
        mint(msg.sender, _qty);
    }

    /// @notice Function that Air Drops NFTs
    /// @dev Mints and transfers an NFT to a wallet
    /// @param _address The wallet for whome to mint the NFTs
    /// @param _qty The number of NFTs to be minted
    function airDrop(address _address, uint256 _qty) public onlyOwner mintCheck(_qty) {
        mint(_address, _qty);
    }

    // Internal minting function
    function mint(address _address, uint256 _qty) internal {
        _mint(_address, _qty);
    }

    /// @notice sets the staking contract address
    /// @param _stakingContract address of staking contract
    function setStakeContract(address _stakingContract) public onlyOwner {
        stakingContract = _stakingContract;
    }

    /// @dev Preapproves staking contract without costing holder gas to approve
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {      
        if (_operator == stakingContract) {
          return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /// @notice lists all the NFTs owner by a wallet
    /// @param _owner address of wallet to check
    /// @return array of NFTs owned by the _owner
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256 mintedTokens = totalSupply();
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= mintedTokens) {
            if (ownerOf(currentTokenId) == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    /// @notice Withdraws contract balance
    /// @dev withdraws 5% of balance to TMTLabs (tmtlab.eth) and remaining to owner's address
    function withdraw() public payable onlyOwner {
    
    // Transfer 5% to TMT Labs
    (bool tmt, ) = payable(0x9c3213422b5DE9223B1cdC764e3cc17249A7c033).call{value: address(this).balance * 5 / 100}("");
    require(tmt);
    
    // Transfers remaining balance to owner.
    (bool lrc, ) = payable(owner()).call{value: address(this).balance}("");
    require(lrc);
  }
}