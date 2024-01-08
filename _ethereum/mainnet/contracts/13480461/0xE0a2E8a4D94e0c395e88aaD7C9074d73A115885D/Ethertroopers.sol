// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// Ether Troopers Mint Pass NFT Contract
/// Website: ethertroopers.com
/// @author: niveyno

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

interface IMintPass {
    function burnFrom(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract EtherTroopers is ERC721, Ownable {
    uint256 public totalSupply;
    uint256 public maxSupply = 8888;
    uint256 public price = 0.088 ether;

    bool public presaleActive = true;
    mapping(address => uint256) public presaleLimits;
    mapping(address => uint256) public presaleMintings;

    bool public publicsaleActive = false;
    mapping(address => uint8) public publicsaleMints;
    uint256 public publicsaleMintLimit = 8;

    address private _wallet1 = 0x9dB8922f8044d4cFE9C361b53C149fD5D63d90f9;
    address private _wallet2 = 0x4502F16e0Aa869EA9AAdC7f941e3dE472Af94100;
    address private _signingAuthority = 0x8753fD9b83f0C713CdbD19D21a3b448035d6E5ce;

    IMintPass public mintPassContract;

    string public provenanceHash;
    string public baseURI;

    constructor() ERC721("EtherTroopers", "TRPR") {}

    function mintPublicsale(uint256 count) external payable {
        require(_msgSender() == tx.origin, "Reverted");
        require(publicsaleActive, "Public sale is not active");
        require(totalSupply + count <= maxSupply, "Can not mint more than max supply");
        require(msg.value >= count * price, "Insufficient payment");
        require(publicsaleMints[_msgSender()] + count <= publicsaleMintLimit, "Per wallet mint limit");

        for (uint256 i = 0; i < count; i++) {
            totalSupply++;
            publicsaleMints[_msgSender()]++;
            _mint(_msgSender(), totalSupply);
        }
    }

    function mintWithWhitelist(uint256 timestamp, uint256 count, uint256 limit, bytes memory signature) external payable {
        require(presaleMintings[_msgSender()] + count <= limit, "More than limit");
        require(_msgSender() == tx.origin, "Reverted");
        require(presaleActive, "Presale sale is not active");
        require(totalSupply + count <= maxSupply, "Can not mint more than max supply");
        require(msg.value >= count * price, "Insufficient payment");
        require(block.timestamp <= timestamp, "Too late");
        require(
            recover(keccak256(abi.encode("\x19Ethereum Signed Message EtherTroopers:\n32", timestamp, limit, _msgSender())), signature) ==
            _signingAuthority,
            "Not allowed"
        );
        presaleLimits[_msgSender()] = limit;

        for (uint256 i = 0; i < count; i++) {
            totalSupply++;
            presaleMintings[_msgSender()]++;
            _mint(_msgSender(), totalSupply);
        }
    }

    function mintWithMintPass(uint256[] memory mintPassIds) external payable {
        uint256 count = mintPassIds.length;
        require(_msgSender() == tx.origin, "Reverted");
        require(presaleActive, "Presale is not active");
        require(totalSupply + count <= maxSupply, "Can not mint more than max supply");
        require(msg.value >= count * price, "Insufficient payment");

        for (uint256 i = 0; i < count; i++) {
            require(mintPassContract.ownerOf(mintPassIds[i]) == _msgSender(), "You don't own that mint pass");
            mintPassContract.burnFrom(mintPassIds[i]);
            totalSupply++;
            _mint(_msgSender(), totalSupply);
        }
    }

    function mintGiveaway(address[] memory winners) external onlyOwner {
        uint256 count = winners.length;
        require(_msgSender() == tx.origin, "Reverted");
        require(totalSupply + count <= maxSupply, "Can not mint more than max supply");

        for (uint256 i = 0; i < count; i++) {
            totalSupply++;
            _mint(winners[i], totalSupply);
        }
    }

    function distributePayment() external {
        require(msg.sender == _wallet1 || msg.sender == _wallet2, "Not authorized");
        uint256 balance = address(this).balance;
        bool success = false;
        (success,) = _wallet1.call{value : balance * 93 / 100}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : balance * 7 / 100}("");
        require(success2, "Failed to send2");
    }

    function togglePublicsale() external onlyOwner {
        publicsaleActive = !publicsaleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setPerWalletMintLimitForPublicsale(uint256 newLimit) external onlyOwner {
        publicsaleMintLimit = newLimit;
    }

    function setProvenanceHash(string memory newProvenanceHash) external onlyOwner {
        provenanceHash = newProvenanceHash;
    }

    function setMintPassContract(IMintPass newContractAddress) external onlyOwner {
        mintPassContract = newContractAddress;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function recover(bytes32 hash, bytes memory signature) internal returns (address) {
        return ECDSA.recover(hash, signature);
    }
}
