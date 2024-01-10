// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// import "./console.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC721A.sol";  

contract TheTrillionaireClubNFT is ERC721A, Ownable {

    string public uri = "https://trillionaire-club.herokuapp.com/api/v1/avatars/metadata/";
    uint256 public maxSupply = 9999;
    uint256 public Public_Price = 200000000000000000;
    uint256 public Presale_Price = 150000000000000000;
    uint256 public maxPublicMintAmount = 3;
    uint256 public maxPresaleMintAmount = 3;
    uint256 public maxOgMintAmount = 5;
    uint256 public token_count = 0;
    uint256 public presale_count = 0;
    uint256 public gift_count = 0;

    uint256 public presale_list_length = 0;
    uint256 public og_list_length = 0;

    bool public PublicSaleStarted = false;
    bool public PreSaleStarted = false;
    bool public revealed = false;
    mapping(address => bool) private _presaleList;
    mapping(address => bool) private _ogList;
    mapping(address => bool) private _blackList;
    
    constructor() ERC721A("TheTrillionaireClubNFT", "TCLUB") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function changeRevealedUri(string calldata newUri) external onlyOwner {
        uri = newUri;
    }

    function changeMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function addToPresaleList(address[] calldata _addresses) public onlyOwner {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Message: Can't add a zero address"
            );
            if (_presaleList[_addresses[ind]] == false) {
                _presaleList[_addresses[ind]] = true;
                presale_list_length = presale_list_length + 1;
            }
        }
    }

    function isOnPresaleList(address _address) external view returns (bool) {
        return _presaleList[_address];
    }

    function addToOgList(address[] calldata _addresses) public onlyOwner {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Message: Can't add a zero address"
            );
            if (_ogList[_addresses[ind]] == false) {
                _ogList[_addresses[ind]] = true;
                og_list_length = og_list_length + 1;
            }
        }
        
    }

    function isOnOgList(address _address) external view returns (bool) {
        return _ogList[_address];
    }

     function isOnBlackList(address _address) external view returns (bool) {
        return _blackList[_address];
    }
    
    function preSaleHasStarted () public onlyOwner {
        PreSaleStarted = true;
        PublicSaleStarted = false;
    }


    function publicSaleHasStarted () public onlyOwner {
        PreSaleStarted = false;
        PublicSaleStarted = true;
    }

    function disableSale () public onlyOwner {
        PublicSaleStarted = false;
        PreSaleStarted = false;
    }
    

    function mintNFT(uint256 _mintAmount) public payable
    {
        if (PublicSaleStarted == false) {
            preSaleMint(_mintAmount);
        } else {
            saleMint(_mintAmount);
        }
    }

    function saleMint(uint256 _mintAmount) internal {
        uint256 supply = totalSupply();
        // require(!paused);
        uint256 maxMintAmount = maxPublicMintAmount;

        require(_blackList[msg.sender] == false, "Message: You can not mint anymore");
        require(PublicSaleStarted == true, "Message: Sale isn't started.");
        require(_mintAmount > 0, "Message: You must set an amount.");
        require(_mintAmount <= maxMintAmount, "Message: You are not allowed to mint the specified amount of tokens.");
        require(supply + _mintAmount <= maxSupply, "Message: Maximum supply reached.");
        require(msg.value == Public_Price * _mintAmount, "Message: You must pay the price.");
        
     
          _safeMint(msg.sender, _mintAmount);
          token_count = token_count + _mintAmount;
        

        _blackList[msg.sender] = true;

    }

    function preSaleMint(uint _mintAmount) internal {
        uint256 supply = totalSupply();
        uint256 maxMintAmount = 0;


        if(_ogList[msg.sender] == true){
            maxMintAmount = maxOgMintAmount;
        } else if(_presaleList[msg.sender] == true){
            maxMintAmount = maxPresaleMintAmount;
        } 
        

        require(PreSaleStarted == true, "Message: Presale isn't started.");

        require((_presaleList[msg.sender] == true || _ogList[msg.sender] == true), "Message: You are not on the presale list");
        require(_mintAmount > 0, "Message: You must set an amount.");
        require(_mintAmount <= maxMintAmount, "Message: You are not allowed to mint the specified amount of tokens.");
        require(supply + _mintAmount <= maxSupply, "Message: Maximum supply reached.");
        require(msg.value == Presale_Price * _mintAmount, "Message: You must pay the price.");
        
       
        _safeMint(msg.sender, _mintAmount);
        token_count = token_count + _mintAmount;
        presale_count = presale_count + _mintAmount;
        

        if(_ogList[msg.sender] == true){
            _ogList[msg.sender] = false;
        }
        if(_presaleList[msg.sender] == true){
            _presaleList[msg.sender] = false;
        }

    }

    function giftMint(address[] calldata _addresses) external onlyOwner {

        uint256 supply = totalSupply();
        require(supply + _addresses.length <= maxSupply, "Message: Maximum supply reached.");
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            _safeMint(_addresses[ind], 1);
            token_count = token_count + 1;
            gift_count = gift_count + 1;
        }
        
    }

    function changePublicPrice(uint256 _publicPrice) external onlyOwner {
        Public_Price = _publicPrice;
    }

    function changePresalePrice(uint256 _presalePrice) external onlyOwner {
        Presale_Price = _presalePrice;
    }

    function withdrawAll() public onlyOwner {

        uint256 _balanceOnePerc = address(this).balance * 1 / 100;
        uint256 _balanceTenPerc = address(this).balance * 10 / 100;
        uint256 _balanceEightyNinePerc = address(this).balance * 89 / 100;

        (bool designer, ) = payable(0x2D355D5eBD9437318B03aB6c64a44DB765Ab1166).call{value: _balanceOnePerc}("");
        require(designer);

        (bool developer, ) = payable(0x8818F967A6Df5fb655248564DE3aC9519cFdC779).call{value: _balanceTenPerc}("");
        require(developer);

        (bool organisation, ) = payable(0xC709e50237145f8B17251B6512B9122D9fD5f4ea).call{value: _balanceEightyNinePerc}("");
        require(organisation);

    }
}