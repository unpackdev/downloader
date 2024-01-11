// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ECDSA.sol";


interface Web3NycGalleryInterface {
    function mint(address to, uint256 tokenId) external;
    function multiMint(address _to, uint256[] memory tokenIds) external;
    function totalSupply()external view returns(uint256 totalSupply);
}

contract Web3NYCMinter is AccessControl{
    using ECDSA for bytes32;

    Web3NycGalleryInterface nftContract;
    bool public presaleIsActive = false;
    bool public saleIsActive = false;
    uint256 public maxSupply = 300;
    address public signerAddress = 0x7E4723A50108AC20CBE09cD9F656bd065f5B42c8; 

    mapping (uint256 => bool) public claimedTokens;


    constructor(address nftAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        nftContract = Web3NycGalleryInterface(nftAddress);
    }

    receive() external payable {}
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
    function flipSaleState() external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleIsActive = !presaleIsActive;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = _maxSupply;
    }

    function setSignerAddress(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signerAddress = signer;
    }

    function _hash(address _address, uint256 tokenId, uint256 price) internal view returns (bytes32) {
        return keccak256(abi.encode(address(this),_address, tokenId, price)).toEthSignedMessageHash();
    }

    function _verify( bytes memory signature, uint256 tokenId, uint256 price) internal view returns (bool) {
        return (_hash(msg.sender, tokenId, price).recover(signature) == signerAddress);
    }

    function presaleMint(uint256[] memory tokenIds, uint256[] memory values, bytes[] calldata _signatures) payable external {
        uint256 amount = tokenIds.length;
        uint256 totalValue;
        require(presaleIsActive, "sale not live");
        require(nftContract.totalSupply() + amount <= maxSupply, "sold out");
        for (uint i = 0; i < amount; i++) {
            require(!claimedTokens[tokenIds[i]], "token already claimed");
            require(_verify(_signatures[i], tokenIds[i], values[i]), "bad signature");
            claimedTokens[tokenIds[i]] = true;
            totalValue += values[i];
        }
        require(totalValue == msg.value, "wrong eth value");
        nftContract.multiMint(msg.sender, tokenIds);
    }

    function publicMint(uint256[] memory tokenIds, uint256[] memory values, bytes[] calldata _signatures) payable external {
        uint256 amount = tokenIds.length;
        uint256 totalValue;
        require(saleIsActive, "sale not live");
        require(nftContract.totalSupply() + amount <= maxSupply, "sold out");
        for (uint i = 0; i < amount; i++) {
            require(!claimedTokens[tokenIds[i]], "token already claimed");
            require(_verify(_signatures[i], tokenIds[i], values[i]), "bad signature");
            claimedTokens[tokenIds[i]] = true;
            totalValue += values[i];
        }
        require(totalValue == msg.value, "wrong eth value");
        nftContract.multiMint(msg.sender, tokenIds);
    }
}
