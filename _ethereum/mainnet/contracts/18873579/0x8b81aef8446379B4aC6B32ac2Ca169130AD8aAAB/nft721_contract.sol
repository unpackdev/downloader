// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Keisuke OHNO (kei31.eth)

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/


pragma solidity >=0.8.17;

import "./base64.sol";
import "./ERC721RestrictApprove.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./IERC4906.sol";

//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract NFTContract721 is ERC2981 ,Ownable, ERC721RestrictApprove ,AccessControl,ReentrancyGuard , IERC4906  {
    using Strings for uint256;

    constructor(
    ) ERC721Psi("Digital Castletown Project/Digital Jokers", "DCP") {
        
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE       , msg.sender);
        grantRole(AIRDROP_ROLE      , msg.sender);
        grantRole(ADMIN             , msg.sender);

        _setupRole(DEFAULT_ADMIN_ROLE, 0xF2514B3A47a8e7Cd4B5684d80D5C70fEF8d536A0);
        grantRole(ADMIN             , 0xF2514B3A47a8e7Cd4B5684d80D5C70fEF8d536A0);

        setBaseURI( 0 , "https://cnp.nftstorage.jp/digital-jokers/metadata_c/");
        setBaseURI( 1 , "https://cnp.nftstorage.jp/digital-jokers/metadata_b1/");
        setBaseURI( 2 , "https://cnp.nftstorage.jp/digital-jokers/metadata_b2/");
        setBaseURI( 3 , "https://cnp.nftstorage.jp/digital-jokers/metadata_a/");

        //CAL initialization
        setCALLevel(1);

        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);//Ethereum mainnet proxy
        //_setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy

        _addLocalContractAllowList(0x1E0049783F008A0085193E00003D00cd54003c71);//OpenSea
        _addLocalContractAllowList(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be);//Rarible

        //initial mint 
        _safeMint(0x3742FFF5D84AA72E4b1d700e87D22e43644F82C5, 94);
        _safeMint(0x409c46975e6c177f08CcE5a36Bab1C71A673130E, 1);
        _safeMint(msg.sender, 5);

        //Royalty
        setDefaultRoyalty(0x3742FFF5D84AA72E4b1d700e87D22e43644F82C5 , 1000);

        //SBT
        setIsSBT(true);

    }

    //
    //withdraw section
    //

    address public withdrawAddress = 0x3742FFF5D84AA72E4b1d700e87D22e43644F82C5;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //mint section
    //

    //https://eth-converter.com/
    uint256 public cost = 7000000000000000;
    uint256 public maxSupply = 5000 -1;
    uint256 public maxMintAmountPerTransaction = 10;
    uint256 public publicSaleMaxMintAmountPerAddress = 50;
    bool public paused = true;

    bool public onlyAllowlisted = true;
    bool public mintCount = true;

    //0 : Merkle Tree
    //1 : Mapping
    uint256 public allowlistType = 0;
    bytes32 public merkleRoot;
    uint256 public saleId = 0;
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;
    mapping(uint256 => mapping(address => uint256)) public allowlistUserAmount;


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
 
    //mint with merkle tree
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require( _nextTokenId() + _mintAmount -1 <= maxSupply , "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");

        uint256 maxMintAmountPerAddress;
        if(onlyAllowlisted == true) {
            if(allowlistType == 0){
                //Merkle tree
                bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
                require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf), "user is not allowlisted");
                maxMintAmountPerAddress = _maxMintAmount;
            }else if(allowlistType == 1){
                //Mapping
                require( allowlistUserAmount[saleId][msg.sender] != 0 , "user is not allowlisted");
                maxMintAmountPerAddress = allowlistUserAmount[saleId][msg.sender];
            }
        }else{
            maxMintAmountPerAddress = publicSaleMaxMintAmountPerAddress;
        }

        if(mintCount == true){
            require(_mintAmount <= maxMintAmountPerAddress - userMintedAmount[saleId][msg.sender] , "max NFT per address exceeded");
            userMintedAmount[saleId][msg.sender] += _mintAmount;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public {
        require(hasRole(AIRDROP_ROLE, msg.sender), "Caller is not a air dropper");
        require(_airdropAddresses.length == _UserMintAmount.length , "Array lengths are different");
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(0 < _mintAmount , "need to mint at least 1 NFT");
        require( _nextTokenId() + _mintAmount -1 <= maxSupply , "max NFT limit exceeded");        
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function currentTokenId() public view returns(uint256){
        return _nextTokenId() -1;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN) {
        merkleRoot = _merkleRoot;
    }

    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function setAllowListType(uint256 _type)public onlyRole(ADMIN){
        require( _type == 0 || _type == 1 , "Allow list type error");
        allowlistType = _type;
    }

    function setAllowlistMapping(uint256 _saleId , address[] memory addresses, uint256[] memory saleSupplies) public onlyRole(ADMIN) {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlistUserAmount[_saleId][addresses[i]] = saleSupplies[i];
        }
    }

    function getAllowlistUserAmount(address _address ) public view returns(uint256){
        return allowlistUserAmount[saleId][_address];
    }

    function getUserMintedAmountBySaleId(uint256 _saleId , address _address ) public view returns(uint256){
        return userMintedAmount[_saleId][_address];
    }

    function getUserMintedAmount(address _address ) public view returns(uint256){
        return userMintedAmount[saleId][_address];
    }

    function setSaleId(uint256 _saleId) public onlyRole(ADMIN) {
        saleId = _saleId;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(ADMIN) {
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyRole(ADMIN) {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyRole(ADMIN) {
        cost = _newCost;
    }

    function setOnlyAllowlisted(bool _state) public onlyRole(ADMIN) {
        onlyAllowlisted = _state;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyRole(ADMIN) {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }
  
    function setMintCount(bool _state) public onlyRole(ADMIN) {
        mintCount = _state;
    }
 


    //
    //URI section
    //


    //0 : FreeMint
    //1 : 寄付済み、　　未訪問
    //2 : 寄付してない、訪問済み
    //3 : 寄付済み、　　訪問済み
    mapping(uint256 => uint256) public stageByTokenId; //0 , 1 , 2 , 3
    mapping(uint256 => string) public baseURI;


    struct TokenInfo {
        uint256 tokenId;
        uint256 tokenStage;
    }    

    string public baseExtension = ".json";

    function setBaseURI(uint256 _stage , string memory _newBaseURI) public onlyRole(ADMIN) {
        baseURI[_stage] = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyRole(ADMIN) {
        baseExtension = _newBaseExtension;
    }

    function getStageByTokenId( uint256 _tokenId ) public view returns(uint256){
        return stageByTokenId[_tokenId];
    }

    function _setStageByTokenId(uint256 _tokenId , uint256 _stage ) internal {
        stageByTokenId[_tokenId] = _stage;
    }

    bytes32 public constant STAGECHANGER_ROLE  = keccak256("STAGECHANGER_ROLE");

    function setStageByTokenId(uint256 _tokenId , uint256 _stage ) public onlyRole(STAGECHANGER_ROLE) {
        _setStageByTokenId(_tokenId , _stage);
        emit MetadataUpdate( _tokenId );
    }

    function MetadataUpdateEvent(uint256 _tokenId ) public onlyRole(STAGECHANGER_ROLE) {
        emit MetadataUpdate( _tokenId);
    }
    
    function BatchMetadataUpdateEvent(uint256 _fromTokenId , uint256 _toTokenId ) public onlyRole(STAGECHANGER_ROLE) {
        emit BatchMetadataUpdate( _fromTokenId,  _toTokenId);
    }

    event Donated(uint256 tokenId, address user);

    function DonationEvent(uint256 _tokenId , address user) public onlyRole(STAGECHANGER_ROLE) {
        emit Donated( _tokenId,  user);
    }

    function DonationTokensEvent( uint256[] memory _tokenIds , address user) public onlyRole(STAGECHANGER_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            emit Donated( _tokenIds[i] ,  user);    
        }
    }



    function tokensOfOwnerByStage(address owner , uint256 stage) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsStageIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                if (_exists(i)) {
                    if (ownerOf(i) == owner) {
                        if( getStageByTokenId(i) == stage){
                            tokenIds[tokenIdsStageIdx++] = i;
                        }
                        tokenIdsIdx++;
                    }
                }
            }

            uint256[] memory tokenIdsReturn = new uint256[](tokenIdsStageIdx);
            for (uint256 i = 0; i < tokenIdsStageIdx; ++i) {
                tokenIdsReturn[i] = tokenIds[i];
            }

            return tokenIdsReturn;   
        }
    }


    //
    //interface metadata
    //

    iTokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    function setInterfaceOfTokenURI(address _address) public onlyRole(ADMIN) {
        interfaceOfTokenURI = iTokenURI(_address);
    }

    function setUseInterfaceMetadata(bool _useInterfaceMetadata) public onlyRole(ADMIN) {
        useInterfaceMetadata = _useInterfaceMetadata;
    }


    //
    //token URI
    //

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(_tokenId);
        }

        require(_exists(_tokenId), "ERC721Psi: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI[ stageByTokenId[_tokenId] ], _tokenId.toString() , baseExtension ));
    }


    //
    //burnin' section
    //

    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE  = keccak256("BURNER_ROLE");

    function externalMint(address _address , uint256 _amount ) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require( _nextTokenId() + _amount -1 <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }

    function externalMintWithStage(address _address , uint256 _amount , uint256 _stage) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        uint256 nextTokenId = _nextTokenId();
        require( nextTokenId + _amount -1 <= maxSupply , "max NFT limit exceeded");

        for( uint256 i = nextTokenId ; i < nextTokenId + _amount ; i++){
            _setStageByTokenId(i , _stage);
        }
        _safeMint( _address, _amount );
    }

    function externalBurn(uint256[] memory _burnTokenIds) external nonReentrant{
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(tx.origin == ownerOf(tokenId) , "Owner is different");
            _burn(tokenId);
        }        
    }





    //
    //sbt and opensea filter section
    //

    bool public isSBT = false;

    uint256 public sbtStartId = 99999;
    uint256 public sbtEndId = 99999;

    function setIsSBT(bool _state) public onlyRole(ADMIN) {
        isSBT = _state;
    }

    function setSBTId(uint256 _sbtStartId , uint256 _sbtEndId) public onlyRole(ADMIN) {
        sbtStartId = _sbtStartId;
        sbtEndId = _sbtEndId;
    }

    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( 
            ( isSBT == false && ( startTokenId < sbtStartId || sbtEndId < startTokenId) )  ||
            from == address(0) || 
            to == address(0)|| 
            to == address(0x000000000000000000000000000000000000dEaD),
            "transfer is prohibited"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require( (isSBT == false ) || approved == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override {
        require( 
            (isSBT == false ) , 
            "approve is prohibited"
        );
        super.approve(operator, tokenId);
    }


    //
    //ERC721PsiAddressData section
    //

    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }


    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address _owner) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(_owner != address(0), "ERC721Psi: balance query for the zero address");
        return uint256(_addressData[_owner].balance);   
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        require(quantity < 2 ** 64);
        uint64 _quantity = uint64(quantity);

        if(from != address(0)){
            _addressData[from].balance -= _quantity;
        } else {
            // Mint
            _addressData[to].numberMinted += _quantity;
        }

        if(to != address(0)){
            _addressData[to].balance += _quantity;
        } else {
            // Burn
            _addressData[from].numberBurned += _quantity;
        }
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }




    //
    //ERC721AntiScam section
    //

    bytes32 public constant ADMIN = keccak256("ADMIN");

    function setEnebleRestrict(bool _enableRestrict )public onlyRole(ADMIN){
        enableRestrict = _enableRestrict;
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDES ERC721RestrictApprove
    //////////////////////////////////////////////////////////////*/
    function addLocalContractAllowList(address transferer)
        external
        override
        onlyRole(ADMIN)
    {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        override
        onlyRole(ADMIN)
    {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        override
        view
        returns(address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCALLevel(uint256 level) public override onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setCAL(address calAddress) external override onlyRole(ADMIN) {
        _setCAL(calAddress);
    }


    //
    //setDefaultRoyalty
    //
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDES ERC721RestrictApprove
    //////////////////////////////////////////////////////////////*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981,ERC721RestrictApprove, AccessControl)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721RestrictApprove.supportsInterface(interfaceId) ||
            interfaceId == bytes4(0x49064906); //ERC4906
    }




}