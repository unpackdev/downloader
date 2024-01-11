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
error NotWhitelisted();

contract Junglemaniacs is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply;
    uint256 public maxPerAccount;

    uint256 public preSalePrice;
    uint256 public pubSalePrice;

    string public baseUri;
    string public unreUri;

    uint256 public prSaleTime;
    uint256 public puSaleTime;
    uint256 public revealTime;

    address private passwordSigner;

    constructor(
        uint256 _maxSupply,
        uint256 _maxPerAccount,
        uint256 _preSalePrice,
        uint256 _pubSalePrice,
        uint256 _prSaleTime,
        uint256 _puSaleTime,
        uint256 _revealTime,
        address _passwordSigner
    ) ERC721A("GenericContract", "GENC") {
        maxSupply = _maxSupply;
        maxPerAccount = _maxPerAccount;
        preSalePrice = _preSalePrice;
        pubSalePrice = _pubSalePrice;
        prSaleTime = _prSaleTime;
        puSaleTime = _puSaleTime;
        revealTime = _revealTime;
        passwordSigner = _passwordSigner;
        _safeMint(msg.sender, 1);
    }

    /* Transactions */
    function preSaleMint(uint256 amount, bytes memory signature)
        external
        payable
    {
        uint256 currentTime = block.timestamp;

        if (msg.sender != tx.origin) revert AntiBot();
        if (!isWhitelisted(msg.sender, signature)) revert NotWhitelisted();
        if (currentTime > puSaleTime) revert PreSaleEnded();
        if (currentTime < prSaleTime) revert PreSaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert ExceedMaxSupply();
        if (amount > maxPerAccount) revert ExceedMaxAmount();
        if (msg.value < amount * preSalePrice) revert ValueTooLow();

        _safeMint(msg.sender, amount);
    }

    function pubSaleMint(uint256 amount) external payable {
        uint256 currentTime = block.timestamp;

        if (msg.sender != tx.origin) revert AntiBot();
        if (currentTime < puSaleTime) revert PubSaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert ExceedMaxSupply();
        if (amount > maxPerAccount) revert ExceedMaxAmount();
        if (msg.value < amount * pubSalePrice) revert ValueTooLow();

        _safeMint(msg.sender, amount);
    }

    /* Utils */
    function isWhitelisted(address user, bytes memory signature)
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
        uint256 currentTime = block.timestamp;

        if (currentTime < revealTime || bytes(baseUri).length == 0) {
            return unreUri;
        } else {
            return string(abi.encodePacked(baseUri, id.toString(), ".json"));
        }
    }

    /* Setters */
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerAccount(uint256 _maxPerAccount) public onlyOwner {
        maxPerAccount = _maxPerAccount;
    }

    function setPreSalePrice(uint256 _preSalePrice) public onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setPubSalePrice(uint256 _pubSalePrice) public onlyOwner {
        pubSalePrice = _pubSalePrice;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setUnreUri(string memory _unreUri) public onlyOwner {
        unreUri = _unreUri;
    }

    function setPrSaleTime(uint256 _prSaleTime) public onlyOwner {
        prSaleTime = _prSaleTime;
    }

    function setPuSaleTime(uint256 _puSaleTime) public onlyOwner {
        puSaleTime = _puSaleTime;
    }

    function setRevealTime(uint256 _revealTime) public onlyOwner {
        revealTime = _revealTime;
    }

    function setPasswordSigner(address _passwordSigner) public onlyOwner {
        passwordSigner = _passwordSigner;
    }
}
