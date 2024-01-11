// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721AQueryable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/// @title The ERC721 Contract for Niky Botz Picture Day
contract NikyBotzPictureDay is ERC721AQueryable, AccessControl, Ownable {

    uint256 private _price = 0.055 ether;

    uint256 private _reserveMintCount;

    bytes32 public whitelistRoot = "";

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    bytes32 public constant SYSADMIN_ROLE = keccak256("SYSADMIN_ROLE");

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string public provenanceHash = "";

    string private _customBaseURI = "";

    // Must be true for any minting to possibly occur
    bool private _allMintOn = false;

    // Must be true and allMintOn must be true to mint publicly
    bool private _publicMintOn = false;

    // Must be true and allMintOn must be true to mint from whitelist
    bool private _whitelistMintOn = false;

    bool private _provenanceHashSet = false;


    mapping(address => uint) private _hasMinted;

    event ProvenanceHashSet(string provHash);

    event WhitelistRootUpdated(bytes32 root);

    event AllMintOnStateFlipped(bool state);

    event PublicMintOnStateFlipped(bool state);

    event WhitelistMintOnStateFlipped(bool state);


    /**
    @notice Used for all 3 minting functions
    */
    modifier allMintOn() {
        require(_allMintOn, "All minting off");
        _;
    }

    /**
    @notice Used for 'mintSchoolBotz' function
    */
    modifier publicMintOn() {
        require(_publicMintOn, "Public minting off");
        _;
    }

    /**
    @notice Used for 'mintFromWhitelist' function
    */
    modifier whitelistMintOn() {
        require(_whitelistMintOn, "Whitelist minting off");
        _;
    }


    constructor(
        string memory name,
        string memory symbol,
        string memory customBaseURI,
        address multisig,
        address sysadmin
    ) ERC721A(name, symbol) {
        _customBaseURI = customBaseURI;

        _setupRole(OWNER_ROLE, multisig);

        _setupRole(SYSADMIN_ROLE, multisig);
        _setupRole(SYSADMIN_ROLE, sysadmin);

        _setupRole(MANAGER_ROLE, multisig);
        _setupRole(MANAGER_ROLE, sysadmin);

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(SYSADMIN_ROLE, SYSADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, SYSADMIN_ROLE);

        // We don't want the deployer to own the contract
        transferOwnership(multisig);
    }


    /**
    @notice This function can only be set once. This is to ensure metadata integrity before any sales begin
    @dev This will be a hash of the concatenation of all images/metadata hashed sequentially
    */
    function setProvenanceHash(string memory provHash)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(_provenanceHashSet == false, "Already set");
        provenanceHash = provHash;
        _provenanceHashSet = true;
        emit ProvenanceHashSet(provenanceHash);
    }

    /**
    @notice Sets the base URI for all tokens
    */
    function setBaseTokenURI(string memory newBaseURI)
        external
        onlyRole(MANAGER_ROLE)
    {
        _customBaseURI = newBaseURI;
    }

    /**
    @notice Sets the whitelist root
    @dev The _root should be the root (a keccack256 hash) of a merkle tree of all whitelist addresses
    */
    function setWhitelistRoot(bytes32 root) external onlyRole(MANAGER_ROLE) {
        whitelistRoot = root;
        emit WhitelistRootUpdated(whitelistRoot);
    }

    /**
    @notice Mints up to a max. of 100 tokens (by managers)
    */
    function mintReserveSchoolBotz(address mintToAddress, uint256 numTokens)
        external
        allMintOn
        onlyRole(MANAGER_ROLE)
    {
        require(numTokens + totalSupply() <= 5555, "Over token limit");
        require(numTokens + _reserveMintCount <= 100, "Over reserve limit");

        _reserveMintCount += numTokens;
        _safeMint(mintToAddress, numTokens);

    }

    /*
    @notice Mints up to 2 tokens if msg.sender is on whitelist
    @dev See https://github.com/miguelmota/merkletreejs-solidity for how to construct 'proof' on client side
    @param proof This should be a merkle proof that verifies msg.sender is a part of the merkle root (whitelist root)
    */
    function mintFromWhitelist(uint numTokens, bytes32[] calldata proof)
        external
        payable
        whitelistMintOn
        allMintOn
    {
        require(numTokens == 1 || numTokens == 2, "Invalid no. of tokens");
        require(numTokens + totalSupply() <= 5555, "Over token limit.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, getWhitelistRoot(), leaf) == true,
            "Invalid address"
        );
        require(
            _price * numTokens <= msg.value,
            "Invalid ether value sent."
        );
        require(
            _hasMinted[msg.sender] + numTokens <= 2,
            "Whitelist mint limit"
        );

        _safeMint(msg.sender, numTokens);

        _hasMinted[msg.sender] += numTokens;
    }

    /**
    @notice Mint any number of NFTs (within cap of 5555)
    */
    function mintSchoolBotz(uint numTokens)
        external
        payable
        publicMintOn
        allMintOn
    {
        require(numTokens > 0, "Invalid no. of tokens");
        require(numTokens + totalSupply() <= 5555, "Over token limit.");
        require(_price * numTokens <= msg.value, "Invalid msg.value");

        _safeMint(msg.sender, numTokens);

    }

    /**
    @notice Only owner can withdraw funds from contract
    */
    function withdrawFunds() public onlyRole(OWNER_ROLE) onlyOwner {
        address payable wallet = payable(owner());

        (bool sent, ) = wallet.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
    @notice Starting NFT tokenId
    */
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    } 


    /**
    @notice Return price of 1 NFT
    */
    function getPrice() public view returns (uint256) {
        return _price;
    }

    /**
    @return Number of mints from reserves
    */
    function getReserveMintCount() public view returns (uint) {
        return _reserveMintCount;
    }
    

    /**
    @return the whitelist root (merkle root)
    */
    function getWhitelistRoot() public view returns (bytes32) {
        return whitelistRoot;
    }

    /**
    @return the base URI for tokens
    */
    function baseTokenURI() public view returns (string memory) {
        return _customBaseURI;
    }

    /**
    @return the TokenURI given the tokenId
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    function setPrice(uint price) public onlyRole(MANAGER_ROLE) {
        _price = price;
    }

    /**
    @notice Flips the _allMintOn state
    */
    function flipAllMintState() public onlyRole(MANAGER_ROLE) {
        _allMintOn = !_allMintOn;
        emit AllMintOnStateFlipped(_allMintOn);
    }

    /**
    @notice Flips the _publicMintOn state
    */
    function flipPublicMintState() public onlyRole(MANAGER_ROLE) {
        _publicMintOn = !_publicMintOn;
        emit PublicMintOnStateFlipped(_publicMintOn);
    }

    /**
    @notice Flips the _whitelistMintOn state
    */
    function flipWhitelistMintState() public onlyRole(MANAGER_ROLE) {
        _whitelistMintOn = !_whitelistMintOn;
        emit WhitelistMintOnStateFlipped(_whitelistMintOn);
    }

    /**
    @return the 3 minting states
    */
    function getMintState()
        public
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return (_allMintOn, _publicMintOn, _whitelistMintOn);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
