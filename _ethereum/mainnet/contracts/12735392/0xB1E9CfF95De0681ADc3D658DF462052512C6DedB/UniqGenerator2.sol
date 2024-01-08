// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract UniqGenerator is ERC721Tradable{
    // ----- VARIABLES ----- //
    uint256 internal _verificationPrice;
    address internal _tokenForPaying;
    string public METADATA_PROVENANCE_HASH;
    uint256 public immutable ROYALTY_FEE;
    string internal _token_uri;
    mapping(bytes32 => bool) internal _isItemMinted;
    mapping(uint256 => bytes32) internal _hashOf;
    mapping(bytes32 => address) internal _verificationRequester;
    uint256 internal _tokenNumber;
    address internal _claimingAddress;

    // ----- MODIFIERS ----- //
    modifier notZeroAddress(address a) {
        require(a != address(0), "ZERO address can not be used");
        _;
    }

    constructor(
        address _proxyRegistryAddress,
        string memory _name,
        string memory _symbol,
        uint256 _verfifyPrice,
        address _tokenERC20,
        string memory _ttokenUri
    )
        notZeroAddress(_proxyRegistryAddress)
        ERC721Tradable(_name, _symbol, _proxyRegistryAddress)
    {
        ROYALTY_FEE = 750000; //7.5%
        _verificationPrice = _verfifyPrice;
        _tokenForPaying = _tokenERC20;
        _token_uri = _ttokenUri;
    }

    function getMessageHash(address _requester, bytes32 _itemHash)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_requester, _itemHash));
    }

    function burn(uint256 _tokenId) external {
        if (msg.sender != _claimingAddress) {
            require(
                _isApprovedOrOwner(msg.sender, _tokenId),
                "Ownership or approval required"
            );
        }
        _burn(_tokenId);
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignature(
        address _requester,
        bytes32 _itemHash,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_requester, _itemHash);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function isMintedForHash(bytes32 _itemHash) external view returns (bool) {
        return _isItemMinted[_itemHash];
    }

    function hashOf(uint256 _id) external view returns (bytes32) {
        return _hashOf[_id];
    }

    function royaltyInfo(uint256)
        external
        view
        returns (address receiver, uint256 amount)
    {
        return (owner(), ROYALTY_FEE);
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

    function verificationRequester(bytes32 _itemHash)
        external
        view
        returns (address)
    {
        return _verificationRequester[_itemHash];
    }

    function getClaimerAddress() external view returns (address) {
        return _claimingAddress;
    }

    function getVerificationPrice() external view returns (uint256) {
        return _verificationPrice;
    }

    function baseTokenURI() override public view returns (string memory) {
        return _token_uri;
    }

    function contractURI() public pure returns (string memory) {
        return "https://uniqly.com/api/nft-generator/";
    }

    // ----- PUBLIC METHODS ----- //
    function payForVerification(bytes32 _itemHash) external {
        require(!_isItemMinted[_itemHash], "Already minted");
        require(
            _verificationRequester[_itemHash] == address(0),
            "Verification already requested"
        );
        require(
            IERC20(_tokenForPaying).transferFrom(
                msg.sender,
                address(this),
                _verificationPrice
            )
        );
        _verificationRequester[_itemHash] = msg.sender;
    }

    function mintVerified(bytes32 _itemHash, bytes memory _signature) external {
        require(
            _verificationRequester[_itemHash] == msg.sender,
            "Verification Requester mismatch"
        );
        require(!_isItemMinted[_itemHash], "Already minted");
        require(
            verifySignature(msg.sender, _itemHash, _signature),
            "Signature mismatch"
        );
        _isItemMinted[_itemHash] = true;
        _safeMint(msg.sender, _tokenNumber);
        _hashOf[_tokenNumber] = _itemHash;
        _tokenNumber++;
    }

    // ----- OWNERS METHODS ----- //
    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function editTokenUri(string memory _ttokenUri) external onlyOwner{
        _token_uri = _ttokenUri;
    }

    function setTokenAddress(address _newAddress) external onlyOwner {
        _tokenForPaying = _newAddress;
    }

    function editVireficationPrice(uint256 _newPrice) external onlyOwner {
        _verificationPrice = _newPrice;
    }

    function editClaimingAdress(address _newAddress) external onlyOwner {
        _claimingAddress = _newAddress;
    }

    function recoverERC20(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }

    function receivedRoyalties(
        address,
        address _buyer,
        uint256 _tokenId,
        address _tokenPaid,
        uint256 _amount
    ) external {
        emit ReceivedRoyalties(owner(), _buyer, _tokenId, _tokenPaid, _amount);
    }

    event ReceivedRoyalties(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount
    );
}

interface Ierc20 {
    function transfer(address, uint256) external;
}
