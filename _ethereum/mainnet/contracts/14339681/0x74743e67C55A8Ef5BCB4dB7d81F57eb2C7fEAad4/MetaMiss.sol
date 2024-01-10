// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Allowlist.sol";
import "./SalesActivation.sol";

// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+??+;;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+#?+S%;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;#%..:@*;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;?#,...S%;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;++**++;;;;;;;;;;;#%++.,@*;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;?#????%%%?+;;;;;;;#%%?,SS;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;*@;...:;+?S%+;;;;;S#S*S%;;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;*S%*;+%%?*%#%%SS#@@@@@?*;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;+*?%%SS#@@@@@@@@@@@?S@#?;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;?@@@@@@@@@@@@S;?@@S+;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;*@@@@@@@@@@@@@@@%%@@%;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;%@@@@@@@@@@@@@@@@@@@@+;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;S@@@@##@@@@@@@@@@@@@@*;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;S@@@@#;#@@@@@@@@@@@@@+;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;S@@@S*:;**++**+#@@@@@+;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;S@@@?,:S##:,,,:S@@@@#;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;%@@@@?*S#S**%S#@@@@@S;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;?@@@@@@@@@?S#?#@@@@@?;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;*@@@#S%*SS?+:,*@@@@@*;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;+#@@SS%%%S%;::#@@@@#+;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;+%@@@@@@@@@?S#?%S%?+;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;+#@#@@@@*+?##%S*;;*S%;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;+#SSS%@@*,:*@#@;..;,:@*;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;+S#**##S@%;;S@@@##?:+%%#+;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;%@@S?S@+;%@@@@@###@S%%?+;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;?#@#@@S#@@@S#S#%#####%%***+;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;+@@S#SS##@#%#%S%S%SSSS#S##S##%+;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;%@@%#S#@@#S%SS%%S%S%SS#SS@S@@@*;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;*%SSSS%?%##@S@S###S#S%%?%%S%?+;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+******++;;;;;;;;;;;;;;;;;;;;;;;;;;
// ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


interface MissCryptoClub {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract MetaMiss is ERC721Enumerable, Ownable, Allowlist, SalesActivation {

    using Strings for uint256;

    // base URI
    string baseTokenURI;
    // Price of each MetaMiss
    uint256 private price = 0.08 ether;
    // Maximum amount of MetaMiss in existance 
    uint256 public max_sales_miss = 10000;
    // Max presale 
    uint256 public presaleListMax = 2;
    // Presale claimed
    mapping(address => uint256) private _presaleListClaimed;
    // miss crypto contract address
    address internal misscrypto;
    // team addresses
    address miss_crypto_wallet = 0x500eB1AfC7605a4BFaa5b1e2aBC614ebef905BAF;
    // miss index
    uint256 public miss_index = 3144;
    // claim token array
    uint256[] claimedTokenTemp;
    //Event claimed
    event Claimed(uint256[] tokenId);
    //Event presale
    event Presale(uint256 quantity, address buyer);
    
    constructor(string memory tokenURI, address _missAddr, address sign_address,
    uint256 _publicSalesStartTime, uint256 _preSalesStartTime, uint256 _preSalesEndTime, uint256 _claimStartTime ) 
    ERC721("MetaMiss", "MM") Allowlist("MetaMiss","1",sign_address) 
    SalesActivation(_publicSalesStartTime,_preSalesStartTime,_preSalesEndTime,_claimStartTime) {
        setBaseURI(tokenURI);
        misscrypto = _missAddr;
    }

