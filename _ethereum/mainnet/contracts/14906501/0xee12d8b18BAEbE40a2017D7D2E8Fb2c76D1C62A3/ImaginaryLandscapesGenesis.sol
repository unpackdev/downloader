// SPDX-License-Identifier: MIT

//  ██▓ ███▄ ▄███▓ ▄▄▄        ▄████  ██▓ ███▄    █  ▄▄▄       ██▀███ ▓██   ██▓
// ▓██▒▓██▒▀█▀ ██▒▒████▄     ██▒ ▀█▒▓██▒ ██ ▀█   █ ▒████▄    ▓██ ▒ ██▒▒██  ██▒
// ▒██▒▓██    ▓██░▒██  ▀█▄  ▒██░▄▄▄░▒██▒▓██  ▀█ ██▒▒██  ▀█▄  ▓██ ░▄█ ▒ ▒██ ██░
// ░██░▒██    ▒██ ░██▄▄▄▄██ ░▓█  ██▓░██░▓██▒  ▐▌██▒░██▄▄▄▄██ ▒██▀▀█▄   ░ ▐██▓░
// ░██░▒██▒   ░██▒ ▓█   ▓██▒░▒▓███▀▒░██░▒██░   ▓██░ ▓█   ▓██▒░██▓ ▒██▒ ░ ██▒▓░
// ░▓  ░ ▒░   ░  ░ ▒▒   ▓▒█░ ░▒   ▒ ░▓  ░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░  ██▒▒▒
//  ▒ ░░  ░      ░  ▒   ▒▒ ░  ░   ░  ▒ ░░ ░░   ░ ▒░  ▒   ▒▒ ░  ░▒ ░ ▒░▓██ ░▒░
//  ▒ ░░      ░     ░   ▒   ░ ░   ░  ▒ ░   ░   ░ ░   ░   ▒     ░░   ░ ▒ ▒ ░░
//  ░         ░         ░  ░      ░  ░           ░       ░  ░   ░     ░ ░
//                                                                    ░ ░
//  ██▓    ▄▄▄       ███▄    █ ▓█████▄   ██████  ▄████▄   ▄▄▄       ██▓███  ▓█████   ██████
// ▓██▒   ▒████▄     ██ ▀█   █ ▒██▀ ██▌▒██    ▒ ▒██▀ ▀█  ▒████▄    ▓██░  ██▒▓█   ▀ ▒██    ▒
// ▒██░   ▒██  ▀█▄  ▓██  ▀█ ██▒░██   █▌░ ▓██▄   ▒▓█    ▄ ▒██  ▀█▄  ▓██░ ██▓▒▒███   ░ ▓██▄
// ▒██░   ░██▄▄▄▄██ ▓██▒  ▐▌██▒░▓█▄   ▌  ▒   ██▒▒▓▓▄ ▄██▒░██▄▄▄▄██ ▒██▄█▓▒ ▒▒▓█  ▄   ▒   ██▒
// ░██████▒▓█   ▓██▒▒██░   ▓██░░▒████▓ ▒██████▒▒▒ ▓███▀ ░ ▓█   ▓██▒▒██▒ ░  ░░▒████▒▒██████▒▒
// ░ ▒░▓  ░▒▒   ▓▒█░░ ▒░   ▒ ▒  ▒▒▓  ▒ ▒ ▒▓▒ ▒ ░░ ░▒ ▒  ░ ▒▒   ▓▒█░▒▓▒░ ░  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░
// ░ ░ ▒  ░ ▒   ▒▒ ░░ ░░   ░ ▒░ ░ ▒  ▒ ░ ░▒  ░ ░  ░  ▒     ▒   ▒▒ ░░▒ ░      ░ ░  ░░ ░▒  ░ ░
//   ░ ░    ░   ▒      ░   ░ ░  ░ ░  ░ ░  ░  ░  ░          ░   ▒   ░░          ░   ░  ░  ░
//     ░  ░     ░  ░         ░    ░          ░  ░ ░            ░  ░            ░  ░      ░
//                              ░               ░
//   ▄████ ▓█████  ███▄    █ ▓█████   ██████  ██▓  ██████
//  ██▒ ▀█▒▓█   ▀  ██ ▀█   █ ▓█   ▀ ▒██    ▒ ▓██▒▒██    ▒
// ▒██░▄▄▄░▒███   ▓██  ▀█ ██▒▒███   ░ ▓██▄   ▒██▒░ ▓██▄
// ░▓█  ██▓▒▓█  ▄ ▓██▒  ▐▌██▒▒▓█  ▄   ▒   ██▒░██░  ▒   ██▒
// ░▒▓███▀▒░▒████▒▒██░   ▓██░░▒████▒▒██████▒▒░██░▒██████▒▒
//  ░▒   ▒ ░░ ▒░ ░░ ▒░   ▒ ▒ ░░ ▒░ ░▒ ▒▓▒ ▒ ░░▓  ▒ ▒▓▒ ▒ ░
//   ░   ░  ░ ░  ░░ ░░   ░ ▒░ ░ ░  ░░ ░▒  ░ ░ ▒ ░░ ░▒  ░ ░
// ░ ░   ░    ░      ░   ░ ░    ░   ░  ░  ░   ▒ ░░  ░  ░
//       ░    ░  ░         ░    ░  ░      ░   ░        ░

pragma solidity 0.8.14;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";

contract ImaginaryLandscapesGenesis is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant MAX_PER_MINT = 2;
    uint256 public constant RESERVED_SUPPLY = 5;
    bool public canMintReserve = true;
    bool public publicSaleOpen = true;

    string public baseTokenURI;

    address public saleSigner;
    mapping(address => bool) public freeMinted;

    constructor(string memory baseURI, address signer)
        ERC721A("Imaginary Landscapes Genesis", "LANDSCAPESGENESIS")
    {
        setBaseURI(baseURI);
        setSaleSigner(signer);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function reserveNFTs() public onlyOwner {
        require(canMintReserve, "Already minted reserve");

        uint256 totalMinted = totalSupply();
        require(
            totalMinted + RESERVED_SUPPLY <= MAX_SUPPLY,
            "Not enough NFTs left to reserve"
        );

        _mint(msg.sender, RESERVED_SUPPLY);
        canMintReserve = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setSaleSigner(address _signer) public onlyOwner {
        saleSigner = _signer;
    }

    function setPublicSaleOpen(bool _status) public onlyOwner {
        publicSaleOpen = _status;
    }

    function mint(uint256 _count) public payable callerIsUser {
        require(publicSaleOpen, "Public Sale is closed.");
        require(
            _count > 0 && _count <= MAX_PER_MINT,
            "Cannot mint specified number of NFTs."
        );

        uint256 totalMinted = totalSupply();
        require(totalMinted + _count <= MAX_SUPPLY, "Not enough NFTs left!");
        require(
            msg.value >= PRICE * _count,
            "Not enough ether to purchase NFTs."
        );

        _mint(msg.sender, _count);
    }

    function freeMint(bytes memory signature) public callerIsUser {
        uint256 totalMinted = totalSupply();
        require(totalMinted < MAX_SUPPLY, "Not enough NFTs left!");
        require(!freeMinted[msg.sender], "Free mint has already been used.");
        require(validSignature(signature), "Invalid signature");

        _mint(msg.sender, 1);
        freeMinted[msg.sender] = true;
    }

    function validSignature(bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            saleSigner ==
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ),
                signature
            );
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
