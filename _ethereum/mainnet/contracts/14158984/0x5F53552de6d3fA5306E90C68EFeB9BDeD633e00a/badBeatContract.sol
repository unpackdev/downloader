// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./iBadBeatContract.sol";
import "./Minting.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./ERC721.sol";

/**
 * @dev Implementation of the {IMonsterBuds} interface.
 * This Contract states the 
 *  
 */

contract BadBeatContract is  ERC721URIStorage, Ownable, IBadbeatContract {
    using Strings for uint256;
    
    // token counter
    uint256 public tokenCounter;

    // token URI
    string private beforeUri;

    string private afterUri;

    // 
    address payoutAddress1;


    //
    address payoutAddress2;

 
    // address of IMX contract
    address public imx;

    // sets the flag for BuyNFT
    bool public buyOnOff;

    // stores the blueprint for token Id
    mapping(uint256 => bytes) public blueprints;

    // structure's

    struct tokenDetails{
        uint256 noOfTokens;
        bytes32 signKey;
        uint256 catId;
    }


    /**
     * @dev Sets the initialization
    
     */

    // constructor initialisation section
    constructor(address _imx)  ERC721("BadBeat", "BB") {
        tokenCounter = 1;
        beforeUri = "https://api.badbeatnft.com/api/v1.0/tpa/token-uri/";
        afterUri = "";
        payoutAddress1 = payable(0x46b5a601Fe7022bfc33CfB97a3f3FE82A195827F);
        payoutAddress2 = payable(0xc08da8416EDF57E37f31C2c5C60Eba774F4Cc403);
        imx = _imx;
    } 

    // Modifiers
    
    /**
     * @dev only IMX address can call modifier.
    */

    modifier onlyIMX() {
        require(msg.sender == imx, "Function can only be called by IMX");
        _;
    }

    // functions Sections

    /**
     * @dev concates the two string and token id to create new URI. 
          *
     * @param _before token uri before part.
     * @param _after token uri after part.
     * @param _token_id token Id.
     *
     * Returns
     * - token uri
    */

    function uriConcate(string memory _before, uint256 _token_id, string memory _after) private pure returns (string memory){
        string memory token_uri = string( abi.encodePacked(_before, _token_id.toString(), _after));
        return token_uri;
    }

    /**
     * @dev update the default token Uri. 
          *
     * @param _before token uri before part.
     * @param _after token uri after part.
     *
     * Returns
     * - bool
    */

    function updateDefaultUri(string memory _before, string memory _after) external onlyOwner returns (bool){
        beforeUri = _before; // update the before uri for Badbeat
        afterUri = _after; // update the after uri for Badbeat
        return true;
    }

   
    /**
     * @dev updates the Flag of Buy NFT. 
          *
     * @param status flag of buy nft.
     *
     * Returns
     * - bool
    */

    function updateBuyOnOff(bool status) external onlyOwner returns(bool){
        buyOnOff = status;
        return true;
    }

    /**
     * @dev updates the imx address. 
          *
     * @param _imx imx address 
     *
     * Returns
     * - bool
    */

    function updateImxAddress(address _imx) external onlyOwner returns(bool){
        imx = _imx;
        return true;
    }

    
    /**
     * @dev updates the payable address. 
          *
     * @param  _payoutAddress1  address  
     * @param  _payoutAddress2  address  
     *
     * Returns
     * - bool
    */

    function updatePayoutAddress(address _payoutAddress1 , address _payoutAddress2) external onlyOwner returns(bool){
        payoutAddress1 = _payoutAddress1;
        payoutAddress2 = _payoutAddress2;
        return true;
    }


    /**
     * @dev updates the token Uri of Token Id. 
          *
     * @param id  token Id.
     *
     * Returns
     * - bool
    */

    function updateTokenURI(uint256 id) external onlyOwner returns(bool){
        string memory _uri = uriConcate(beforeUri, id, afterUri);
        _setTokenURI(id, _uri);
        return true;
    }

    /**
     * @dev creating new NFT on immutable x. 
     *
     * @param tokens  token details.
     * @param signature signature to verify.
     *
     * Returns
     * - bool
     *
     * Emits a {TransferEth} event.
    */

    function buyNFT(tokenDetails calldata tokens, bytes calldata signature) public payable returns(bool){
        uint256 value = msg.value; 
        require(buyOnOff == true, "NFT minting is stopped");
        
        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(owner(), tokens.signKey, signature);
        require(status == true, "You cannot mint NFT or a not whitelisted address");

        uint256 payableValue1 = uint256(30) * (msg.value)/ 100;
        payable(payoutAddress1).transfer(payableValue1);

        uint256 payableValue2 = msg.value - payableValue1;
        payable(payoutAddress2).transfer(payableValue2);
        emit TransferEth(msg.sender,payoutAddress1, payableValue1, payoutAddress2, 
        payableValue2, tokens.noOfTokens,tokens.catId,value);


        return true;
    }

    /**
     * @dev mintinf function by only IMX. 
     *
     * @param user  msg.sender.
     * @param quantity number of token amount.
     * @param mintingBlob bytes32
     *
     * Returns
     * - bool
     *
     * Emits a {AssetMinted} event.
    */    

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external onlyIMX {
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    /**
     * @dev mint NFT and set URI. 
          *
     * @param user  msg.sender.
     * @param id token id.
     *
     * Returns
     * - bool
     *
    */  

    function _mintFor(
        address user,
        uint256 id,
        bytes memory 
    ) internal {
        _safeMint(user, id, "");
        string memory _uri = uriConcate(beforeUri, id, afterUri);
       _setTokenURI(id, _uri);
    }

}