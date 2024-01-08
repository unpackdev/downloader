// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 *
 * @dev Implementation of ERC1155 + NFT Token Data 
 *
 * AccessControl 
 *   DEFAULT_ADMIN_ROLE = 0
 *   새로운 role 생성 될때마다 adminRole = 0 이된다. 
 *   따라서 자연스럽게 adminRole = DEFAULT_ADMIN_ROLE 이 된다.
 */


contract NFTBase is ERC1155, Ownable, AccessControl
{
 
    string public name;
    string public symbol;

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");        //Role Id 

    struct TokenData {
        uint256 supply;                            // NFT 공급량 
        string uri;                             // NFT url : json 화일 
        address creator;                        // 저작권자
        uint256 royaltyRatio;                      // 로열티 100% = 100
    }

    mapping(uint256 => TokenData) private _tokens;     // mapping from uint256 to nft token data 
    uint256 private _currentTokenId = 0;            // 현재 tokenId
    
    bool private _isPrivate = true;                 // private Mint 설정 - 오직 MINTER_ROLE 보유자만 가능 
    uint256 private _royaltyMinimum = 0;               // 로열티 최소값
    uint256 private _royaltyMaximum = 90;              // 로열티 최대값
    
    //event
    event Mint(uint256 id,uint256 supply, string uri, address indexed creator, uint256 royaltyRatio);
    /* keccak256 
        Mint(uint256,uint256,string,address,uint256)                : 0x21881410541b694573587a7b14f2da71c815c0d7e24797822fe90249daaf884e
        TransferSingle(address,address,address,uint256,uint256)     : 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
        RoleGranted(bytes32,address,address)                        : 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d
        RoleRevoked(bytes32,address,address)                        : 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b
    */


    constructor (string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _setupRole(DEFAULT_ADMIN_ROLE,_msgSender());        //MINTER_ROLE Amin 설정 
        addWhiteList(_msgSender());
    }
    
    /**
     * @dev setPrivateMarket : Private Market set 
     *
     * Requirements:
     *
     * - 100% 이하
     */

    function setPrivateMarket(bool isPrivate_) external onlyOwner  {
        _isPrivate = isPrivate_;
    }   
    
    function getPrivateMarket() external view returns(bool) {
        return _isPrivate;
    }
    /**
     * @dev setRoyaltyRange : Royalty Range set 
     *
     * Requirements:
     *
     *    Royalty min <= Royalty max
     *    0<= Royalty max <= 100
     */    
    function setRoyaltyRange(uint256 min,uint256 max) external {
        require(max >= min,"NFTBase/should_be_(max >= min)");
        require(max <= 100,"NFTBase/should_be_(max <= 100)"); 
        _royaltyMinimum = min;
        _royaltyMaximum = max;
    }
    
    function getRoyaltyRange() external view returns(uint256,uint256) {
        return (_royaltyMinimum,_royaltyMaximum);
    }

    /**
     * @dev addWhiteList : whitelist account add
     *
     * Requirements:
     *
     *    MINTER_ROLE을 보유하고 있지 않은 address
     *    msg_sender가 DEFAULT_ADMIN_ROLE 보유해야 
     * 
     * Event : RoleGranted
     */

    function addWhiteList(address minter) public  {
        require(!hasRole(MINTER_ROLE,minter),"NFTBase/minter_has_role_already");
        grantRole(MINTER_ROLE,minter);
    }


    /**
     * @dev removeWhiteList : whitelist account remove
     *
     * Requirements:
     *
     *    MINTER_ROLE을 보유하고 있는 address
     *    DEFAULT_ADMIN_ROLE DEFAULT_ADMIN_ROLE 보유해야 
     *
     * Event : RoleRevoked
     *
     */
    function removeWhiteList(address minter)  external {
        require(hasRole(MINTER_ROLE,minter),"NFTBase/minter_has_not_role");
        revokeRole(MINTER_ROLE,minter);
    }
    
    /**
     * @dev mint :   NFT Token 발행
     *
     * Requirements:
     *
     *    supply > 0, uri != "", creator != address(0)
     *    royalty : royalty Range안에 
     *    Private Market의 경우 msg.seder는 MINTER_ROLE을 보유해야 
     *
     * Event : TransferSingle
     */

    /**
     * Only incaseof private market, check if caller has a minter role 
     */
    function mint(uint256 supply, string memory uri, address creator, uint256 royaltyRatio) public returns(uint256 id) {
        require(supply > 0,"NFTBase/supply_is_0");
        require(!compareStrings(uri,""),"NFTBase/uri_is_empty");
        require(creator != address(0),"NFTBase/createor_is_0_address");
        require(_royaltyMinimum <= royaltyRatio && royaltyRatio <= _royaltyMaximum,"NFTBase/royalty_out_of_range");
        
        if(_isPrivate)
            require(hasRole(MINTER_ROLE,_msgSender()),"NFTBase/caller_has_not_minter_role");
        id = ++_currentTokenId;    
        
        _tokens[id].supply  = supply;
        _tokens[id].uri     = uri;
        _tokens[id].creator = creator;
        _tokens[id].royaltyRatio = royaltyRatio;
        
        ERC1155._mint(_msgSender(),id,supply,"");    // TransferSingle Event  

        emit Mint(id,supply,uri,creator,royaltyRatio);
    }
    
    /**
     * @dev uri : NFT Token uri 조회 MI
     */    
    function uri(uint256 id) external view returns (string memory) {
        return  _tokens[id].uri;
    }
    
    /**
     * @dev getCreator : NFT Creator조회 
     */        
    function getCreator(uint256 id) external view returns (address) {
        return _tokens[id].creator;
    }

    /**
     * @dev getRoyaltyRatio : NFT RoyaltyRatio 조회 
     */         
    function getRoyaltyRatio(uint256 id) external view returns (uint256) {
        return _tokens[id].royaltyRatio;
    }
    
    /**
     * @dev compareStrings : string을 암호화해서 비교 
     *   Solidiy string 비교함수 제공하지 않음 
     */
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }    

    /**
     * @dev getTokenData : TokenData Return
     */
    function getTokenData(uint256 id) external view 
        returns(
            uint256
            ,string memory
            ,address
            ,uint256) 
        {
            TokenData memory td = _tokens[id];
            return (
                td.supply
                ,td.uri
                ,td.creator
                ,td.royaltyRatio
            );
    }
}