    /**
    * @dev Claim MetaMiss
    */
    function claimMiss(uint256[] memory tokenId) external isClaimActive() {
        uint256 missNums = MissCryptoClub(misscrypto).balanceOf(msg.sender);
        require(missNums > 0 , "Need to have one Miss in order to claim!");
        require(tx.origin == msg.sender, "Contracts not allowed to claim");
        delete claimedTokenTemp;
        for(uint i =0 ; i<tokenId.length; i++){
            require(tokenId[i] < 3144  , "The token id cannot exceed the total supply of OG Collection!");
            if( msg.sender == MissCryptoClub(misscrypto).ownerOf(tokenId[i])){
                if(!_exists(tokenId[i])){
                    _safeMint(msg.sender, tokenId[i]);
                    claimedTokenTemp.push(tokenId[i]);
                }
            }
        }
        emit Claimed(claimedTokenTemp);
    }

    
    /**
    * @dev Owner Claim MetaMiss
    */
    function ownerClaimMiss(address _to, uint256[] memory tokenId) external onlyOwner() {
        delete claimedTokenTemp;
        for(uint i =0 ; i<tokenId.length; i++){
            require(tokenId[i] < 3144  , "The token cannot exceed the total supply of OG Collection!");
            if(!_exists(tokenId[i])){
                _safeMint(_to, tokenId[i]);
                claimedTokenTemp.push(tokenId[i]);
            }
        }
        emit Claimed(claimedTokenTemp);
    }

    /**
    * @dev Presale Miss
    */
    function presale(uint256 missNumber, bytes memory _signature) public payable isPreSalesActive isSenderAllowlisted(missNumber, _signature){
        require(miss_index + missNumber <= max_sales_miss, 'Exceeds maximum MetaMiss supply');
        require(_presaleListClaimed[msg.sender] + missNumber <= presaleListMax, 'Purchase exceeds max allowed');
        require( msg.value >= price * missNumber,             "Ether sent is not correct" );
        require(tx.origin == msg.sender, "Contracts not allowed to mint");

        for (uint256 i = 0; i < missNumber; i++) {
            _safeMint(msg.sender, miss_index);
            _presaleListClaimed[msg.sender] += 1;
            miss_index ++;
        }
        emit Presale(missNumber, msg.sender);
    }

    /**
    * @dev Mint Miss
    */
    function mint(uint256 missNumber) public payable isPublicSalesActive {
        require( msg.value >= price * missNumber,             "Ether sent is not correct" );
        require( miss_index + missNumber <= max_sales_miss,      "Exceeds maximum Miss supply" );
        require(missNumber > 0, "You cannot mint 0 Miss.");
        require(missNumber <= 20, "You are not allowed to buy this many miss at once.");
        require(tx.origin == msg.sender, "Contracts not allowed");

        for (uint256 i = 0; i < missNumber; i++) {
            _safeMint( msg.sender, miss_index);
            miss_index ++;
        }
    }

    /**
    * @dev Owner Mint Miss
    */
    function ownerMint(address _to,uint256 missNumber) external onlyOwner() {
        require( miss_index + missNumber <= max_sales_miss,      "Exceeds maximum Miss supply" );

        for (uint256 i = 0; i < missNumber; i++) {
            _safeMint(_to, miss_index);
            miss_index ++;
        }
    }
    

    /**
    * @dev Change the address of MCC (Callable by owner only)
    */
    function setMissCryptoAddress(address _miss_address) public onlyOwner {
        misscrypto = _miss_address;
    }

    /**
    * @dev Change the base URI when we move IPFS (Callable by owner only)
    */
    function setBaseURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }
    
    /**
    * @dev Change the total Sales Miss
    */
    function setTotalSalesMiss(uint256 _totalMiss) public onlyOwner {
        max_sales_miss = _totalMiss;
    }

    /**
    * @dev Change the presale list max number
    */
    function setpresaleListMax(uint256 _maxPresaleListMax) public onlyOwner {
        presaleListMax = _maxPresaleListMax;
    }

    /**
    * @dev set Claim Token array
    */
    function setClaimToken(uint256[] memory _tokenArray) public onlyOwner {
        claimedTokenTemp = _tokenArray;
    }

    /**
    * @dev Set Miss Index (Callable by owner only)
    */
    function setMissIndex(uint256 _index) public onlyOwner {
        miss_index = _index;
    }

    /**
    * @dev Set Price if need to discount (Callable by owner only)
    */
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint256 _balance = address(this).balance;
        require(payable(miss_crypto_wallet).send(_balance));
    }

    function getPrice() public view returns (uint256){
        return price;
    }
    
    /**
    * @dev get Claim Token array
    */
    function getClaimToken() public view onlyOwner returns(uint256[] memory) {
        return claimedTokenTemp;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    * @dev Get all tokens of a owner provided
    */
    function getTokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
}
