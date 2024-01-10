// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./console.sol";

contract GuXeClub is ERC721, ERC721URIStorage, Pausable, AccessControl  {
    using SafeMath for uint256;
    using Strings for uint256;

    // Determine if sprout function is paused
    bool public sproutPaused;  

    bytes32 public constant URI_ROLE = keccak256("URI_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    uint256 public tokenCount;  

    // Cost to mint a GuXe in WEI
    uint256 public artistFee;

    // Initial fee to sprout a GuXe in WEI. Paid to the owner of the parent
    uint256 public initialSproutFee;

    // Sprout rate to increase sprouting fee after each sprout
    // units are in tenths of a percent so 1 => 0.1% increase
    uint256 public sproutFeeRate;

    // A mapping is a key/value map. Here we store each TokenId => sprout cost in WEI.
    mapping(uint256 => uint256) public sproutFee;   

    // Emitted in requestGuXe. Token is minted
    event RequestedGuXe(uint256 indexed requestId, uint256 indexed parentId);

    //Emitted in sproutGuXe. URI is added and frozen 
    //opensea will watch this. 
    event PermanentURI(string _value, uint256 indexed _id);

    constructor() ERC721("GuXeClub", "GUXE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_ROLE, msg.sender);
        _setupRole(MINT_ROLE, msg.sender);

        //set original artistFee to create a GuXe
        artistFee = 0.030 * 10 ** 18; //fee in WEI 0.03 eth
        //set initial fee paid to the owner of the parent 
        initialSproutFee = 0.010 * 10 ** 18; //fee in WEI 0.01 eth
        //set original sprout rate in units of a tenth of a percent        
        sproutFeeRate = 80; // 8% rate increase per sprout of parent GuXe       

        //SetTokenCount to 1
        tokenCount = 1; 
        
        //original GuXe is owned by artist    
        _safeMint(msg.sender, tokenCount);     
    }


    // mint (Mint a token in the GuXeClub contract)
    //  Anyone can call mint if they transfer the required ETH
    //  Once the token is minted payments are transferred to the owner.
    //  A RequestedGuXe event is emitted so that GuXeClub.com can
    //   generate the image and update the URI. See setURI
    function mint(uint256 parentId)
        public payable
    {
        require(sproutPaused != true, "Sprout is paused");        
        // Check if the parent GuXe exists         
        require(_exists(parentId), "Parent GuXe does not exists");

        uint256 currentSproutFee = getSproutFee(parentId);
        uint256 totalFee = artistFee.add(currentSproutFee);
        // Check if enough ETH was sent
        require(msg.value >= totalFee, "Did not provide enough ETH");

        tokenCount += 1;
        _safeMint(msg.sender, tokenCount);

        //want the request event to occur before transfer for ease workflow
        emit RequestedGuXe(tokenCount, parentId);

        //increase the sprout fee of the parent
        _incrementSproutFee(parentId);

        //transfer eth to parent owner account
        address parentOwner = ownerOf(parentId);

        //https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool sent, bytes memory data) = parentOwner.call{value: currentSproutFee}("");
        require(sent, "Failed to send Ether");              
    }    

    //Placeholder function to allow minting if we decide to update
    // mint with new implementation 
    function mintFrom(address newOwner) 
        public  
        onlyRole(MINT_ROLE)
    {
        tokenCount += 1;
        _safeMint(newOwner, tokenCount);
    }    

    // Set the URI to point a json file with metadata on the newly minted
    //  Guxe Token. The file is stored on the IPFS distributed web and is immutable.
    //  Once setURI is called for a token the URI can not be updated and 
    //  the file on the IPFS system that the token points to can be verified as
    //  unaltered as well. The json file is in a standard format used by opensea.io
    //  It contains the image uri as well as information pertaining to the rareness
    //  and limited additions of the art included in the image.
    function setURI(uint256 _tokenId, string memory _tokenURI) 
        external onlyRole(URI_ROLE)
    {
        string memory defaultURI = string(abi.encodePacked(_baseURI(), _tokenId.toString()));
        string memory currentURI = super.tokenURI(_tokenId);
        require (compareStrings(defaultURI, currentURI), "URI has already been set.");

        //update the URI
        _setTokenURI(_tokenId, _tokenURI);
        string memory finalURI = super.tokenURI(_tokenId);


        //opensea will watch this
        emit PermanentURI(finalURI, _tokenId);
    }

    // Increase the sproutFee of a parent token by sproutFeeRate
    function _incrementSproutFee(uint256 tokenId) 
        internal 
    {
        uint256 original = sproutFee[tokenId];
        if (original == 0) {
            original = initialSproutFee;
        } 
        uint256 increase = original.mul(sproutFeeRate).div(1000);
        sproutFee[tokenId] = original.add(increase);
    }

    //Allow updating of sproutFee if we need to custom adjust. 
    // SproutFee is adjusted in the mint process so MINT_ROLE is used
    function setSproutFee(uint256 tokenId, uint256 _sproutFee) public onlyRole(MINT_ROLE) {
        sproutFee[tokenId] = _sproutFee;
    }

    // Get the full price to Sprout a GuXe in WEI
    // Artist Fee + SproutFee of parent owner
    function getPrice(uint256 tokenId) public view returns(uint256) {
        return artistFee.add(getSproutFee(tokenId));
    }

    // Get the fee paid to the parent owner in WEI
    function getSproutFee(uint256 tokenId) public view returns(uint256) {
        if (sproutFee[tokenId] == 0) {
            return initialSproutFee;
        }
        return sproutFee[tokenId];
    }

    // Get the balance in the GuXeClub contract in WEI
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // General withdraw function
    function withdraw(address payee, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) { 
        (bool sent, bytes memory data) = payee.call{value: amount}("");
        require(sent, "Failed to send Ether");              
    }
    
    function updateArtistFee(uint256 _artistFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        artistFee = _artistFee;
    }    

    function updateInitialSproutFee(uint256 _initialSproutFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        initialSproutFee = _initialSproutFee;
    }           

    function updateSproutFeeRate(uint256 _sproutFeeRate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        sproutFeeRate = _sproutFeeRate;
    }  

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function setSproutPaused(bool _sproutPaused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        sproutPaused = _sproutPaused;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        sproutPaused = true;
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        sproutPaused = false;
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function compareStrings(string memory a, string memory b) pure internal returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // The following functions are overrides required by Solidity. 

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }    

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}