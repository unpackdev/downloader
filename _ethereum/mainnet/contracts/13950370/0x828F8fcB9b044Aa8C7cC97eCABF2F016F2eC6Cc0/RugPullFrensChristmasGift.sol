// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EnumerableGasOptimization.sol";
import "./Strings.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

//           @@@@@@@@                                                     @@@@@@                                     
//           @@@@@@@@@@@@*                                             .@@@@@@@@@                          
//           @@@@@   @@@@@@@@                                      %@@@@@@@@@@@@                         
//             @@@@@@    @@@@@@@@@@                              ,@@@@@@@@@@@@@@@                         
//               @@@@@       @@@@@@@@@@.                       @@@@@@@  @@@@@@@@.                         
//                  @@@@@@        @@@@@@@@/                  @@@@@@/   @@@@@@@@.                          
//                     @@@@@@@@@,    &((#%  ______        #@@@@@&     @@@@@@@.                           
//                       ..@@(                   .(     .@@@@@     #@@@@@@@@                             
//                     (.                             ( @@@@@      @@@@@@@@                               
//                  ,(                                  (@@     ,@@@@@@@@.                                
//                 .                                       (  @@@@@@@@@                                   
//               .                                            *@@@@,                                     
//               (   _,.@@                                         (                                        
//              (   (   %%@                                         .                                      
//              .  /  %%%%%       &@@@@@@                           ,                                     
//             (  /  %%$%%       @@  ,%%%% ,                        ,                                     
//             (  \  %%%&       @@  %%%%%%%@                         *                                    
//             |  *  %%,        @  /%%%$%%(@                         (                                    
//           ,,    """         @@  %%%%%%%#*                         (                                    
//         @@                  @. .%%%%%% @                          (                                    
//         ##                   @   %%% @@                           (                                     
//          *                    ""...#,                             (                                     
//          (                                                      .((                                    
//           (                                                      ((.                                   
//           (                                                       (((__                                  
//           \                                                           ((___                               
//           (                                                                (/ ___                        
//           (                          C                                          (/__                   
//             \                         &                                               (__               
//             *                         \                                                  (             
//             (                         \                                                   ,            
//             (                         ,                                                     ,          
//             .                          |                                                     .          
//              *                         (                                                    (         
//              $         |                ,                                                     (        
//              .         \                 .                                                    *        
//              /         ,                                                                       *       
//              (          (                                                                       (       
//              (          (                                                                        }      
//              *           \                                                                       ,      
//              /          (                                                                             
//             (                                                                           Artist_Raimochi @2021

//    ______   _    _   ______     ______   _    _   _        _          ______  ______   ______  ______   ______  
//   | |  | \ | |  | | | | ____   | |  | \ | |  | | | |      | |        | |     | |  | \         | |  \ \ / |
//   | |__| | | |  | | | |  | |   | |__|_/ | |  | | | |   _  | |   _    | |---- | |__| |  ΞΞΞΞΞΞ | |  | | '------. 
//   |_|  \_\ \_|__|_| |_|__|_|   |_|      \_|__|_| |_|__|_| |_|__|_|   |_|     |_|  \_\  ______ |_|  |_|  ____|_/ 




contract RugPullFrensChristmasGift is ERC721EnumerableGasOptimization, EIP712 {

    using Strings for uint;

    // State variables
    // Using toggles to open/close freemint
    // ------------------------------------------------------------------------
    bool public isFreeMintActive = true; 


    // URI variables
    // ------------------------------------------------------------------------
    string private _baseTokenURI;

    // Free mint already claimed
    // ------------------------------------------------------------------------
    mapping(address => bool) public isGiftClaimed;

    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);


    // Constructor
    // ------------------------------------------------------------------------
    constructor() 
    ERC721GasOptimization("RugPullFrensChristmasGift", "RPFGIFT",0)
    EIP712("RugPullFrensChristmasGift", "1.0.0")
    {}


    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyFreeMintActive() {
        require(isFreeMintActive, "FREE_MINT_NOT_ACTIVE");
        _;
    }
    
    // Block smart contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
        _;
    }


    // free mint functions
    // ------------------------------------------------------------------------
    function isFreeMintEligible(uint256 holderLevel, bytes memory _SIGNATURE) public view returns (bool){
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address addressForFreeMint,uint256 holderLevel)"),
            _msgSender(),
            holderLevel
        ))), _SIGNATURE);
        
        return owner() == recoveredAddr;
    }

    function setFreeMintStatus(bool _isFreeMintActive) external onlyOwner {
        require(isFreeMintActive != _isFreeMintActive,"SETTING_TO_CURRENT_STATE");
        isFreeMintActive = _isFreeMintActive;
    }

    
    function mintChristmasGift(
        uint256 holderLevel,
        bytes memory _SIGNATURE
    )
        external
        onlyFreeMintActive
        callerIsUser
    {
        require(isFreeMintEligible(holderLevel, _SIGNATURE), "NOT_ELIGIBLE_FOR_FREE_MINT");
        require(!isGiftClaimed[ msg.sender ],"GIFT_ALREADY_CLAIMED");
        require(_balances[ msg.sender ]==0,"YOU_ALREADY_HAVE_GIFT");

        uint supply = totalSupply();

        if (holderLevel==8){
            for(uint i; i < 3; ++i){
                _mint( msg.sender, supply++ );
            }
        } else if (holderLevel==4){
            for(uint i; i < 2; ++i){
                _mint( msg.sender, supply++ );
            }
        } else{
            _mint( msg.sender, supply++ );
        }

        // mark address as claimed
        isGiftClaimed[ msg.sender ] = true;

    }

    
    function ownerClaimGift(uint256 quantity, address addr) external onlyOwner {
        require(_balances[ addr ] + quantity <= 3,"EXCEEDS_MAX_ALLOWED_GIFT_NUM");

        uint supply = totalSupply();

        for(uint i; i < quantity; ++i){
            _mint( addr, supply++ );
        }
        
        // mark address as claimed
        isGiftClaimed[ addr ] = true;

    }

    function setGiftClaimed(address addr,bool isClaimed) external onlyOwner {
        require(isGiftClaimed[ addr ] != isClaimed,"SET_CURRENT_STATE");

        isGiftClaimed[ addr ] = isClaimed;
    }


    // Base URI Functions
    // ------------------------------------------------------------------------
    function setURI(string calldata __tokenURI) external onlyOwner {
        _baseTokenURI = __tokenURI;
        emit BaseTokenURIChanged(__tokenURI);
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "TOKEN_NOT_EXISTS");
        
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // Internal functions
    // ------------------------------------------------------------------------
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
        if( from != address(0) ){
            --_balances[from];
        }
        
        if( to != address(0) ){
            ++_balances[to];
        }
        
    }

    // Other functions
    // ------------------------------------------------------------------------
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function contractDestruct() external onlyOwner {
        selfdestruct(payable(owner()));
    }

}