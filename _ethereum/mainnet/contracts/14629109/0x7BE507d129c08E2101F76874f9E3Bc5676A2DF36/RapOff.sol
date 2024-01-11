// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract RapOffFridge is ERC721A, Ownable {
    using Strings for uint256;

    enum State { NOT_LIVE, ALLOW_LIST, LIVE }

    uint256 public constant RAP_OFF_MAX = 5000;
    uint256 public constant RAP_OFF_RESERVE_MAX = 150;
    uint256 public constant RAP_OFF_PRICE = 0.1 ether;
    
    State public state;
    bool public revealed;
    string public baseURI;
    string public provenance;

    uint256 private _reserveCounter;
    bytes32 private _merkleRoot;
 
    constructor() ERC721A("Rap Off", "RAP") {
        _safeMint(address(this), 1);
        _burn(0);
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof) external payable {
        require((state == State.LIVE || state == State.ALLOW_LIST), "RAP-OFF/NOT_LIVE");
        require(msg.sender == tx.origin, "RAP-OFF/ONLY_EOA");
        require(_amount <= 3, "RAP-OFF/MAX_3_PER_TX");

        if(state != State.LIVE) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "RAP-OFF/INCORRECT_PROOF");
            require(_numberMinted(msg.sender) + _amount <= 3, "RAP-OFF/MAX_3_PER_WALLET");
        }

        require(totalSupply() + _amount <= RAP_OFF_MAX, "RAP-OFF/EXCEEDS_SUPPLY");
        require(msg.value >= RAP_OFF_PRICE * _amount, "RAP-OFF/NOT_ENOUGH_ETH");
        _safeMint(msg.sender, _amount);
    }

    function reserveTeamTokens(address to, uint256 quantity) external onlyOwner {
        require(_reserveCounter + quantity <= RAP_OFF_RESERVE_MAX, "RAP-OFF/MAX_RESERVED");
        _reserveCounter += quantity;
        _safeMint(to, quantity);
    }

    function setState(State targetState) external onlyOwner {
        state = targetState;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function updateBaseURI(string memory newURI, bool reveal) external onlyOwner {
        baseURI = newURI;
        
        if(reveal) {
            revealed = reveal;
        }
    }

    function withdraw() external onlyOwner {
        payable(0x02495951e89D2978930f76dbe98f3a378506ECfa).transfer(address(this).balance / 10);
        payable(0x363D4dA163297C93E29312F05c34a64EAB5A7B9B).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) return _baseURI();
        return string(abi.encodePacked(_baseURI(), "/", tokenId.toString()));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}