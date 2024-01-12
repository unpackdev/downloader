// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Base64.sol";
import "./Strings.sol";

contract WEB3IN2032 is ERC721A, Ownable {
    using ECDSA for bytes32;

    enum Status {
        Waiting,
        Started
    }

    Status public status;
    address private _signer;

    mapping(uint256 => string) public messageImageURIs;
    mapping(uint256 => string) public messageDates;
    mapping(uint256 => string) public messagePrices;

    event Minted(address minter, uint256 tokenId);
    event StatusChanged(Status status);
    event SignerChanged(address signer);

    constructor(address signer) ERC721A("Web3 in 2032", "WEB3IN2032") {
        _signer = signer;
    }

    function _hash(
        address addr,
        string memory imageURI,
        string memory messageDate,
        uint256 price
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(addr, imageURI, messageDate, price));
    }

    function _verify(bytes32 hash, bytes memory token)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function mint(
        string calldata imageURI,
        string calldata messageDate,
        string calldata messagePrice,
        bytes calldata signature
    ) external payable {
        require(
            status == Status.Started,
            "WEB3IN2032: Public mint is not active."
        );
        require(
            tx.origin == msg.sender,
            "WEB3IN2032: contract is not allowed to mint."
        );
        require(
            _verify(
                _hash(msg.sender, imageURI, messageDate, msg.value),
                signature
            ),
            "WEB3IN2032: Invalid signature."
        );

        uint256 currentIndex = _currentIndex;
        _safeMint(msg.sender, 1);
        messageImageURIs[currentIndex] = imageURI;
        messageDates[currentIndex] = messageDate;
        messagePrices[currentIndex] = messagePrice;

        emit Minted(msg.sender, currentIndex);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "WEB3IN2032: Transfer failed.");
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory imageURI = messageImageURIs[tokenId];
        string memory messageDate = messageDates[tokenId];
        string memory messagePrice = messagePrices[tokenId];
        if (bytes(imageURI).length == 0) {
            return "";
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "WEB3IN2032 #',
                        Strings.toString(tokenId),
                        '","description": "WEB3IN2032 documents some of the things that happened on Web3 in 2032.",',
                        '"image": "',
                        imageURI,
                        '","attributes": [{"trait_type": "date", "value": "',
                        messageDate,
                        '"}, {"trait_type": "price", "value": "',
                        messagePrice,
                        '"}]}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
