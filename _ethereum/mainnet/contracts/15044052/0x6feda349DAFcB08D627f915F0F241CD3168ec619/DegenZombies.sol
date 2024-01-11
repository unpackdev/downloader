//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

error AntiBot();
error PubSaleNotStarted();
error PreSaleNotStarted();
error PreSaleEnded();
error PubSaleEnded();
error ExceedMaxAmount();
error ExceedMaxSupply();
error ValueTooLow();
error NotTeam();

contract DegenZombies is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public reservedForTeam;
    uint256 private _mintedForTeam;
    uint256 public maxSupply;
    uint256 public maxPerAccount;
    uint256 public teaSalePrice;
    uint256 public pubSalePrice;
    string public baseUri;
    uint256 public puSaleTime;
    address public passwordSigner;
    mapping(address => uint256) private minted;

    constructor(
        uint256 _reservedForTeam,
        uint256 _maxSupply,
        uint256 _maxPerAccount,
        uint256 _teaSalePrice,
        uint256 _pubSalePrice,
        uint256 _puSaleTime,
        address _passwordSigner
    ) ERC721A("DegenZombies", "DGZB") {
        reservedForTeam = _reservedForTeam;
        maxSupply = _maxSupply;
        maxPerAccount = _maxPerAccount;
        teaSalePrice = _teaSalePrice;
        pubSalePrice = _pubSalePrice;
        puSaleTime = _puSaleTime;
        passwordSigner = _passwordSigner;
        _safeMint(msg.sender, 1);
    }

    /* Transactions */
    function teaSaleMint(uint256 amount, bytes memory signature)
        external
        payable
    {
        uint256 currentTime = block.timestamp;

        if (msg.sender != tx.origin) revert AntiBot();
        if (currentTime < puSaleTime) revert PubSaleNotStarted();
        if (!isTeam(msg.sender, signature)) revert NotTeam();
        if (_mintedForTeam + amount > reservedForTeam) revert ExceedMaxSupply();
        if (amount > maxPerAccount) revert ExceedMaxAmount();
        if (msg.value < uint256(int256(amount) / int256(3)) * teaSalePrice)
            revert ValueTooLow();

        _mintedForTeam += amount;
        _safeMint(msg.sender, amount);
    }

    function pubSaleMint(uint256 amount) external payable {
        uint256 currentTime = block.timestamp;

        if (msg.sender != tx.origin) revert AntiBot();
        if (currentTime < puSaleTime) revert PubSaleNotStarted();
        if (totalSupply() + amount > maxSupply - reservedForTeam)
            revert ExceedMaxSupply();
        if (minted[msg.sender] + amount > maxPerAccount)
            revert ExceedMaxAmount();
        if (msg.value < uint256(int256(amount) / int256(3)) * pubSalePrice)
            revert ValueTooLow();

        minted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    /* Utils */
    function isTeam(address user, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 message = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(user)))
            )
        );

        return recoverSigner(message, signature) == passwordSigner;
    }

    function recoverSigner(bytes32 _message, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /* Getters */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, id.toString(), ".json"));
    }

    /* Setters */
    function setReservedForTeam(uint256 _reservedForTeam) public onlyOwner {
        reservedForTeam = _reservedForTeam;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerAccount(uint256 _maxPerAccount) public onlyOwner {
        maxPerAccount = _maxPerAccount;
    }

    function setTeaSalePrice(uint256 _teaSalePrice) public onlyOwner {
        teaSalePrice = _teaSalePrice;
    }

    function setPubSalePrice(uint256 _pubSalePrice) public onlyOwner {
        pubSalePrice = _pubSalePrice;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setPuSaleTime(uint256 _puSaleTime) public onlyOwner {
        puSaleTime = _puSaleTime;
    }

    function setPasswordSigner(address _passwordSigner) public onlyOwner {
        passwordSigner = _passwordSigner;
    }
}
