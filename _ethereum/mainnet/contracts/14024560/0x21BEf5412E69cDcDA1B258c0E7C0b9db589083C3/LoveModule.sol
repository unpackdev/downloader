//SPDX-License-Identifier: UNLICENSE


/*
                              
    (%#(//(#      ,%(///#%,   
  %#,,,,,,,,*## #(,,,,,,,,.#( 
 (%////////////#//////////**% 
 /%///(((((Nahiko's(((((((//# 
  %#(((((((((((((((((((((((## Ò
   #%##((((((((((((((((((##/  
     %%###((((((((((((###%    
       %%###((((((((##%%      
         %%%###((###%%        
           #%%%%%%%*          
             .%%%             
            
*/


pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";

import "./INiftyForge721.sol";
import "./NFBaseModule.sol";
import "./INFModuleTokenURI.sol";
import "./INFModuleWithRoyalties.sol";

/// @title NahikosGameModule
/// @author Simon Fremaux (@dievardump) & Nahiko
contract LoveModule is
    Ownable,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties
{
    // this is because minting is secured with a Signature
    using Strings for uint256;

    // link to the skin URI
    string public skinURI;

    // link to the bones URI
    string public bonesURI;

    // contract on which this module is made to mint
    address public nftContract;

    // init the phase associated to the different phases (Skin, Flesh, Bones, Mind)
    uint _phase;

    // variable to contain the local tokenId
    uint256 public tokenId;


    address public rendererAddress;

    /// @notice constructor
    /// @param nftContract_ contract on which we mint
    /// @param rendererAddress_ contract containing the code to render the final phase
    constructor(
        address nftContract_,
        address rendererAddress_
    ) NFBaseModule("") {
        nftContract = nftContract_;
        rendererAddress = rendererAddress_;
        _phase = 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(msg.sender, tokenId_);
    }

    function tokenURI(address, uint256)
        public
        view
        override
        returns (string memory)
    {
        bytes memory uriString;

        if(_phase == 3){
            string memory rendered = ICaller(rendererAddress).render(address(this));
            uriString = abi.encodePacked("data:application/json;utf8,{\"description\":\"\xE2\x9D\xA4\xEF\xB8\x8F\",\"name\":\"Anatomy Of Love\",\"attributes\":[{\"trait_type\":\"Phase\",\"value\":\"The Mind\"}],\"image\":\"data:image/svg+xml;base64,",rendered,"\"}");
        }

        else if(_phase == 2){
            uriString = abi.encodePacked("data:application/json;utf8,{\"description\":\"\xE2\x9D\xA4\xEF\xB8\x8F\",\"name\":\"Anatomy Of Love\",\"attributes\":[{\"trait_type\":\"Phase\",\"value\":\"The Bones\"}],\"animation_url\":\"",bonesURI,"\"}");
        }
        
        else if(_phase == 1){
            uriString = abi.encodePacked("data:application/json;utf8,{\"description\":\"\xE2\x9D\xA4\xEF\xB8\x8F\",\"name\":\"Anatomy Of Love\",\"attributes\":[{\"trait_type\":\"Phase\",\"value\":\"The Skin\"}],\"image\":\"",skinURI,"\"}");
        }

        return string(uriString);
    }

    function mint() external onlyOwner {
        require(tokenId == 0, "AlreadyMinted");
        // INiftyForge721.mint(address to, string memory uri, address feeRecipient, uint256 feeAmount, address transferTo ) external returns (uint256 tokenId);
        tokenId = INiftyForge721(nftContract).mint(owner(), '',  address(0), 0, address(0));
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(uint256 tokenId_)
        public
        view
        override
        returns (address, uint256)
    {
        return royaltyInfo(msg.sender, tokenId_);
    }

    /// @inheritdoc    INFModuleWithRoyalties
    function royaltyInfo(address, uint256)
        public
        view
        override
        returns (address, uint256)
    {
        return (owner(), 500);
    }



    /// @notice Setter for nfts contract
    /// @param nftContract_ the contract containing the registry
    function setNFTContract(address nftContract_) external onlyOwner {
        nftContract = nftContract_;
    }


    /// @notice Setter for the skin URI
    /// @param skinURI_ the parameter containing the link
    function setSkinURI(string memory skinURI_) external onlyOwner {
        skinURI = skinURI_;
    }

    /// @notice Setter for the skin URI
    /// @param bonesURI_ the parameter containing the link
    function setbonesURI(string memory bonesURI_) external onlyOwner {
        bonesURI = bonesURI_;
    }

    /// @notice Setter for the phase of Anatomy
    /// @param newPhase the new phase to be put on
    function setphase(uint8 newPhase) external onlyOwner{
        _phase = newPhase;
    }

    event LoveDeclared(address indexed LoveSender, address indexed LoveReceiver);

    function DeclareMyLove(address LoveReceiver) public {  
        emit LoveDeclared(msg.sender, LoveReceiver);
        //emit both the lovers's love
    }

    /// @notice The function containing the painting of a heart on the NFT. The token is the canvas.
    function heart() public {
        require(false,"nope");
        assembly{
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff)

            sstore(69, 0x0000ff0000ff0000ff0000a00000ffffffa00000ff0000ff0000ff0000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffff)

            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000) 

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffff) //first black dot of the heart black
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) 
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff0000001111ff0000000fff) //second heart line black/red/black
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0x0000001110001111ff1111ff1111ff000000000abcffffffffffdfffffff) //third heart line black/red/red/red/black
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffff) 
            sstore(69, 0xfffffff1100110000ff0000ff0000ff0000ff0000ff001100fffffffffff) //fourth heart line black/red/red/red/red/red/black
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffff)
            sstore(69, 0x1aa1100001100ff1100ff1100ff1100ff1100ff1100ff1111ff111111fff) //fifth line black/red/red/red/red/red/red/red/black
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0x1aa1100001100ff1100ff1100ff1100ff1100ff1100ff1111ff111111fff) //sixth line same as fifth
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffff)
            sstore(69, 0x1aa1100001100ff1100ff1100ff1100111100ff1100ff1111ff111111fff) //seventh line black/red/red/red/black/red/red/red/black
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xaFFFFFF110022110022110022FFFFFF110022110022111122FFFFFFfffff) //last line white/black/black/black/white/black/black/black/white
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff) 
            
            sstore(69, 0xa00000a00000a00000ffffffffffffffffffa00000a00000a00000)

            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            sstore(69, 0xffffffffffffffffffffffffffffffffffffff)
            
        }
    }
    
}

interface ICaller{
    function render(address addressToRender) external view returns(string memory);
}
