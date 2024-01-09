// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// import "./console.sol";

contract Lazy is  ERC721URIStorage, EIP712 , AccessControl, Ownable, ERC721Enumerable, ReentrancyGuard {

    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public initialPrice = 0.30 ether;

    uint public shareOfSale1 = 8300;
    uint public shareOfSale2 = 1500;
    uint public shareOfSale3 = 200;

    uint public shareOfWhitelist1 = 5800;
    uint public shareOfWhitelist2 = 4000;
    uint public shareOfWhitelist3 = 200;

    // the address all signatures need to verify against
    mapping(address => bool) public whiteLists;

    // Wallet 1(83% or 58%)
    address public owner1 = 0x5db8Bb85D6065f95350d8AE3934D72Ad0aB3Ae7E;
    // Wallet 2(40% or 15%)
    address public owner2 = 0x04d59D5699E1B28161eA972fFD81a6705bFEB8A3;
    // Wallet 3 (2%):
    address public owner3 = 0xf08e0469565d481d4193de46D5f98b7c6463FC3d;    

    receive() external payable {
        // Do not send ether directly
        revert();
    }

    constructor() 
        ERC721("Exposed Walls Banksy", "EWB") 
        EIP712("Exposed Walls Banksy", "1") {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintToken(uint256 amount, string[] calldata message, bytes[] calldata sign) external payable nonReentrant callerIsUser {
        require(message.length == amount, "Invalid number of messages");
        require(msg.value == initialPrice * amount, "not enough money");
        require(totalSupply() + amount <= 10000, "over the 10000");
        for (uint256 index = 0; index < amount; index++) {
            address signer = verify(message[index], sign[index]);
            require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, message[index]);
        }

        uint shareamount1;
        uint shareamount2;
        uint shareamount3;

        if (whiteLists[msg.sender]) {
            shareamount1 = shareOfWhitelist1;
            shareamount2 = shareOfWhitelist2;
            shareamount3 = shareOfWhitelist3;            
        }else{
            shareamount1 = shareOfSale1;
            shareamount2 = shareOfSale2;
            shareamount3 = shareOfSale3;   
        }
        (bool sent, ) = payable(owner1).call{value: (msg.value * shareamount1/ 10000)}("");
        require(sent, "Failed to send Ether");
        (sent, ) = payable(owner2).call{value: (msg.value * shareamount2/ 10000)}("");
        require(sent, "Failed to send Ether");
        (sent, ) = payable(owner3).call{value: (msg.value * shareamount3/ 10000)}("");
    }

    function addWhitelistuser(address user) external onlyOwner{
        whiteLists[user] = true;
    }

    function addBulkWhitelistUser(address[] memory users) external onlyOwner{
        for(uint i = 0; i< users.length; i++){
            whiteLists[users[i]] = true;
        }
    }

    function removeWhitelistuser(address user) external onlyOwner{
        whiteLists[user] = false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721, ERC721Enumerable) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function verify(string calldata message, bytes calldata sign) public pure returns (address) {
        bytes32 b = keccak256(abi.encodePacked(message));
        return b.toEthSignedMessageHash().recover(sign);
    }

    function _burn(uint256 tokenId) internal virtual override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}