// SPDX-License-Identifier: MIT

/*

░██████╗███╗░░░███╗░█████╗░██╗░░░░░███████╗██████╗░███████╗███╗░░██╗░██████╗███╗░░██╗███████╗████████╗░░░░█████╗░░█████╗░███╗░░░███╗
██╔════╝████╗░████║██╔══██╗██║░░░░░██╔════╝██╔══██╗██╔════╝████╗░██║██╔════╝████╗░██║██╔════╝╚══██╔══╝░░░██╔══██╗██╔══██╗████╗░████║
╚█████╗░██╔████╔██║██║░░██║██║░░░░░█████╗░░██████╔╝█████╗░░██╔██╗██║╚█████╗░██╔██╗██║█████╗░░░░░██║░░░░░░██║░░╚═╝██║░░██║██╔████╔██║
░╚═══██╗██║╚██╔╝██║██║░░██║██║░░░░░██╔══╝░░██╔══██╗██╔══╝░░██║╚████║░╚═══██╗██║╚████║██╔══╝░░░░░██║░░░░░░██║░░██╗██║░░██║██║╚██╔╝██║
██████╔╝██║░╚═╝░██║╚█████╔╝███████╗██║░░░░░██║░░██║███████╗██║░╚███║██████╔╝██║░╚███║██║░░░░░░░░██║░░░██╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚═╝░░░░░╚═╝░╚════╝░╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝╚═════╝░╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░╚═╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
 */

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract SmolFrens is ERC721Enumerable, Ownable {
    bytes32 public merkleRoot;
    string public baseTokenURI;
    uint public price;
    uint public status;

    mapping(uint => mapping(address => bool)) public denylist;

    constructor() ERC721("SmolFrens", "Frens") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setStatus(uint _status) external onlyOwner {
        status = _status;
    }

    function claim(bytes32[] calldata _merkleProof, uint256 _amount) external {
        uint256 supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        require(status == 10, 'Claim Not Active');
        require(!denylist[0][msg.sender], 'Mint Is Claimed');
        require(supply + _amount < 8889, 'Supply Maxed');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }

        denylist[0][msg.sender] = true;
    }

    function whitelistsale(bytes32[] calldata _merkleProof, uint _amount) external payable {
        uint supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(status == 20, 'Whitelist Mint Not Live');
        require(_amount < 11, 'Amount Surplus');
        require(!denylist[1][msg.sender], 'Mint Is Claimed');
        require(supply + _amount < 8889, 'Supply Maxed');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(msg.value >= price * _amount, 'Ether Amount Insufficient');
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

        for(uint i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }

        denylist[1][msg.sender] = true;
    }

    function mint(uint _amount) external payable {
        uint supply = totalSupply();

        require(status == 30, 'Public Mint Not Live');
        require(_amount < 11, 'Amount Surplus');
        require(supply + _amount < 8889, 'Supply Maxed');
        require(tx.origin == msg.sender, 'Contract Denied');
        require(msg.value >= price * _amount, 'Ether Amount Insufficient');

        for(uint i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function withdraw() external payable onlyOwner {
        uint256 p1 = address(this).balance * 40 / 100;
        uint256 p2 = address(this).balance * 40 / 100;
        uint256 p3 = address(this).balance * 10 / 100;
        uint256 p4 = address(this).balance * 10 / 100;

        require(payable(0x8FA9FAA437446eCbC9C2f7436B9328603E03817d).send(p1));
        require(payable(0xCd3DCDefDb63FFF60F93130aeE4d727F109Aa020).send(p2));
        require(payable(0xA038A64eD671b257b0b12F4812B3cC0C9591Ebcb).send(p3));
        require(payable(0xfB9bE452316754a94f46aD36F6bd279699FB3840).send(p4));
    }
}