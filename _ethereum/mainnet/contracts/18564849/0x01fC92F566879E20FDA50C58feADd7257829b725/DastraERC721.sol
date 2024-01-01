// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;
pragma abicoder v2;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Counters.sol";
import "./ERC2771Context.sol";

contract DastraERC721 is ERC2771Context, Ownable, ERC721("Dastra", "DNFT") {
    using ECDSA for bytes32;
    
    mapping(address => bool) public signers;
    mapping(uint256 => bool) nonces;
    mapping(uint256 => string) uris;

    uint256 public nextTokenId;
    address public feeCollector;

    event SignerAdded(address _address);
    event SignerRemoved(address _address);
    event TokenMinted(uint256 _nonce, uint256 _tokenId);

    constructor(address _feeCollector, address trustedForwarder) ERC2771Context(trustedForwarder) {
        address sender = _msgSender();
        signers[sender] = true;
        emit SignerAdded(sender);
        feeCollector = _feeCollector;
    }

    function addSigner(address _address) external onlyOwner {
        signers[_address] = true;
        emit SignerAdded(_address);
    }

    function removeSigner(address _address) external onlyOwner {
        signers[_address] = false;
        emit SignerRemoved(_address);
    }

    function mint(
        uint256 _nonce,
        string memory _uri,
        bytes memory _signature,
        uint256 mintPrice
    ) public payable {
        address sender = _msgSender();
        uint256 _id = nextTokenId;

        require(
            nonces[_nonce] == false,
            "DastraERC721: Invalid nonce"
        );
        require(msg.value >= mintPrice, "DastraERC721: You should send enough funds for mint");
        require(bytes(_uri).length > 0, "DastraERC721: _uri is required");
        address signer = keccak256(
            abi.encodePacked(sender, _nonce, _uri, address(this), mintPrice)
        ).toEthSignedMessageHash().recover(_signature);
        
        require(signers[signer], "DastraERC721: Invalid signature");

        payable(feeCollector).transfer(mintPrice);

        _mint(sender, _id);

        emit TokenMinted(_nonce, _id);
        nonces[_nonce] = true;
        uris[_id] = _uri;
        nextTokenId += 1;
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        return uris[_id];
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}