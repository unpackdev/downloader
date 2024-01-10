//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Tiramisu is ERC721, Ownable {
    using Strings for uint256;

    string public baseTokenURI;
    mapping(address => bool) public claimedWL; // stores addresses that have claimed whitelisted tokens

    uint64 public constant PRICE = 0.05 ether;
    bytes32 public root; // merkle root set in constructor
    uint16 public tokenSupply;
    uint16 public constant MAX_SUPPLY = 1000;
    bool public premintPhase = true;

    address public constant ADDR_80 = 0x95645e9fCfEe7882DA368963d5A460308df24DD6;
    address public constant ADDR_20 = 0x705a47eBC6fCE487a3C64A2dA64cE2E3B8b2EF55;

    constructor(string memory baseURI, bytes32 initialRoot) ERC721('Tiramisu Recipe by STILLZ', 'TMISU') {
        baseTokenURI = baseURI;

        uint16 mintIndex = tokenSupply;
        for (uint16 i; i < 10; i++) {
            _incrementTokenSupply();
            _safeMint(ADDR_80, mintIndex + i);
        }

        setMerkleRoot(initialRoot);
    }

    /// @dev minting tokens after the premint phase
    function mint() external payable {
        require(!premintPhase, 'premint phase');
        require(msg.value == PRICE, 'incorrect ether amount supplied');
        issueToken(msg.sender);
    }

    /// @dev issues token to recipient
    function issueToken(address recipient) private {
        uint16 mintIndex = tokenSupply;
        require(mintIndex < MAX_SUPPLY, 'exceeds token supply');
        _incrementTokenSupply();
        _safeMint(recipient, mintIndex);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return (operator == 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b) ?
        true
        :
        super.isApprovedForAll(owner, operator);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool status1,) = ADDR_80.call{value : (balance * 8) / 10}("");
        (bool status2,) = ADDR_20.call{value : (balance * 2) / 10}("");
        require(status1 == true && status2 == true, 'withdraw failed');
    }

    function setIsPremintPhase(bool _isPremintPhase) public onlyOwner {
        premintPhase = _isPremintPhase;
    }

    function getTokensLeft() public view returns (uint16) {
        return MAX_SUPPLY - tokenSupply;
    }

    function _incrementTokenSupply() private {
        unchecked {
            tokenSupply += 1;
        }
    }


    function setMerkleRoot(bytes32 newRoot) public onlyOwner {
        root = newRoot;
    }

    function _leaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) private view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /// @dev allows whitelisted users to claim their tokens during the premint phase
    function redeem(bytes32[] calldata proof) external {
        require(premintPhase, 'not a premint phase');
        require(_verify(_leaf(msg.sender), proof), "invalid merkle proof");
        require(!claimedWL[msg.sender], "already claimed");
        claimedWL[msg.sender] = true;
        issueToken(msg.sender);
    }
}
