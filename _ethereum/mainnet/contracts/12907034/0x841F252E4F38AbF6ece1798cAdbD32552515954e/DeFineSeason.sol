// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./INFTBadge721Token.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./ERC721URIStorage.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract DeFineSeason is ERC721PresetMinterPauserAutoId, ERC721URIStorage, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public constant AUTUMN = 1;
    uint256 public constant WINTER = 2;
    uint256 public constant SPRING = 3;
    uint256 public constant SUMMER = 4;
   
    uint256 public constant DFA_AMOUNT = 1000*10**18; 
    bytes32 public constant ADMIN_ROLE = keccak256("NFT721_ADMIN_ROLE");

    uint256 private _counter;          
    uint256 public created;          
    uint256 public totalBadgeNFTAmount;
    address public dfaAddress;
    address public vaultAddress;
    address public badgeNFTAddress;
    uint256 public prefix_number;
    string private _baseTokenURI;
   
    struct NFTInfo {
        uint256 seasonType; // seasonType
        uint256 dueDay;     // time for redeem;  eg. 1635609600 (2021-10-31 00:00:00)
        uint256 dfaAmount;  // DFA token amount
        uint256 price;      // USDC price for token, $2.4 per DFA token
    }  
    
    mapping(uint256 => uint256) public usd_prices;
    mapping(uint256 => NFTInfo) public nfts_info;
    mapping(uint256 => uint256) public nft_dueday;
    mapping(address => bool)    public whitelist;
    mapping(uint256 => bool)    public badgenft_claim;
    mapping(uint256 => uint256) public badgenft_mapIdx;//index => tokenId
    mapping(address => uint256) public users_claim_badgeNFT;//user address=> nft number, after claim one badge, then sub one, untill zero
    mapping (address => mapping (uint256 => uint256)) public _bscUsersAddrTofourSeasonIds;

    /**
     * @notice Event emitted when admin mint NFT.
     */
    event OnNFTTokenMinted(address indexed to, uint256 indexed nftID, NFTInfo nftinfo);

    /**
     * @notice Event emitted when user redeem & pay for the NFT.
     */
    event OnReceivedFund(address indexed payer, address indexed usdAddr, uint256 payment);

    /**
     * @notice Event emitted when admin deposit ERC20 DFA token into the pool.
     */
    event OnDepositERC20(address indexed user, uint256 amount);

    /**
     * @notice Event emitted when admin deposit Badge NFT token into the pool.
     */
    event OnDepositBadgeNFT(address indexed user, uint256 nftid);

    /**
     * @notice Event emitted when user redeem.
     */
    event OnRedeem(address indexed user, uint256 indexed nftID, uint256 dfaAmount);

    /**
     * @notice Event emitted when  award the user a Badge NFT token.
     */
    event OnAwardBadgeNFT(address indexed user, uint256 nftid);

    constructor(string  memory tokenName, 
                string  memory tokenSymbol, 
                string  memory uri, 
                address DFAAddr_, 
                address badgeNFTAddr_)
        ERC721PresetMinterPauserAutoId(tokenName, tokenSymbol, uri)
    {
        grantRole(ADMIN_ROLE, msg.sender);
        vaultAddress = msg.sender;
        badgeNFTAddress = badgeNFTAddr_;
        dfaAddress      = DFAAddr_;
        prefix_number   = 20210000;

        /*
            ID Period	Quantity	DFA	Initial Price	executive price
            1    90	     125	    1000	     99   	2
            2    180	 125     	1000	     99	    2 
            3    270	 125	    1000	     99	    2
            4    360	 125	    1000	     99	    2 
        */
        setNFTDueDay(AUTUMN, 1635638400);//2021-10-31 00:00:00 UTC+0
        setNFTDueDay(WINTER, 1643587200);//2022-01-31 00:00:00 UTC+0
        setNFTDueDay(SPRING, 1651276800);//2022-04-30 00:00:00 UTC+0
        setNFTDueDay(SUMMER, 1659225600);//2021-07-31 00:00:00 UTC+0

        setUSDPrice(AUTUMN, 2*10**6);
        setUSDPrice(WINTER, 2*10**6);
        setUSDPrice(SPRING, 2*10**6);
        setUSDPrice(SUMMER, 2*10**6);        
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a Admin");
        _;
    }
    
    /**
     * @dev allow admin set a global limit of tokens
     */
    function setPrefixNumber(uint256 _newLimit) public onlyAdmin {
        require(_newLimit > 0,"invalid limit");
        prefix_number = _newLimit;
    }

    function setDFAAddress(address _dfaAddr) public onlyAdmin {
        require(_dfaAddr != address(0), "invalid address");
        dfaAddress = _dfaAddr;
    }

     function setbadgeNFTAddress(address _badgeNFTAddr) public onlyAdmin {
        require(_badgeNFTAddr != address(0), "invalid address");
        badgeNFTAddress = _badgeNFTAddr;
    }

    function setNFTDueDay(uint256 id, uint256 _dueday) public onlyAdmin {
        nft_dueday[id] = _dueday;
    }

    function setWhiteList(address tokenAddr) public onlyAdmin {
        require(!whitelist[tokenAddr],"Already added!");
        whitelist[tokenAddr] = true;
    }

    function setUSDPrice(uint256 id, uint256 _price) public onlyAdmin {
        require(_price > 0,"invalid price");
        usd_prices[id] = _price;
    }

    function setVaultAddress(address _vault) public onlyAdmin {
        vaultAddress = _vault;
    }

    function setBaseURI(string memory _baseURI) public onlyAdmin {
        _baseTokenURI  = _baseURI;
    }

    function getAvailableDFAAmount() public view returns(uint256) {
        return IERC20(dfaAddress).balanceOf(address(this));
    }

    function getLockedDFAAmount() public view returns(uint256) {
        return DFA_AMOUNT.mul(_counter);
    }
    /**
     * @dev allow admin to get user redemption money OR other tokens
     */    
    function withdrawPlatformTokens(address token, uint256 amount) external onlyAdmin nonReentrant{
       require(token != address(0), "invalid token address");
       require(amount > 0, "invalid amount number");
       require(IERC20(token).balanceOf(address(this)) >= amount, "insufficient token");
       uint256 _amount = getAvailableDFAAmount().sub(getLockedDFAAmount());
       if(token == dfaAddress){//only for DFA
           require(_amount >= amount, "insufficient available DFA fund");
       }       
       IERC20(token).transfer(msg.sender, amount);       
    }

    /**
     * @dev allow admin mint token with {_tokenURI}
     */
    function mintNFT(uint256 seasonType, address _to, string memory _tokenURI) public onlyAdmin returns(uint256) {
        require(_to != address(0), "invalid address");
        require(seasonType < 5, "invalid seasonType");
        require(seasonType > 0, "invalid seasonType");
        require(nft_dueday[seasonType] > 0, "invalid due day");     

        created = created.add(1);
        uint256 _tokenId = prefix_number + created;
        //1. Check uri, if not input, then use baseURI;
        if(bytes(_tokenURI).length < 1){
            _tokenURI = _baseURI();
        } else {
            _setTokenURI(_tokenId, _tokenURI);
        }

        //2. Create NFT
        _mint(_to, _tokenId);       

        //4. save nft information
        NFTInfo memory nftinfo = NFTInfo(seasonType, nft_dueday[seasonType], DFA_AMOUNT, usd_prices[seasonType]);
        nfts_info[_tokenId] = nftinfo;

        emit OnNFTTokenMinted(_to, _tokenId, nftinfo);
        
        //5. increase counter of minted tokens
        _counter = _counter.add(1);
        return _tokenId;
    }  

    function redeembyERC20(uint256 tokenId, address usdAddr) external nonReentrant returns(bool){
        NFTInfo memory nftinfo = nfts_info[tokenId];
        IERC20 dfa = IERC20(dfaAddress);  
        require(_exists(tokenId) , "the token id does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only the owner can redeem");
        require(whitelist[usdAddr], "token not in whitelist");
        require(nftinfo.price > 0 , "invalid usd price");        
        require(block.timestamp < (nftinfo.dueDay +  2592000), "NFT Expired");        

        //1. Check dueday;
        require(block.timestamp >= nftinfo.dueDay, "Not yet redeemed");

        //2. get USD from the user;
        {            
            IERC20 erc20Token  = IERC20(usdAddr);
            assert(erc20Token.transferFrom(msg.sender, vaultAddress, nftinfo.price.mul(nftinfo.dfaAmount).div(10**18)));
            emit OnReceivedFund(msg.sender, usdAddr, nftinfo.price.mul(nftinfo.dfaAmount).div(10**18));
        }

        //3. burn the NFT
        _burn(tokenId);

        //4. Transfer DFA to the user  
        assert(dfa.transfer(msg.sender, nftinfo.dfaAmount));
        emit OnRedeem(msg.sender, tokenId, nftinfo.dfaAmount);       
        
        //5. give a new badge NFT for awarding user who has been redeemed.    mint directly     
        INFTBadge721Token erc721Token = INFTBadge721Token(badgeNFTAddress); 
        erc721Token.mintBadgeNFTToUser(msg.sender, tokenId, "");      
        return true;
    }

    /**
     * @dev Return nft details of this {_tokenId}
     */
    function getTokenDetail(uint256 tokenId) public view returns (NFTInfo memory) {
        return nfts_info[tokenId];
    }
   

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721PresetMinterPauserAutoId) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721, ERC721PresetMinterPauserAutoId) returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721PresetMinterPauserAutoId) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {  
        _counter.sub(1);
        ERC721URIStorage._burn(tokenId);
    }   
}
