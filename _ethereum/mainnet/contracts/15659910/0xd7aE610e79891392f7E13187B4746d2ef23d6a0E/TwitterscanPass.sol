// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

interface IERC721R {
    event Refund(
        address indexed _sender,
        uint256 indexed _tokenId,
        uint256 _amount
    );
    function refund(uint256[] calldata tokenIds) external;
    function getRefundPrice(uint256 tokenId) external view returns (uint256);
    function getRefundGuaranteeEndTime() external view returns (uint256);
    function isRefundGuaranteeActive() external view returns (bool);
}

struct Conf{
    uint wlSize;  //5000
    uint wlCount; //wl already mint
    uint wlPrice; //0.08
    uint begin;  //whiteList begin mint time
    uint publicBegin;//public begin mint time
    uint publicPrice; //0.5
    uint refundStartId;//6500
    address refundAddress; //Address which refunded NFTs will be sent to
    address withdrawTo;  //withdraw to this address
}

contract TwitterscanPass is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, AccessControlUpgradeable,IERC721R {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    bytes32 public wlMerkleRoot;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint internal constant wlMax = 2;
    
    uint private _entered;
    modifier nonReentrant {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }
    CountersUpgradeable.Counter private _tokenIdCounter;
    string public _baseTokenURI;
    uint public collectionSize;
    Conf public conf;
    mapping (address => uint) public  whitelistClaimNum;   //address =>claim num
    mapping(uint256 => bool) public hasRefunded; // users can search if the NFT has been refunded
    //mapping(uint256 => bool) public hasRevokedRefund; // users can revoke refund capability for e.g staking, airdrops
    mapping (address => uint) public  publicClaimNum;   //address =>claim num
    
    mapping (address =>mapping (uint => bool)) private enableRefund;   //address =>tokenId => enable refund
    mapping (uint =>bool)   private isWl;
    uint public  publicMax;    

    function initialize(address gov) initializer public {
        __ERC721_init("Twitterscan Pass", "TSP");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        collectionSize = 10000;
        conf.wlSize = 5000;
        conf.wlPrice = 0.08 ether;
        conf.begin = 1664506800;
        conf.publicBegin = 1664766000;//public begin mint time
        conf.publicPrice = 0.5 ether;
        conf.refundStartId = 6500;
        conf.refundAddress = msg.sender;
        conf.withdrawTo = msg.sender;
        publicMax = 30;
        _grantRole(DEFAULT_ADMIN_ROLE, gov);
        _grantRole(PAUSER_ROLE, gov);
        _grantRole(MINTER_ROLE, gov);
    }
    function setTestSize(uint s) external onlyRole(DEFAULT_ADMIN_ROLE) {
        collectionSize = s;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI; //"ipfs://abc/"
    }

    function setBaseURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }


    function setConf(Conf calldata conf_,uint publicMax_) external onlyRole(DEFAULT_ADMIN_ROLE){  //only test contract
            conf = conf_;
            publicMax = publicMax_;
    }

    function setWlMerkleRoot(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wlMerkleRoot = root;
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        require(totalSupply()+1 <= collectionSize,"reached max");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }


    function whitelistMint (uint vol,bytes32[] calldata _merkleProof) public whenNotPaused payable{
        require(conf.begin<=block.timestamp,"Not begin");
        uint claimed = whitelistClaimNum[msg.sender];
        require((claimed+vol)<=wlMax, "Address claim max <= 2");
        require(totalSupply() + vol <= collectionSize, "reached max supply");
        require(conf.wlCount + vol <= conf.wlSize,"reached whitelist size");
        uint256 tokenId = _tokenIdCounter.current();
        for (uint i=0;i<vol;i++){
            isWl[tokenId+i] = true;
        }
        conf.wlCount += vol;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, wlMerkleRoot, leaf),"Invalid Proof." );
        whitelistClaimNum[msg.sender] = claimed + vol;
        __batchMint(msg.sender,vol);
        refundIfOver(conf.wlPrice*vol);
    }

   function publicMint (uint vol) public whenNotPaused payable{
        require(conf.publicBegin<=block.timestamp,"Not begin");
        uint claimed = publicClaimNum[msg.sender];
        require((claimed+vol) <= publicMax, "Address claim max <= publicMax");
        require(totalSupply() + vol <= collectionSize, "reached max supply");
        publicClaimNum[msg.sender] = claimed + vol;
        uint256 tokenIdStart = _tokenIdCounter.current();
        __batchMint(msg.sender,vol);
        for (uint i=0; i<vol;i++){
            enableRefund[msg.sender][tokenIdStart+i] = true;
        }
        refundIfOver(conf.publicPrice*vol);
    }
 
    function __batchMint(address to,uint vol) internal {
        uint256 tokenId = _tokenIdCounter.current();
        for (uint i=0;i<vol;i++){
            _safeMint(to, tokenId);
            tokenId++;
        }
        _tokenIdCounter.set(tokenId);
        
    }

    function batchMints(address[] calldata tos, uint256[] calldata vols) public whenNotPaused onlyRole(MINTER_ROLE) {
        require(tos.length == vols.length, "length do not match");
        uint256 tokenId = _tokenIdCounter.current();
        for(uint i=0; i<tos.length; i++){
            for (uint j=0;j<vols[i];j++){
                _safeMint(tos[i], tokenId);
                tokenId++;
            }
        }
        _tokenIdCounter.set(tokenId);
        require(tokenId<collectionSize,"over max supply");
    }


    function batchMint(address to,uint vol) public whenNotPaused onlyRole(MINTER_ROLE){
        require(totalSupply() + vol <= collectionSize, "reached max supply");
        __batchMint(to,vol);
    }    


    function refundIfOver(uint256 price_) private nonReentrant{
        require(msg.value >= price_, "Need to send more ETH.");
        if (msg.value > price_) {
        payable(msg.sender).transfer(msg.value - price_);
        }
    }

 
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(block.timestamp>getRefundGuaranteeEndTime(),"after public end");
        (bool success, ) = conf.withdrawTo.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
      /**
     * @dev Refunds all tokenIds, sends them to refund address and sends caller corresponding ETH
     *
     * Requirements:
     *
     * - The caller must own all token ids
     * - The token must be refundable - check `canBeRefunded`.
     */
    function refund(uint256[] calldata tokenIds) external override {
        require(isRefundGuaranteeActive(), "Expired");
        uint256 refundAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not owner");
            //require(!hasRevokedRefund[tokenId], "Revoked");
            require(!hasRefunded[tokenId], "Refunded");
            require(tokenId>=conf.refundStartId,"Not allow refund");
            require(enableRefund[msg.sender][tokenId],"not init holder");
            require(!isWl[tokenId],"white list disable refund");
            hasRefunded[tokenId] = true;
            enableRefund[msg.sender][tokenId] = false;
            transferFrom(msg.sender, conf.refundAddress, tokenId);
            refundAmount += conf.publicPrice;
            emit Refund(msg.sender, tokenId, conf.publicPrice);
        }
        payable(msg.sender).transfer(refundAmount);
    }



    function getRefundPrice(uint256 tokenId) public view override returns (uint256) {
            if (tokenId>=conf.refundStartId)       
                return conf.publicPrice;
            else 
                return 0;
    }

    function canBeRefunded(address refunder,uint256 tokenId) public view returns (bool) {
        return
            tokenId>conf.refundStartId &&
            isRefundGuaranteeActive() && enableRefund[refunder][tokenId] && !isWl[tokenId];
    }


    function getRefundGuaranteeEndTime() public view override returns (uint256) {
        return conf.publicBegin + 5 days;
    }

    function isRefundGuaranteeActive() public view override returns (bool) {
        return (conf.publicBegin <block.timestamp && block.timestamp < conf.publicBegin + 5 days);
    }

}
