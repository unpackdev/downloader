//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";

contract TigerVip is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public FACES_PROVENANCE = ""; // IPFS PROVENANCE TO BE ADDED WHEN SOLD OUT
    
    address devWallet = 0xd683eb2F7214Ef5a86A1815Ad431410ddD45BAbb;
    address designerWallet = 0x8F6D7f8e27EB55563FBd036C41379714b8DB0146;

    string public LICENSE_TEXT = "";

    bool licenseLocked = false;

    bytes32 public merkleRoot = 0x608d11effd83691f72a3ae5dd473e3fb90b43e791b17a22db46b05f7abfa6698;

    mapping(address => bool) public whitelistClaimed;

    string private newBaseURI;

    // uint256 public facePrice = 50000000000000000; // 0.050 ETH
    uint256 public facePrice = 100000000000000000; // 0.1 ETH
    uint256 public whitelistPrice = 70000000000000000; // 0.07 ETH

    uint256 public constant maxFacePurchase = 50;

    uint256 public constant MAX_FACES = 10000;

    bool public saleIsActive = false;

    uint256 public faceReserve = 200; // Reserve 250 faces for team & community (Used in giveaways, events etc...)

    event licenseisLocked(string _licenseText);

    constructor() ERC721("Stripes Tiger", "STRIPES") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserveFaces(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= faceReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        faceReserve = faceReserve.sub(_reserveAmount);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        FACES_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        newBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return newBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Returns the license for tokens
    function tokenLicense(uint256 _id) public view returns (string memory) {
        require(_id < totalSupply(), "CHOOSE A FACE WITHIN RANGE");
        return LICENSE_TEXT;
    }

    // Locks the license to prevent further changes
    function lockLicense() public onlyOwner {
        licenseLocked = true;
        emit licenseisLocked(LICENSE_TEXT);
    }

    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function getWhitelistAddr(address index) public view returns (bool)  {
        return whitelistClaimed[index];
    }

    function mintFace(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Face");
        require(
            0 < numberOfTokens && numberOfTokens <= maxFacePurchase,
            "Can only mint 50 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_FACES,
            "Purchase would exceed max supply of Faces"
        );

        if (msg.value == whitelistPrice) {
            whitelistClaimed[msg.sender] = true;
            require(
                msg.value >= whitelistPrice,
                "Ether value sent is not correct"
            );

            for (uint256 i = 0; i < 1; i++) {
                uint256 mintIndex = totalSupply();
                if (totalSupply() < MAX_FACES) {
                    _safeMint(msg.sender, mintIndex);
                }
            }
        } else {
            require(
                msg.value >= facePrice.mul(numberOfTokens),
                "Ether value sent is not correct"
            );

            for (uint256 i = 0; i < numberOfTokens; i++) {
                uint256 mintIndex = totalSupply();
                if (totalSupply() < MAX_FACES) {
                    _safeMint(msg.sender, mintIndex);
                }
            }
        }
    }

    function setFacePrice(uint256 newPrice) public onlyOwner {
        facePrice = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }
}
