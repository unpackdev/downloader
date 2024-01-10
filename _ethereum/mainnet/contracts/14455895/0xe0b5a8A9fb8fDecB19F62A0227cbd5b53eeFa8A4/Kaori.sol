// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Kaori is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public price = 0.088 ether;
    uint256 public constant maxSupply = 1000;
    uint256 private constant maxMintAmountPerTx = 2;
    uint256 private constant maxMintAmountPerWallet = 2;

    string public baseURL;
    string private baseExtension = ".json";
    string public HiddenURL;
    bytes32 public hashRoot;

    bool public presaleMintIsActive = false;
    bool public publicMintIsActive = false;
    bool public revealed = true;

    constructor() ERC721A("Kaori", "TDOK") {}

    // ================= Mint Function =======================

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(presaleMintIsActive, "Presale not active yet!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(msg.value >= price * _mintAmount, "Insufficient funds!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, hashRoot, leaf),
            "You are not whitelisted!"
        );

        uint256 mintedByWallet = _getAux(msg.sender) + _mintAmount;
        require(
            mintedByWallet <= maxMintAmountPerWallet,
            "Max mint per wallet exceeded!"
        );

        _setAux(msg.sender, mintedByWallet);
        _safeMint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount) external payable {
        require(publicMintIsActive, "Mint is not active!");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(msg.value >= price * _mintAmount, "Insufficient funds!");

        _safeMint(msg.sender, _mintAmount);
    }

    // =================== Owner only function ==================

    function flipPresaleMint() external onlyOwner {
        presaleMintIsActive = !presaleMintIsActive;
    }

    function flipPublicMint() external onlyOwner {
        publicMintIsActive = !publicMintIsActive;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function devMint(uint256 _mintAmount) external onlyOwner {
        _safeMint(msg.sender, _mintAmount);
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setbaseURL(string memory uri) external onlyOwner {
        //change to public if constructor need to call
        baseURL = uri;
    }

    function setHiddenURL(string memory uri) external onlyOwner {
        //change to public if constructor need to call
        HiddenURL = uri;
    }

    function setHashRoot(bytes32 hp) external onlyOwner {
        //change to public if constructor need to call
        hashRoot = hp;
    }

    function withdraw() external onlyOwner {
        address devAddress = 0x00E5c7839E9bdE6c440886C19519c3Ed4797E1A6;
        uint256 CurrentContractBalance = address(this).balance;
        uint256 devShare = (CurrentContractBalance * 10) / 100;
        uint256 ownerShare = (CurrentContractBalance * 90) / 100;

        (bool success, ) = payable(devAddress).call{value: devShare}("");
        require(success);

        (bool os, ) = payable(msg.sender).call{value: ownerShare}("");
        require(os);
    }

    // =================== View only function ======================

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return HiddenURL;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURL;
    }
}
