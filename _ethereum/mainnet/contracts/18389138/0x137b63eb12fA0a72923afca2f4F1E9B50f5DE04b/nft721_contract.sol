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
import "./IERC5192.sol";

//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

//SBT interface
interface iSbtCollection {
    function externalMint(address _address , uint256 _amount ) external payable;
    function balanceOf(address _owner) external view returns (uint);
}


contract NFTContract721 is ERC2981 ,Ownable, ERC721RestrictApprove ,AccessControl,ReentrancyGuard , IERC4906 , IERC5192 {
    using Strings for uint256;

    constructor(
    ) ERC721Psi("Cool Girl NFT", "CG") {
        
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE       , msg.sender);
        grantRole(AIRDROP_ROLE      , msg.sender);
        grantRole(ADMIN             , msg.sender);
        grantRole(LOCKER_ROLE       , msg.sender);

        grantRole(MINTER_ROLE       , 0xFfe3F496288E299f14D8493d996e0fd2A872F59D);
        grantRole(LOCKER_ROLE       , 0xFfe3F496288E299f14D8493d996e0fd2A872F59D);


        setBaseURI("https://cool-connect.nftstorage.jp/coolgirl/metadata/");
        setBaseURILocked("https://cool-connect.nftstorage.jp/coolgirl/metadata-locked/");

        //CAL initialization
        setCALLevel(1);

        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);//Ethereum mainnet proxy
        //_setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy

        _addLocalContractAllowList(0x1E0049783F008A0085193E00003D00cd54003c71);//OpenSea
        _addLocalContractAllowList(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be);//Rarible

        //initial mint
        //_safeMint(msg.sender, 5);        

        //Royalty
        setDefaultRoyalty( 0xFfe3F496288E299f14D8493d996e0fd2A872F59D , 1000);
        setWithdrawAddress(0xFfe3F496288E299f14D8493d996e0fd2A872F59D);

    }

    //
    //withdraw section
    //

    address public withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

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
    uint256 public cost = 1000000000000000;
    uint256 public maxSupply = 5000 -1;
    uint256 public maxMintAmountPerTransaction = 200;
    uint256 public publicSaleMaxMintAmountPerAddress = 50;
    bool public paused = true;

    bool public onlyAllowlisted = true;
    bool public mintCount = true;
    bool public burnAndMintMode = false;

    //0 : Merkle Tree
    //1 : Mapping
    uint256 public allowlistType = 0;
    bytes32 public merkleRoot;
    uint256 public saleId = 0;
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;
    mapping(uint256 => mapping(address => uint256)) public allowlistUserAmount;

    bool public mintWithSBT = false;
    iSbtCollection public sbtCollection;


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
 
    //mint with merkle tree
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof , uint256 _burnId ) public payable callerIsUser{
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
                require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not allowlisted");
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

        if(burnAndMintMode == true ){
            require(_mintAmount == 1, "The number of mints is over.");
            require(msg.sender == ownerOf(_burnId) , "Owner is different");
            _burn(_burnId);
        }

        if( mintWithSBT == true ){
            if( sbtCollection.balanceOf(msg.sender) == 0 ){
                sbtCollection.externalMint(msg.sender,1);
            }
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

    function setMintWithSBT(bool _mintWithSBT) public onlyRole(ADMIN) {
        mintWithSBT = _mintWithSBT;
    }

    function setSbtCollection(address _address) public onlyRole(ADMIN) {
        sbtCollection = iSbtCollection(_address);
    }

    function setBurnAndMintMode(bool _burnAndMintMode) public onlyRole(ADMIN) {
        burnAndMintMode = _burnAndMintMode;
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

    string public baseURI;
    string public baseURILocked;
    string public baseExtension = ".json";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    function _baseURILocked() internal view returns (string memory) {
        return baseURILocked;        
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(ADMIN) {
        baseURI = _newBaseURI;
    }

    function setBaseURILocked(string memory _newBaseURI) public onlyRole(ADMIN) {
        baseURILocked = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyRole(ADMIN) {
        baseExtension = _newBaseExtension;
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(tokenId);
        }

        if( locked(tokenId) == true ){
            return string(abi.encodePacked(_baseURILocked(), tokenId.toString(), baseExtension));            
        }else{
            return string(abi.encodePacked(ERC721Psi.tokenURI(tokenId), baseExtension));
        }

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

    function externalBurn(uint256[] memory _burnTokenIds) external nonReentrant{
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(tx.origin == ownerOf(tokenId) , "Owner is different");
            _burn(tokenId);
        }        
    }




    //
    //sbt
    //

    bool public isSBT = false;

    function setIsSBT(bool _state) public onlyRole(ADMIN) {
        isSBT = _state;
    }



    //
    // Lock section
    //

    mapping(uint256 => bool ) public userLockStatus;  // false:unlock , true:lock
    mapping(uint256 => bool ) public adminLockStatus; // false:unlock , true:lock
    uint256 public userLockedAmount = 0;
    uint256 public adminLockedAmount = 0;
    bytes32 public constant LOCKER_ROLE  = keccak256("LOCKER_ROLE");

    function locked(uint256 tokenId) override public view returns (bool){
        return userLockStatus[tokenId] || adminLockStatus[tokenId];
    }

    function getUserLockStatus(uint256 tokenId) public view returns (bool) {
        return userLockStatus[tokenId];
    }

    function getAdminLockStatus(uint256 tokenId) public view returns (bool) {
        return adminLockStatus[tokenId];
    }

    function resetAdminLockedAmount(uint256 _adminLockedAmount) public onlyRole(LOCKER_ROLE) {
        adminLockedAmount = _adminLockedAmount;
    }
    function resetUserLockedAmount(uint256 _userLockedAmount) public onlyRole(LOCKER_ROLE) {
        userLockedAmount = _userLockedAmount;
    }

    function userLock(uint256[] memory _tokenIds ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(msg.sender == ownerOf(_tokenIds[i]) || hasRole(LOCKER_ROLE, msg.sender) , "Owner is different");
            if( getUserLockStatus(_tokenIds[i] ) == false ){
                userLockedAmount += 1;
                emit Locked( _tokenIds[i] );
                emit MetadataUpdate( _tokenIds[i] );
            } 
            userLockStatus[ _tokenIds[i] ] = true;
        }
    }

    function userUnLock(uint256[] memory _tokenIds ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(msg.sender == ownerOf(_tokenIds[i]) || hasRole(LOCKER_ROLE, msg.sender) , "Owner is different");
            if( getUserLockStatus(_tokenIds[i] ) == true ){
                userLockedAmount -= 1;
                emit Unlocked( _tokenIds[i] );                
                emit MetadataUpdate( _tokenIds[i] );
            } 
            userLockStatus[ _tokenIds[i] ] = false;
        }
    }


    function adminLock(uint256[] memory _tokenIds ) public onlyRole(LOCKER_ROLE){
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if( getAdminLockStatus( _tokenIds[i] ) == false ){
                adminLockedAmount += 1;
            } 
            adminLockStatus[ _tokenIds[i] ] = true;
        }
    }

    function adminUnLock(uint256[] memory _tokenIds ) public onlyRole(LOCKER_ROLE){
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if( getAdminLockStatus( _tokenIds[i] ) == true ){
                adminLockedAmount -= 1;
            } 
            adminLockStatus[ _tokenIds[i] ] = false;
        }
    }

    function tokensOfUserLocked() external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = userLockedAmount;
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                if (getUserLockStatus(i)) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;   
        }
    }

    function tokensOfAdminLocked() external view virtual returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = adminLockedAmount;
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                if (getAdminLockStatus(i)) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;   
        }
    }



    //override


    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( 
            (isSBT == false && locked(startTokenId) == false)  ||
            from == address(0) || 
            to == address(0)|| 
            to == address(0x000000000000000000000000000000000000dEaD),
            "transfer is prohibited"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require( 
            isSBT == false || 
            approved == false , 
            "setApprovalForAll is prohibited"
            );
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override {
        require( 
            (isSBT == false && locked(tokenId) == false) , 
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
            interfaceId == bytes4(0x49064906) || //ERC4906
            interfaceId == type(IERC5192).interfaceId ;
    }

    

}