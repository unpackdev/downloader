//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ENS.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BoredApezMapper is Ownable {

    using Strings for uint256;

    ENS private ens;
    bytes32 public domainHash;
    string constant public DOMAIN_LABEL = "boredapez";
    IERC721 constant public BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

    mapping(bytes32 => mapping(string => string)) public texts;
    mapping(bytes32 => uint256) public hashToIdMap;
    mapping(uint256 => bytes32) public tokenHashmap;
    mapping(bytes32 => string) public hashToDomainMap;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event RegisterSubdomain(address indexed registrar, uint256 indexed token_id, string indexed label);

    constructor() {
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        domainHash = getDomainHash();
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x3b3b57de //addr
        || interfaceID == 0x59d1d43c //text
        || interfaceID == 0x691f3431 //name
        || interfaceID == 0x01ffc9a7; //supportsInterface << [inception]
    }

    function text(bytes32 node, string calldata key) external view returns (string memory) {
        uint256 token_id = hashToIdMap[node];
        require(token_id > 0 && tokenHashmap[token_id] != 0x0, "Invalid address");

        if(keccak256(abi.encodePacked(key)) == keccak256("avatar")) {
            return string(abi.encodePacked("eip155:1/erc721:", addressToString(address(BAYC)), "/", token_id.toString()));
        }
        else{
            return texts[node][key];
        }
    }

    function addr(bytes32 nodeID) public view returns (address) {
        uint256 token_id = hashToIdMap[nodeID];
        require(token_id > 0 && tokenHashmap[token_id] != 0x0, "Invalid address");
        return BAYC.ownerOf(token_id);
    }  

    function name(bytes32 node) view public returns (string memory) {
        return (hashToIdMap[node] == 0) 
        ? "" 
        : string(abi.encodePacked(hashToDomainMap[node], ".", DOMAIN_LABEL, ".eth"));
    }

    function domainMap(string calldata label) public view returns(bytes32) {
        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));
        return hashToIdMap[big_hash] > 0 ? big_hash : bytes32(0x0);
    }

   function getTokenDomain(uint256 token_id) private view returns(string memory uri) {
        require(tokenHashmap[token_id] != 0x0, "Token does not have an ENS register");
        uri = string(abi.encodePacked(hashToDomainMap[tokenHashmap[token_id]] ,"." ,DOMAIN_LABEL, ".eth"));
        return uri;
    }

    function getTokensDomains(uint256[] memory token_ids) public view returns(string[] memory) {
        string[] memory uris = new string[](token_ids.length);

        for(uint256 i; i < token_ids.length; i++) {
           uris[i] = getTokenDomain(token_ids[i]);
        }

        return uris;
    }

    function addressToString(address _addr) private pure returns(string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(51);

        str[0] = "0";
        str[1] = "x";

        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }

        return string(str);
    }

    function getDomainHash() private pure returns (bytes32 namehash) {
        namehash = 0x0;
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(DOMAIN_LABEL))));
    }
    
    function setDomain(string calldata label, uint256 token_id) public isAuthorized(token_id) {     
        require(tokenHashmap[token_id] == 0x0, "Token has already been set");
        require(keccak256(bytes(label)) == keccak256(bytes(Strings.toString(token_id))), "Label must equal tokenID");

        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

        require(!ens.recordExists(big_hash) || msg.sender == owner(), "sub-domain already exists");
        
        ens.setSubnodeRecord(domainHash, encoded_label, owner(), address(this), 0);

        hashToIdMap[big_hash] = token_id;        
        tokenHashmap[token_id] = big_hash;
        hashToDomainMap[big_hash] = label;

        emit RegisterSubdomain(BAYC.ownerOf(token_id), token_id, label);     
    }

    function setText(bytes32 node, string calldata key, string calldata value) external isAuthorized(hashToIdMap[node]) {
        uint256 token_id = hashToIdMap[node];
        require(token_id > 0 && tokenHashmap[token_id] != 0x0, "Invalid address");
        require(keccak256(abi.encodePacked(key)) != keccak256("avatar"), "cannot set avatar");

        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    function resetDomainForToken(uint256 token_id) public isAuthorized(token_id) {
        bytes32 domain = tokenHashmap[token_id];
        require(ens.recordExists(domain), "Sub-domain does not exist");
        
        hashToDomainMap[domain] = "";      
        hashToIdMap[domain] = 0;
        tokenHashmap[token_id] = 0x0;
    }

    function setEnsAddress(address addr) public onlyOwner {
        ens = ENS(addr);
    }

    function renounceOwnership() public override onlyOwner {
        require(false, "Sorry - you cannot renounce ownership.");
        super.renounceOwnership();
    }

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

    modifier isAuthorized(uint256 tokenId) {
        require(owner() == msg.sender || BAYC.ownerOf(tokenId) == msg.sender, "Not authorized");
        _;
    }
}