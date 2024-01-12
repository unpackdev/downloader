// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

/**                                                              
                                          .::::.                                          
                                      -+*########*+-                                      
                                   .=################=.                                   
                                 .=######*=-::-=++++++=:                                  
                      ......   .=######+.  .........................                      
                 .-+*#####+. .=######+. .=###########################*+-.                 
                =#######+. .=######+. .=#################################=                
               +*****+=. .=******+.  .-----------------------------=+*****+               
              -*****:  .=******+.                          :::::::.  :*****-              
              =*****  -******=.                            .=******=. .+***=              
              :*****-                                        .=******=. .+*:              
               =******+++++++++++==-:.              .:-==+++=. .=******=. .               
                :*********************+:          :+**********=. .=******=.               
             .=-  :-+*******************-        -**************=. .=******=.             
           .=****=:                =*****        *****=              .=******=.           
         .=******=.                .*****.      .*****.                .=******=.         
        =******=.                  .*****.      .*****.                  .=******=        
      :******=.                    .*****.      .*****.                    .=******:      
     :*****+.                      .*****.      .*****.                      .+*****:     
     +****=                        .*****.      .*****.                        =****+     
    .*****.                        .*****.      .*****.                        .*****.    
    .*****:                        .*****.      .*****.                        :*****.    
     =****+.                       .*****.      .*****.                       .+****=     
      +****+-                      .*****.      .*****.                      -+****+      
       =*****+-                    .*****.      .*****.                    -+*****=       
        .=*****+-                  .*****.      .*****.                  -+*****=.        
          .=*****+-                .*****.      .*****.                -+*****=.          
            .=++++++-              .+++++.      .+++++.              -++++++=.            
              .=++++++-            .+++++.      .+++++.            -++++++=.              
                .=++++++-          .+++++.      .+++++.          -++++++=.                
                  .=++++++-        .+++++.      .+++++.        -++++++=.                  
                    .=++++++-      .+++++.      .+++++.      -++++++=.                    
                      .=++++++-     +++++=      =+++++     -++++++=.                      
                        .=++++++-   :+++++-    -+++++:   -++++++=.                        
                          .=++++++-  .::::.  :++++++-  -++++++=.                          
                            .=++++++=-::::-=+++++++:  =+++++=.                            
                              .=+++++++++++++++++:  :+++++=.                              
                                 :=++++++++++=-.  :++++=:                                 
                                     ......      ....
 */

