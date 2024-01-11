// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract GrantrektHotel is ERC721A, Ownable {
    uint256 public immutable maxSupply;
    uint256 public immutable teamSupply;

    string public baseURI;
    uint32 public teamMinted;

    address private _signer;
    mapping(uint256 => uint256) private _usedNonces;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _teamSupply,
        string memory uri,
        address signer
    ) ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        teamSupply = _teamSupply;
        setBaseURI(uri);
        _signer = signer;
    }

    function mint() external payable {
        require(
            _numberMinted(msg.sender) + 1 <= 1,
            "Wallet limit exceeded."
        );
        require(
            totalSupply() + 1 + teamSupply - teamMinted <= maxSupply,
            "Max supply exceeded."
        );
        _safeMint(msg.sender, 1);
    }

    function raffleMint(
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public payable {
        require(
            _numberMinted(msg.sender) + amount <= 3,
            "Wallet limit exceeded."
        );
        require(
            totalSupply() + amount + teamSupply - teamMinted <= maxSupply,
            "Max supply exceeded."
        );
        require(
            _usedNonces[nonce] == 0,
            "Nonce already used."
        );
        require(
            verifySignature(msg.sender, amount, nonce, signature) == _signer,
            "Not authorized to mint."
        );
        _usedNonces[nonce] = 1;
        _safeMint(msg.sender, amount);
    }

    function verifySignature(
        address wallet,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public pure returns (address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(wallet, amount, nonce))
            ), signature
        );
    }

    function devMint(address to, uint32 amount) external onlyOwner {
        require(
            teamMinted + amount <= teamSupply,
            "Max supply exceeded."
        );
        teamMinted += amount;
        _safeMint(to, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
