// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;
pragma abicoder v2;

import "Ownable.sol";
import "ECDSA.sol";
import "ERC721.sol";
import "IERC721.sol";
import "Counters.sol";
import "IMintywayRoyalty.sol";

contract MintywayERC721TokenETH is Ownable, ERC721, IMintywayRoyalty {
    using ECDSA for bytes32;
    
    mapping(address => bool) public signers;
    mapping(uint256 => bool) nonces;
    mapping(uint256 => string) uris;
    mapping(uint256 => address) internal creators;
    mapping(uint256 => uint256) internal royalties;

    uint256 public nextTokenId;

    uint256 private _mintPrice = 10**15;

    event SignerAdded(address _address);
    event SignerRemoved(address _address);
    event TokenMinted(uint256 _nonce, uint256 _tokenId);

    constructor() ERC721("MintyWay", "MYWY") {
        address _msgSender = msg.sender;

        transferOwnership(_msgSender);
        signers[_msgSender] = true;
        emit SignerAdded(_msgSender);
    }

    function addSigner(address _address) external onlyOwner {
        signers[_address] = true;
        emit SignerAdded(_address);
    }

    function removeSigner(address _address) external onlyOwner {
        signers[_address] = false;
        emit SignerRemoved(_address);
    }

    function royaltyOf(uint256 _id) external view returns(uint256){
        return royalties[_id];
    }

    function creatorOf(uint256 _id) external view returns(address){
        return creators[_id];
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        _mintPrice = mintPrice;
    }

    function getMintPrice() external view returns(uint256){
        return _mintPrice;
    }

    function mint(
        uint256 _nonce,
        string memory _uri,
        bytes memory _signature,
        uint256 royalty
    ) public payable {
        address _msgSender = msg.sender;
        uint256 _id = nextTokenId;

        require(msg.value >= _mintPrice, "SingularToken: mint costs 0.001 ETH");
        require(royalty <= 50, "SingularToken: royalty must be lower then 50%");
        require(
            nonces[_nonce] == false,
            "SingularToken: Invalid nonce"
        );
        require(bytes(_uri).length > 0, "SingularToken: _uri is required");
        
        address signer = keccak256(
            abi.encodePacked(_msgSender, _nonce, _uri, address(this))
        ).toEthSignedMessageHash().recover(_signature);
        require(signers[signer], "SingularToken: Invalid signature");

        _mint(_msgSender, _id);

        emit TokenMinted(_nonce, _id);

        nonces[_nonce] = true;
        uris[_id] = _uri;
        creators[_id] = _msgSender;
        royalties[_id] = royalty; 
        nextTokenId += 1;
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        return uris[_id];
    }

    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