import "./ERC721A.sol";
import "./Ownable.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract SoarProof is ERC721A, Ownable, VRFConsumerBaseV2 {
    bool constant public IS_SOUL_BOUND_TOKEN = true;
    
    uint256 constant public maxSupply = 1000;
    uint256 public price = 0.65 ether;

    // 2022-07-23 09:00:00 (UTC) ~ 2022-07-23 12:00:00 (UTC)
    uint256 public startSaleTime = 1658566800;
    uint256 public endSaleTime = 1658577600;
    bool private isRevealImmediately = false;

    string public baseUri = "";
    string public uriSuffix = ".json?level=";
    bool isUriWithLevel = true;

    /** LEVEL_AMOUNT represent Level 0, 1, 2, 3
      * LEVEL_AMOUNT[0] => Level 0 is un-revealed
      * LEVEL_AMOUNT[1] => Level 1 is 50% of MaxSupply
      * LEVEL_AMOUNT[2] => Level 2 is 40% of MaxSupply
      * LEVEL_AMOUNT[3] => Level 3 is 10% of MaxSupply
      */
    uint64[4] public LEVEL_AMOUNT = [0, 500, 400, 100];
    mapping(uint16 => uint8) public tokenToLevel;
    uint16 public revealCurrentId = 0;

    event Reveal(uint256 indexed tokenId, uint8 indexed level);
    event RequestReveal(uint256 indexed currentId, uint256 indexed amount, uint256 requestId);

    // Ref: https://docs.chain.link/docs/vrf-contracts/#ethereum-mainnet
    // Mainnet LINK: 0x514910771AF9Ca656af840dff83E8264EcF986CA
    // Mainnet VRF Coordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
    // Mainnet 200 gwei Key Hash: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) payable ERC721A(_tokenName, _tokenSymbol)
      VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909) {
        COORDINATOR = VRFCoordinatorV2Interface(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        LINKTOKEN = LinkTokenInterface(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

        _mint(msg.sender, 1);
    }

    function mint(address to, uint32 _amt) external payable {
        require(block.timestamp > startSaleTime, "Mint is not started.");
        require(block.timestamp < endSaleTime, "Mint has been end");
        require(msg.value >= price * _amt, "Insufficient funds");
        require(totalSupply() + _amt <= maxSupply, "Max supply exceeded");

        _mint(to, _amt);
        if(isRevealImmediately) {
            requestRandomWords(_amt);
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(_tokenId);
        return string(abi.encodePacked(uri, uriSuffix, isUriWithLevel ? _toString(tokenToLevel[uint16(_tokenId)]) : ""));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /** SOUL BOUND TOKEN **/
    /**
     * Soul bound tokens are non-transferable identity and reputation tokens. 
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal pure override {
        bool isMinting = from == address(0);
        bool isBurning = to == address(0);
        if(!isMinting && !isBurning && IS_SOUL_BOUND_TOKEN) {
            revert("THE_NFT_IS_SOUL_BOUND_TOKEN");
        }
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if(IS_SOUL_BOUND_TOKEN) {
            revert("THE_NFT_IS_SOUL_BOUND_TOKEN");
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public override {
        if(IS_SOUL_BOUND_TOKEN) {
            revert("THE_NFT_IS_SOUL_BOUND_TOKEN");
        }
        super.approve(to, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        if (IS_SOUL_BOUND_TOKEN) {
            return false;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId, true);
    }

    /** Chainkink VRF **/
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    bytes32 keyHash;
    uint64 s_subscriptionId;

    uint32 callbackGasLimit = 2000000;
    uint16 requestConfirmations = 3;

    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        s_subscriptionId = subscriptionId;
    }

    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    function setVrfCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function requestRandomWords(uint32 numWords) internal {
        uint256 rid = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RequestReveal(revealCurrentId, numWords, rid);
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        for(uint16 index; index < randomWords.length; index++) {
            reveal(revealCurrentId + index, randomWords[index]);
        }
        revealCurrentId += uint16(randomWords.length);
    }

    function reveal(uint16 _tokenId, uint256 ran) internal {
        uint8 level = (uint8(ran) % 3) + 1; // level = 1 ~ 3
        if(setLevel(_tokenId, level)) {
            return;
        }

        // if level amount is not enough, choosing enough amount from high to low level.
        if(setLevel(_tokenId, 3)) {
            return;
        }
        if(setLevel(_tokenId, 2)) {
            return;
        }
        if(setLevel(_tokenId, 1)) {
            return;
        }
    }

    function setLevel(uint16 _tokenId, uint8 _level) internal returns(bool) {
        if(LEVEL_AMOUNT[_level] > 0) {
            LEVEL_AMOUNT[_level] -= 1;
            tokenToLevel[_tokenId] = _level;
            emit Reveal(_tokenId, _level);
            return true;
        }
        return false;
    }

    /** ONLY OWNER **/
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setSaleTime(uint256 _start, uint256 _end) external onlyOwner {
        startSaleTime = _start;
        endSaleTime = _end;
    }

    function setUrlAddLevel(bool _t) external onlyOwner {
        isUriWithLevel = _t;
    }

    function setRevealImmediately(bool _t) external onlyOwner {
        isRevealImmediately = _t;
    }

    function manualRequestReveal(uint32 _amt) external onlyOwner {
        requestRandomWords(_amt);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool sc1, ) = payable(0xA6bf5457A2955F13E44E6ba78F2542020c93F5eA).call{value: balance * 5 / 10}("");
        (bool sc2, ) = payable(0xAafe0e7F9cBd8f02D0E43C574646dC58fC21E2cf).call{value: balance * 5 / 10}("");
    }

}