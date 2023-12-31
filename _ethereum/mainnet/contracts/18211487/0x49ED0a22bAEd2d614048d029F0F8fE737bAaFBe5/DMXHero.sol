// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DMXHeroStaker.sol";
import "./DMXAllowlist.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

contract DMXHero is ERC721Upgradeable, OwnableUpgradeable , DefaultOperatorFiltererUpgradeable {
    using ECDSA for bytes32;
    address public staker;
    address public store;
    address public allowlist;
    uint32 public totalSupply;
    uint32 public customSupply;
    uint32 public genesisSupply;
    uint32 public commonSupply;
    
    //TODO: assure minting authority for potential future Minter contract
    string metadataUrl;
    mapping(address => uint256) public minting_nonces;
    event Mint(uint32 tokenId, address Recipient, uint NftType, uint StoreType);

    // OpenSea
    event Stake(uint256 indexed tokenId);
    event Unstake(uint256 indexed tokenId, uint256 stakedAtTimestamp, uint256 removedFromStakeAtTimestamp);
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function emitStaked(uint32 tokenId) public {
        require(msg.sender == staker);
        emit Stake(tokenId);
    }
    function emitUnstaked(uint32 tokenId) public {
        require(msg.sender == staker);
        emit Unstake(tokenId,0, block.timestamp); //opensea does not use these last two arguments, but they may be required for this event to be seen
    }

    function refreshAllMetadata() public onlyOwner {
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    function initialize()  public initializer  {
        __ERC721_init("DMX", "DMX");
        __Ownable_init();
        totalSupply = 0;
        customSupply = 0;
        genesisSupply = 0;
        commonSupply = 0;
    }

    function setStaker(address Staker) public onlyOwner {
        staker = Staker;
    }

    function setStore(address Store) public onlyOwner {
        store = Store;
    }

    function setAllowlist(address AllowlistContract) public onlyOwner {
        allowlist = AllowlistContract;
    }

    function mintGenesisNFT()
    public {
        DMXAllowlist allowlistContract = DMXAllowlist(address(allowlist));
        require(allowlistContract.mintPhase() == DMXAllowlist.MintPhase.PUBLIC);
        require(genesisSupply < 10000);
        uint32 nextID = _getNextGenesisID();
        genesisSupply++;
        totalSupply++;
        emit Mint(nextID, msg.sender, 1, 0);
        _safeMint(msg.sender, nextID);
    }

    function _completeGenesisMint() internal {
        uint32 nextID = _getNextGenesisID();
        genesisSupply++;
        totalSupply++;
        emit Mint(nextID, msg.sender, 1,0);
        _safeMint(msg.sender, nextID);
    }

    function mintAllowgroupNFT(bytes32[] calldata _merkleProof, string calldata GroupName)
    public {
        DMXAllowlist allowlistContract = DMXAllowlist(address(allowlist));
        allowlistContract.validateAndMintOnAllowgroup(msg.sender, _merkleProof, GroupName);
        _completeGenesisMint();
    }

    function mintInvitelistNFT(bytes32[] calldata _merkleProof, uint quantity)
    public {
        DMXAllowlist allowlistContract = DMXAllowlist(address(allowlist));
        allowlistContract.validateAndMintOnAllowlist(msg.sender, _merkleProof, DMXAllowlist.MintPhase.INVITATIONLIST);
        require(quantity <= allowlistContract.invitationlistMax());
        for(uint i = 0; i < quantity; i++)
            _completeGenesisMint();
    }

    function mintAllowlistNFT(bytes32[] calldata _merkleProof, uint quantity)
    public {
        DMXAllowlist allowlistContract = DMXAllowlist(address(allowlist));
        allowlistContract.validateAndMintOnAllowlist(msg.sender, _merkleProof, DMXAllowlist.MintPhase.ALLOWLIST);
        require(quantity <= allowlistContract.allowlistMax());
        for(uint i = 0; i < quantity; i++)
            _completeGenesisMint();
    }

    function mintCustomNFT(address Recipient, uint Id)
    onlyOwner
    public {
        uint32 nextID = _getNextCustomID();
        require(Id == nextID);
        customSupply++;
        totalSupply++;
        emit Mint(nextID, Recipient, 0, 0);
        _safeMint(Recipient, nextID);
    }
    function _completeCommonMint(address recipient, uint nft_type, uint store_type) 
    internal {
        uint32 nextID = _getNextCommonID();
        commonSupply++;
        totalSupply++;
        emit Mint(nextID, recipient, nft_type, store_type);
        _safeMint(recipient, nextID);
    }
    function mintCommonNFT(bytes32 eth_hash, bytes memory signature, uint256 nonce, address recipient)
    public { 
        require((eth_hash.toEthSignedMessageHash().recover(signature) == owner()));
        //to eth signed message hash adds a text string that is added to the hash by wallets before producing the signature.
        //'\x19Ethereum Signed Message:\n' wallets do this as a safety measure against code injection attacks
        require(eth_hash == keccak256(abi.encodePacked(nonce, recipient)), "incorrect hash");
        require(minting_nonces[recipient] + 1 == nonce, "incorrect nonce"); 
        //nonce has to be a uint256, bc that is the kind of int that is encoded by web3 sha3, which is how our webserver will hash
        minting_nonces[recipient]++;
        _completeCommonMint(recipient, 2, 0);
      
    }

    function mintStoreNFT(address recipient, uint hero_type, uint nft_count)
    public {
        require(msg.sender == store, "only the store can mint");
        
        for(uint i = 0; i < nft_count; i++) {
            _completeCommonMint(recipient,3,hero_type);
        }
    }

    function mintCompanyNFT(address recipient, uint nft_type, uint hero_type)
    public
    onlyOwner {
        _completeCommonMint(recipient,nft_type,hero_type);
    }

   
    function _getNextCustomID()
    internal view returns(uint32 id)
    {
        uint32 nextId = customSupply + 1;
        return (nextId <= 1000) ? nextId : _getNextCommonID();
    }

    function _getNextGenesisID()
    internal view returns(uint32 id) 
    {
        uint32 nextId = 1000 + genesisSupply + 1;
        require(nextId <= 11000);
        return nextId;
    }

    function _getNextCommonID()
    internal view returns(uint32 id)
    {
        if(customSupply <= 1000)
            return commonSupply + 11000 + 1 ;
        else
            return 11000 + commonSupply + customSupply - 1000;
    }
    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public
        override
        onlyAllowedOperator(from) {
        
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataUrl;
    }

    function setMetadataURL(string memory url) public onlyOwner {
        metadataUrl = url;
    }
}