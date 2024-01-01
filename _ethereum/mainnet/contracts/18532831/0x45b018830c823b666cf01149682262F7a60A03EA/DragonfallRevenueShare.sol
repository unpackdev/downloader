// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Strings.sol"; 


contract DragonFallRevenueShare is ERC721, Ownable(msg.sender) {

    uint256 constant public MAX_SUPPLY = 1000;
    using Strings for uint256;

    IERC20 public immutable USDT;
    uint256 public USDT_DECIMALS = 10 ** 6;
    string public baseURI;

    mapping(address => bool) public minterRole;

    struct nftIds{
        uint256 bronze;
        uint256 silver;
        uint256 gold;
        uint256 platinum;
    }

    struct prices{
        uint256 bronze;
        uint256 silver;
        uint256 gold;
        uint256 platinum;
    }

    nftIds public IDs;
    prices public Prices;    

    constructor(address _USDT, string memory baseURI_ ) ERC721("Dragonfall Revenue Share", "DRG") {
        
        IDs.platinum = 0;      
        IDs.gold = 120; 
        IDs.silver = 370;
        IDs.bronze = 625;

        Prices.platinum = 3200;
        Prices.gold = 2000;
        Prices.silver =760;
        Prices.bronze = 385;

        USDT = IERC20(_USDT);
        baseURI = baseURI_;
    }

    /*
     * @dev Mint Platinum NFTs
     * @param _amount Number of NFTs to mint
     */


    function mintPlatinum(uint256 _amount) public  {
        require(IDs.platinum + _amount <= 96, "Platinum NFTs are sold out");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 5, "Max 5 NFTs per transaction");

        bool success = USDT.transferFrom(msg.sender, address(this), Prices.platinum * _amount * USDT_DECIMALS);
        require(success, "Transfer failed");
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(msg.sender, IDs.platinum + i);
        }
        IDs.platinum += _amount;
      
    }

    /*
     * @dev Mint Gold NFTs
     * @param _amount Number of NFTs to mint
     */

    function mintGold(uint256 _amount) public  {
        require(IDs.gold + _amount <= 320, "Gold NFTs are sold out");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 5, "Max 5 NFTs per transaction");

        bool success = USDT.transferFrom(msg.sender, owner(), Prices.gold * _amount * USDT_DECIMALS);
        require(success, "Transfer failed");
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(msg.sender, IDs.gold + i);
        }
        IDs.gold += _amount;
      
    }

    /*
     * @dev Mint Silver NFTs
     * @param _amount Number of NFTs to mint
     */

    function mintSilver(uint256 _amount) public  {
        require(IDs.silver + _amount <= 574, "Silver NFTs are sold out");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 5, "Max 5 NFTs per transaction");

        bool success = USDT.transferFrom(msg.sender, owner(), Prices.silver * _amount * USDT_DECIMALS);
        require(success, "Transfer failed");
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(msg.sender, IDs.silver + i);
        }
        IDs.silver += _amount;
      
    }

    /*
     * @dev Mint Bronze NFTs
     * @param _amount Number of NFTs to mint
     */

    function mintBronze(uint256 _amount) public  {
        require(IDs.bronze + _amount <= 925, "Bronze NFTs are sold out");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 5, "Max 5 NFTs per transaction");

        bool success = USDT.transferFrom(msg.sender, owner(), Prices.bronze * _amount * USDT_DECIMALS);
        require(success, "Transfer failed");
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(msg.sender, IDs.bronze + i);
        }
        IDs.bronze += _amount;
      
    }

    /*
     * @dev Mint NFTs
     * @param _amount Number of NFTs to mint
     * @param _tier Tier of NFTs to mint
     * @param _recipient Address to mint NFTs to
     * _tier 0 = Bronze, 1 = Silver, 2 = Gold, 3 = Platinum
     */

    function ownerMint(uint256 _amount, uint256 _tier, address _recipient) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= 10, "Max 10 NFTs per transaction");
        require(_tier >= 0 && _tier <= 3, "Invalid tier");
        require(_recipient != address(0), "Invalid recipient");

        if(_tier == 0){
            require(IDs.bronze + _amount <= 925, "Bronze NFTs are sold out");
            for(uint256 i = 0; i < _amount; i++){
                _safeMint(_recipient, IDs.bronze + i);
            }
            IDs.bronze += _amount;
        }
        else if(_tier == 1){
            require(IDs.silver + _amount <= 574, "Silver NFTs are sold out");
            for(uint256 i = 0; i < _amount; i++){
                _safeMint(_recipient, IDs.silver + i);
            }
            IDs.silver += _amount;
        }
        else if(_tier == 2){
            require(IDs.gold + _amount <= 320, "Gold NFTs are sold out");
            for(uint256 i = 0; i < _amount; i++){
                _safeMint(_recipient, IDs.gold + i);
            }
            IDs.gold += _amount;
        }
        else if(_tier == 3){
            require(IDs.platinum + _amount <= 96, "Platinum NFTs are sold out");
            for(uint256 i = 0; i < _amount; i++){
                _safeMint(_recipient, IDs.platinum + i);
            }
            IDs.platinum += _amount;
        }
    }


    /*
     * @dev privileged function to mint one NFT to a specific address
     * @param to Address to mint NFT to
     * @param tokenId Tier of NFT to mint
     * _tokenId 0 = Bronze, 1 = Silver, 2 = Gold, 3 = Platinum
     */

    function mintTo(address to, uint256 tokenId) public{
        require(minterRole[msg.sender], "Caller is not a minter");
        require(tokenId >= 0 && tokenId <= 3, "Invalid tier");
        require(to != address(0), "Invalid recipient");

        if(tokenId == 0){
            require(IDs.bronze + 1 <= 925, "Bronze NFTs are sold out");
            _safeMint(to, IDs.bronze);
            IDs.bronze += 1;
        }
        else if(tokenId == 1){
            require(IDs.silver + 1 <= 574, "Silver NFTs are sold out");
            _safeMint(to, IDs.silver);
            IDs.silver += 1;
        }
        else if(tokenId == 2){
            require(IDs.gold + 1 <= 320, "Gold NFTs are sold out");
            _safeMint(to, IDs.gold);
            IDs.gold += 1;
        }
        else if(tokenId == 3){
            require(IDs.platinum + 1 <= 96, "Platinum NFTs are sold out");
            _safeMint(to, IDs.platinum);
            IDs.platinum += 1;
        }

    }

    /*
     * @dev Rescues ERC20 tokens sent to contract
     * @param _token Address of ERC20 token
     * @param _amount Amount of ERC20 token to rescue
     */
    
    function retrieveERC20(address _token, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, _amount);
    }

    /*
     * @dev Rescues ETH sent to contract
     */
    function retrieveETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
     * @dev Set the base URI for all token IDs. It is automatically added as a prefix to the value returned in {tokenURI}.
     * @param _baseURI The base URI string
     */      

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /*
     * @dev See {IERC721Metadata-tokenURI}.
     */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string.concat(baseURI_, tokenId.toString(), ".json") : "";
    }

    /*
     * @dev add or remove minter role
     * @param _minter Address of minter
     * @param _status true to add, false to remove
     */


    function setMinterRole (address _minter, bool _status) public onlyOwner {
        minterRole[_minter] = _status;
    }


}
