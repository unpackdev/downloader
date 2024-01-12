// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Strings.sol";
import "./BitMaps.sol";
import "./ERC721A.sol";

contract NekoClans is ERC721A, EIP712, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    enum SalePhase {
        WhiteList,
        Free,
        Public
    }
    string public baseURI;
    address private signerAddress;
    address private withdrawAddress;
    uint256 public immutable maxSupply = 5666;
    uint256 public immutable price = 0.00899 ether;
    uint256 public immutable maxWalletFreeSupply = 1;
    uint256 public immutable maxWalletWlSupply = 3;

    mapping(SalePhase => mapping(address => uint256)) public mintedCount;

    constructor() ERC721A("NekoClans", "NekoClans") EIP712("NekoClans", "1") {
        signerAddress = owner();
        withdrawAddress = owner();
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        withdrawAddress = newWithdrawAddress;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier isWithdrawAddress() {
        require(
            withdrawAddress == msg.sender,
            "The caller is incorrect address."
        );
        _;
    }

    function _hash(string memory _prefix, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_prefix, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, signature) == signerAddress);
    }

    function _recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function whiteListAdopt(
        uint256 quantity,
        bytes32 hash,
        bytes calldata signature
    ) external payable callerIsUser {
        require(
            mintedCount[SalePhase.WhiteList][msg.sender] + quantity <=
                maxWalletWlSupply,
            "maxMintWl:Too many nft to adopt."
        );
        mintedCount[SalePhase.WhiteList][msg.sender] += quantity;
        require(_hash("whiteList", msg.sender) == hash, "Invalid hash.");
        require(_verify(hash, signature), "Invalid signature.");
        unchecked {
            require(
                _totalMinted() + quantity <= maxSupply,
                "Max supply reached."
            );
        }
        _safeMint(msg.sender, quantity);
    }

    function publicAdopt(uint256 quantity) external payable callerIsUser {
        unchecked {
            require(
                _totalMinted() + quantity <= maxSupply,
                "Max supply reached."
            );
            uint256 walletFeeMinted = mintedCount[SalePhase.Free][msg.sender];
            uint256 freeQuantity = maxWalletFreeSupply > walletFeeMinted
                ? maxWalletFreeSupply - walletFeeMinted
                : 0;
            if (quantity > freeQuantity) {
                require(
                    msg.value >= price * (quantity - freeQuantity),
                    "Incorrect price."
                );
                mintedCount[SalePhase.Free][msg.sender] += freeQuantity;
                mintedCount[SalePhase.Public][msg.sender] += (quantity -
                    freeQuantity);
            } else {
                mintedCount[SalePhase.Free][msg.sender] += quantity;
            }
        }
        _safeMint(msg.sender, quantity);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdraw(address beneficiary) external onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    function withdraw() external isWithdrawAddress callerIsUser {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function getNftInfo(address _address)
        external
        view
        returns (
            uint256 _whitelistMinted,
            uint256 _freeMinted,
            uint256 _publicMinted,
            uint256 _priceWl,
            uint256 _maxMintWl,
            uint256 _priceFree,
            uint256 _maxMintFree,
            uint256 _pricePublic,
            uint256 _maxMintPublic,
            uint256 totalMinted
        )
    {
        return (
            mintedCount[SalePhase.WhiteList][_address],
            mintedCount[SalePhase.Free][_address],
            mintedCount[SalePhase.Public][_address],
            0,
            maxWalletWlSupply,
            0,
            maxWalletFreeSupply,
            price,
            5666,
            _totalMinted()
        );
    }
}
