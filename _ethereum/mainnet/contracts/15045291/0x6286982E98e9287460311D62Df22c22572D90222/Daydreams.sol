// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// @author: oriku.xyz

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//            .'                 .'                                                         //
//       .-..'  .-. .    .-..-..'   .;.::..-.  .-.    . ,';.,';.      .                     //
//      :   ;  ;   : `:  ; :   ;    .;  .;.-' ;   :   ;;  ;;  ;;    .';                     //
//      `:::'`.`:::'-'`.'  `:::'`..;'    `:::'`:::'-'';  ;;  ';   .' .'                     //
//                 -.;'                             _;        `-''                          //
//                                                                                          //
//      The Official Collection – by Taisei                                                 //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract Daydreams is ERC721A, Ownable, ReentrancyGuard {  
    bytes32 public merkleRoot;
    uint public total;
    uint public teamMinted;
    uint public reserves;
    uint public maxMint;
    uint8 public phase;

    uint public constant PRESALE_MINT_PRICE = 0.06 ether;
    uint public constant MINT_PRICE = 0.08 ether;

    address private treasury;
    string private baseURI;
    mapping(address => uint) private claimed;

    constructor(
        address _treasury,
        uint _total,
        uint _reserves,
        uint _maxMint
    ) ERC721A("Daydreams", "DAYDREAM") {
        treasury = _treasury;
        total = _total;
        reserves = _reserves;
        maxMint = _maxMint;
    }

    receive() external payable {}

    function mint(uint256 _qty) external payable {
        uint supply = totalSupply();

        require(phase == 2, "Mint not active");
        require(claimed[_msgSender()] + _qty <= maxMint, "Minting too many");
        require(msg.sender == tx.origin, "No contract mints");
        require(supply + _qty <= (total - reserves), "Minting exceeds total");
        require(MINT_PRICE * _qty == msg.value, "Invalid funds");

        claimed[_msgSender()] += _qty;
        _safeMint(_msgSender(), _qty);
    }

    function presaleMint(uint256 _qty, uint256 _maxQty, bytes32[] calldata _merkleProof) external payable {
        uint supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _maxQty));

        require(phase == 1, "Mint not active");
        require(claimed[_msgSender()] + _qty <= maxMint, "Minting too many");
        require(claimed[_msgSender()] + _qty <= _maxQty, "Minting too many");
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not on the list");
        require(supply + _qty <= (total - reserves), "Minting exceeds total");
        require(PRESALE_MINT_PRICE * _qty == msg.value, "Invalid funds");

        claimed[_msgSender()] += _qty;
        _safeMint(_msgSender(), _qty);
    }

    function teamMint(uint _qty) public {
        uint supply = totalSupply();

        require(treasury == _msgSender(), "Unauthorized");
        require(supply + _qty <= total, "Minting exceeds total");
        require(teamMinted + _qty <= reserves, "Minting exceeds reserved supply");

        teamMinted += _qty;
        _safeMint(treasury, _qty);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isOnPresaleList(uint256 _maxQty, bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _maxQty));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
  
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setPhase(uint8 _value) public onlyOwner {
        require(_value <= 2, "Invalid phase");
        phase = _value;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function withdraw() public nonReentrant {
        require(treasury == _msgSender(), "Unauthorized");
        (bool success,) = _msgSender().call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }

    function getBalance() external view returns(uint) {
        return (address(this)).balance;
    }
}
