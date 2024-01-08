// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// Ether Troopers Mint Pass NFT Contract
/// Website: ethertroopers.com
/// @author: niveyno

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract EtherTroopersMintPass is ERC721, Ownable {
    uint256 public totalSupply;
    uint256 public maxSupply = 500;
    uint256 public price = 0.05 ether;

    bool public publicsaleActive = true;
    mapping(address => uint8) public publicsaleMints;
    uint256 public publicsaleMintLimit = 2;

    address private _wallet1 = 0x9dB8922f8044d4cFE9C361b53C149fD5D63d90f9;
    address private _wallet2 = 0x4502F16e0Aa869EA9AAdC7f941e3dE472Af94100;
    address private _signingAuthority = 0x8753fD9b83f0C713CdbD19D21a3b448035d6E5ce;

    IERC721 public troopersContract;

    string public provenanceHash;
    string public baseURI;

    constructor() ERC721("Ether Troopers Mint Pass", "ETMP") {} //

    function mint(uint256 timestamp, uint256[] memory tokenIds, bytes memory signature) external payable {
        require(msg.sender == tx.origin, "Reverted");
        require(publicsaleActive, "Public sale is not active");
        uint256 count = tokenIds.length;
        require(totalSupply + count <= maxSupply, "Can not mint more than max supply");
        require(msg.value >= count * price, "Insufficient payment");
        require(publicsaleMints[msg.sender] + count <= publicsaleMintLimit, "Per wallet mint limit");
        require(block.timestamp <= timestamp, "Too late");
        require(
            recover(keccak256(abi.encode("\x19Ethereum Signed Message EtherTroopers Mint Pass:\n32", timestamp, tokenIds, _msgSender())), signature) ==
            _signingAuthority,
            "Not allowed"
        );
        for (uint256 i = 0; i < count; i++) {
            require(!_exists(tokenIds[i]) && tokenIds[i] > 0 && tokenIds[i] <= maxSupply, "Can not mint this token");
            totalSupply++;
            publicsaleMints[msg.sender]++;
            _mint(msg.sender, tokenIds[i]);
        }
    }

    function distributePayment() external onlyOwner {
        uint256 balance = address(this).balance;
        bool success = false;
        (success,) = _wallet1.call{value : balance * 93 / 100}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : balance * 7 / 100}("");
        require(success2, "Failed to send2");
    }

    function burnFrom(uint256 tokenId) external {
        require(msg.sender == address(troopersContract), "Not allowed");
        _burn(tokenId);
    }

    function togglePublicsale() external onlyOwner {
        publicsaleActive = !publicsaleActive;
        emit PublicsaleUpdated(publicsaleActive);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice);
    }

    function setPerWalletMintLimitForPublicsale(uint256 newLimit) external onlyOwner {
        publicsaleMintLimit = newLimit;
    }

    function setProvenanceHash(string memory newProvenanceHash) external onlyOwner {
        provenanceHash = newProvenanceHash;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMintPassContract(IERC721 newContractAddress) external onlyOwner {
        troopersContract = newContractAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function recover(bytes32 hash, bytes memory signature) internal returns(address) {
        return ECDSA.recover(hash, signature);
    }

    event PublicsaleUpdated(bool newStatus);
    event PriceUpdated(uint256 newPrice);
}
