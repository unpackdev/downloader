// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;
pragma abicoder v2;

import "Ownable.sol";
import "ECDSA.sol";
import "ERC1155.sol";
import "IERC1155.sol";
import "IMintywayRoyalty.sol";


contract MintywayERC1155TokenETH is Ownable, ERC1155, IMintywayRoyalty {
    using ECDSA for bytes32;

    mapping(address => bool) public signers;
    mapping(uint256 => bool) nonces;
    mapping(uint256 => string) uris;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public royalties;

    uint256 public nextTokenId;

    uint256 private _mintPrice = 10**16;
    
    event SignerAdded(address _address);
    event SignerRemoved(address _address);
    event TokenMinted(uint256 _nonce, uint256 _tokenId);

    constructor() ERC1155("") {
        address _msgSender = msg.sender;
        transferOwnership(_msgSender);
        signers[_msgSender] = true;
        emit SignerAdded(_msgSender);
    }

    function addSigner(address _address) public onlyOwner {
        signers[_address] = true;
        emit SignerAdded(_address);
    }

    function removeSigner(address _address) public onlyOwner {
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
        uint256 _amount,
        string memory _uri,
        bytes memory _signature,
        uint256 royalty
    ) public payable {

        address _msgSender = msg.sender;
        uint256 _id = nextTokenId;

        require(msg.value >= _mintPrice, "CollectionToken: mint costs 0.001 ETH");
        require(
            nonces[_nonce] == false,
            "CollectionToken: Invalid nonce"
        );
        require(
            creators[_id] == address(0),
            "CollectionToken: Token is already minted"
        );
        require(royalty <= 50, "SingularToken: royalty must be lower then 50%");
        require(_amount > 0, "CollectionToken: Amount should be positive");
        require(bytes(_uri).length > 0, "CollectionToken: URI should be set");

        address signer = keccak256(
            abi.encodePacked(_msgSender, _nonce, _amount, _uri, address(this))
        ).toEthSignedMessageHash().recover(_signature);
        require(signers[signer], "Invalid signature");

        _mint(_msgSender, _id, _amount, "");

        emit TokenMinted(_nonce, _id);

        nonces[_nonce] = true;
        uris[_id] = _uri;
        creators[_id] = _msgSender;
        royalties[_id] = royalty;
        nextTokenId += 1;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return uris[_id];
    }

    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
