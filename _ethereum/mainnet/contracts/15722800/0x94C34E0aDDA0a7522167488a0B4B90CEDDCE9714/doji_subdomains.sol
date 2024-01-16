// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SignatureChecker.sol";
import "./ENS.sol";
import "./Base64.sol";
import "./Strings.sol";

/// @custom:security-contact k@quantum.tech
/// @custom:security-contact y@quantum.tech
contract ZingotSubdomainRegistrar is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    event NameRegistered( uint256 indexed id, address indexed owner, uint256 expires );
    event TokenPayment( address indexed buyer, uint256 indexed serial, uint256 indexed tokenId, string name, string domain );

    using Strings for uint256;
    // A map of expiry times
    mapping(uint256 => TokenData) public ensToTokenData;
    mapping(uint256 => uint256) public expiries;
    struct TokenData { uint256 created; uint256 expiration; uint256 registration; uint256 labelSize; string label; string domain; }

    string public imageURL;

    // The ENS registry
    ENS public ens;

    // The namehash of the TLD this registrar owns (eg, .eth)
    struct DomainData { bool enable; string name; address resolver; }
    mapping(bytes32 => DomainData) public baseNodes;
    address public signer;
    uint256 _totalSupply;
    address public admin;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Zingot Subdomain Registrar", "zID");
        __Ownable_init();
        __UUPSUpgradeable_init();
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        signer = 0xa7e1AC56E96aAcc633d8356491B6F9AA652c129e;
        admin = 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8;
        //resolver = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
        imageURL = "https://zcm.s3.amazonaws.com/subdomains/images/";
        transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *        is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    modifier live(bytes32 baseNode) {
        require(ens.owner(baseNode) == address(this));
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *            when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override(ERC721Upgradeable) returns (address) {
        require(expiries[tokenId] > block.timestamp);
        return super.ownerOf(tokenId);
    }

    function _getMessageHash(address to, string memory label, bytes32 baseNode, address _contract, uint256 serial, uint256 timestamp) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _getMessage(to, label, baseNode, _contract, serial, timestamp)
                )
            );
    }

    function _getMessage(address to, string memory label, bytes32 baseNode, address _contract, uint256 serial, uint256 timestamp) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, label, baseNode, _contract, serial, timestamp));
    }

    function recover(address to, string memory label, bytes32 baseNode, uint256 serial, uint256 timestamp, bytes memory signature ) public view returns (bool) {
        bytes32 hash = _getMessageHash(to, label, baseNode, address(this), serial, timestamp);
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }
    
    function computeNamehash(string memory name) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256( abi.encodePacked(namehash, keccak256(bytes('eth'))) );
        namehash = keccak256( abi.encodePacked(namehash, keccak256(bytes(name))) );
    }

    function computeENSIdfromString(string memory subdomain, string memory domain) public pure returns (uint256 ensID) {
        bytes32 baseNode = computeNamehash(domain);
        ensID = uint256(keccak256(abi.encodePacked(baseNode, keccak256(bytes(subdomain)))));
    }

    function computeENSIdfromHash(string memory subdomain, bytes32 baseNode) public pure returns (uint256 ensID) {
        ensID = uint256(keccak256(abi.encodePacked(baseNode, keccak256(bytes(subdomain)))));
    }

    function reclaimDomain(string memory name) external onlyAdmin {
        bytes32 nodehash = computeNamehash(name);
        require(ens.owner(nodehash) == address(this));
        ens.setOwner(nodehash, msg.sender);
        if ( baseNodes[nodehash].enable ) {
            baseNodes[nodehash].enable = false;
        }
    }

    function enableDomainWithResolver(string memory name, address _resolver) external onlyAdmin {
        bytes32 nodehash = computeNamehash(name);
        require(ens.owner(nodehash) == address(this));
        require(_resolver != 0x0000000000000000000000000000000000000000);

        ens.setResolver(nodehash, _resolver);
        baseNodes[nodehash].enable = true;
        baseNodes[nodehash].name = name;
        baseNodes[nodehash].resolver = _resolver;        
    }

    function enableDomain(string memory name) external onlyAdmin {
        bytes32 nodehash = computeNamehash(name);
        require(ens.owner(nodehash) == address(this));
        address _resolver = ens.resolver(nodehash);
        require(_resolver != 0x0000000000000000000000000000000000000000);

        ens.setResolver(nodehash, _resolver);
        baseNodes[nodehash].enable = true;
        baseNodes[nodehash].name = name;
        baseNodes[nodehash].resolver = _resolver;        
    }

    function disableDomain(string memory    name) external onlyAdmin {
        bytes32 nodehash = computeNamehash(name);        
        baseNodes[nodehash].enable = false;
    }

    function setSigner(address _signer) external onlyAdmin {
        signer = _signer;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }
    
    function setImageURL(string memory _url) external onlyAdmin {
        imageURL = _url;
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(bytes32[] memory _baseNodes, address _resolver) external onlyAdmin {
        for (uint i = 0; i < _baseNodes.length; i++) {
            ens.setResolver(_baseNodes[i], _resolver);
            baseNodes[_baseNodes[i]].resolver = _resolver;
        }
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view returns (uint256) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] < block.timestamp;
    }

    function register(address owner, bytes memory data) external {
        (string memory label, bytes32 baseNode, uint256 serial, uint256 timestamp, bytes memory signature) = abi.decode(
            data,
            (string, bytes32, uint256, uint256, bytes)
        );

        require(baseNodes[baseNode].enable, "Invalid domain");
        require(recover(msg.sender, label, baseNode, serial, timestamp, signature), "wrong signature");
        require(timestamp >= block.timestamp, "Signature expired");
        bytes32 labelhash = keccak256(bytes(label));
        uint256 ensID = computeENSIdfromHash(label, baseNode);
        ensToTokenData[ensID].created = block.timestamp;
        ensToTokenData[ensID].labelSize = bytes(label).length;
        ensToTokenData[ensID].label = label;
        ensToTokenData[ensID].domain = baseNodes[baseNode].name;
        _register(ensID, labelhash, baseNode, owner, true);
        _totalSupply++;

        emit TokenPayment(msg.sender, serial, ensID, label, baseNodes[baseNode].name);
    }

    function _register( uint256 id, bytes32 labelhash, bytes32 baseNode, address owner, bool updateRegistry ) internal live(baseNode) {
        require(available(id));

        expiries[id] = block.timestamp + type(uint64).max;
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if (updateRegistry) {
            ens.setSubnodeRecord(
                baseNode,
                labelhash,
                owner,
                baseNodes[baseNode].resolver,
                type(uint64).max
            );
        }

        emit NameRegistered(id, owner, block.timestamp + type(uint64).max);
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(bytes32 baseNode, uint256 id, address owner) external live(baseNode) {
        require(_isApprovedOrOwner(msg.sender, id));
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 ensID) public view override returns (string memory) {
        require(_exists(ensID), "ERC721: token doesn't exist");

        string memory tokenName = string(abi.encodePacked(_upperString(ensToTokenData[ensID].label),'.',_upperString(ensToTokenData[ensID].domain),'.ETH'));
        string memory tokenDescription = string(abi.encodePacked(tokenName,' a Zingot ID and fully functional ENS Subdomain. Get yours at https://dojicrew.com/ids'));
        string memory tokenImage = string(abi.encodePacked(imageURL,ensID.toString(),'.png'));
        string memory tokenAttributes = string(abi.encodePacked('[',
                '{"display_type":"date","trait_type": "Created Date","value":"',ensToTokenData[ensID].created.toString(),'"}',
                ',{"display_type":"number","trait_type": "Length","value":"',ensToTokenData[ensID].labelSize.toString(),'"}',
                ',{"trait_type": "Domain","value":"', _upperString(ensToTokenData[ensID].domain),'.ETH"}',
                ']'));
        
        string memory json = Base64.encode(
            abi.encodePacked(
                '{',
                '"description":"', tokenDescription,'",',
                '"external_url":"https://dojicrew.com/",',
                '"name":"',tokenName,'","image":"',tokenImage,'",', 
                '"attributes":',tokenAttributes,
                '}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    // Upper string function from willitscale/solidity-util
    function _upperBytes(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }
        return _b1;
    }
        
    // Upper string function from willitscale/solidity-util
    function _upperString(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upperBytes(_baseBytes[i]);
        }
        return string(_base);
    }
}
