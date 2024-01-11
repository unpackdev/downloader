// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721Pausable.sol";

contract BayApes is ERC721A, Ownable, Pausable {
    uint256 public immutable _maxSupply = 2221;
    uint256 public immutable _withheld = 62;
    uint256 public immutable _price = 0.5 ether;
    uint256 public immutable _presalePrice = 0.3 ether;
    uint256 public _ownerMinted = 0;
    uint256 public _maxPerWallet = 25;
    string public _baseTokenURI;
    bool public presaleActive = true;
    bytes32 public allowlistRoot;
    mapping(address => uint256) public _mintCount;

    constructor(bytes32 merkle) ERC721A("The Bay Apes", "TBA") {
        allowlistRoot = merkle;
    }

    function _mint(uint256 quantity) private {
        require(
            totalSupply() + quantity <= _maxSupply,
            "Maximum supply exceeded"
        );
        require(
            _mintCount[msg.sender] + quantity <= _maxPerWallet,
            "Max per wallet limit reached"
        );
        _safeMint(msg.sender, quantity);
        _mintCount[msg.sender] += quantity;
    }

    function mint(uint256 quantity) external payable {
        require(!presaleActive, "Whitelist only now");
        require(msg.value == _price * quantity, "Incorrect payment");
        _mint(quantity);
    }

    function presaleMint(uint256 quantity, bytes32[] calldata proof)
        public
        payable
    {
        require(presaleActive, "Presale over");

        require(
            MerkleProof.verify(
                proof,
                allowlistRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the list"
        );

        require(msg.value == quantity * _presalePrice, "Incorrect payment");
        _mint(quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    //
    // Admin
    //

    function setPresaleActive(bool active) public onlyOwner {
        presaleActive = active;
    }

    function ownerMint(uint256 quantity) public onlyOwner {
        require(_ownerMinted + quantity <= _withheld, "Owner already minted");
        _safeMint(msg.sender, quantity);
        _ownerMinted = _ownerMinted + quantity;
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
    }
}
