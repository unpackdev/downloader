// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";


contract SqushyPuzzle is ERC721, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public cost = 0 ether;
    uint256 public maxSupply = 1111;
    string public baseURI;
    bool public mintingEnabled = true;
    mapping(address => uint) public claimedTokens;

    // private vars
    address private _signer;

    constructor(
        string memory _initBaseURI,
        address signer
    )
    ERC721("SqushyPuzzle", "SQP"){
        setBaseURI(_initBaseURI);
        _signer = signer;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    // using signer technique for managing approved minters
    function updateSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function _hash(address _address, uint amount, uint allowedAmount) internal view returns (bytes32){
        return keccak256(abi.encode(address(this), _address, amount, allowedAmount));
    }

    function _verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool){
        return (ecrecover(hash, v, r, s) == _signer);
    }

    // enable / disable minting
    function setMintState(bool _mintingEnabled) public onlyOwner {
        mintingEnabled = _mintingEnabled;
    }

    // minting function
    function mint(uint8 v, bytes32 r, bytes32 s, uint256 allowedAmount) public payable {
        require(mintingEnabled, "CONTRACT ERROR: minting has not been enabled");
        require(claimedTokens[msg.sender] + 1 <= allowedAmount, "CONTRACT ERROR: Address has already claimed max amount");
        require(cost == msg.value, "CONTRACT ERROR: incorrect amount of ether sent");
        require(totalSupply + 1 <= maxSupply, "CONTRACT ERROR: not enough remaining in supply to support desired mint amount");
        require(_verify(_hash(msg.sender, 1, allowedAmount), v, r, s), 'CONTRACT ERROR: Invalid signature');
        _safeMint(msg.sender, totalSupply);
        claimedTokens[msg.sender] += 1;
    }

}
