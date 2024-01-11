// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract RugZuki is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public MAX_RUGZUKIS = 10000;
    uint256 public MAX_FREE_RUGZUKIS = 5000;
    uint256 public MAX_FREE_RUGZUKIS_PER_WALLET = 5;
    uint256 public MAX_RUGZUKIS_PER_WALLET = 20;
    uint256 public constant PRICE = 0.025 ether;

    string public tokenBaseURI;

    mapping(address => uint256) private addressFreeMintCount;
    mapping(address => uint256) private addressMintCount;

    Counters.Counter public tokenSupply;

    constructor() ERC721("RugZuki", "RugZuki") {}

    function setMaxMintLimit(uint256 _amount) public onlyOwner {
        MAX_RUGZUKIS_PER_WALLET = _amount;
    }

    function setTokenBaseURI(string memory _baseURI) external onlyOwner {
        tokenBaseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
    }


    // please do not freak out at the name - this is actuall just a withdrawl function
    function superRugzillaExpress() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function verifyOwnerSignature(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return hash.toEthSignedMessageHash().recover(signature) == owner();
    }

    function freeMint() external {
        require(
            tokenSupply.current().add(1) <= MAX_FREE_RUGZUKIS,
            "This purchase would exceed max supply of free rugzukis"
        );
        require(addressFreeMintCount[msg.sender] < MAX_FREE_RUGZUKIS_PER_WALLET, "Free limit reached");
        require(addressMintCount[msg.sender]+1 <= MAX_RUGZUKIS_PER_WALLET, "Limit reached");
        uint256 mintIndex = tokenSupply.current();
        
        addressMintCount[msg.sender] = addressMintCount[msg.sender]+1;
        addressFreeMintCount[msg.sender] = addressFreeMintCount[msg.sender]+1;
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
    }

    function publicMint(uint256 _quantity) external payable {
        _safeMintRugZukis(_quantity);
    }

    function _safeMintRugZukis(uint256 _quantity) internal {
        require(_quantity > 0, "minimum is 1");    
        require(
            tokenSupply.current().add(_quantity) <= MAX_RUGZUKIS,
            "This purchase would exceed max supply of rugzukis"
        );
        require(
            msg.value >= PRICE.mul(_quantity),
            "The ether value sent is not correct"
        );
        require(addressMintCount[msg.sender]+_quantity <= MAX_RUGZUKIS_PER_WALLET, "Limit reached");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 mintIndex = tokenSupply.current();

            if (mintIndex < MAX_RUGZUKIS) {
                addressMintCount[msg.sender] = addressMintCount[msg.sender]+1;
                tokenSupply.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}