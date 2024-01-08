//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./ECDSA.sol";

contract UnopndSouvenirV1 is ERC1155Supply, Ownable {
    using ECDSA for bytes32;

    constructor() ERC1155("") Ownable() {}

    string[] private _uri;
    string public contractURI;

    mapping(bytes32 => bool) public redeemed;
    uint256[] public mintableUntil;
    address public redeemCodeSigner;

    event PermanentURI(string _value, uint256 indexed _id);

    modifier onlyWhenMintable(uint256 id) {
        require(mintableUntil[id] > block.timestamp, "Not mintable");
        _;
    }

    function updateContractURI(string memory uri_) public onlyOwner {
        contractURI = uri_;
    }

    function setRedeemCodeSigner(address signer) public onlyOwner {
        redeemCodeSigner = signer;
    }

    function registerNew(string memory uri_, uint256 timestamp)
        public
        onlyOwner
    {
        require(timestamp > block.timestamp, "This is not mintable");
        _uri.push(uri_);
        mintableUntil.push(timestamp);
        emit PermanentURI(uri_, _uri.length - 1);
    }

    function getRedeemCode(uint256 id, bytes32 emailHash)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(id, emailHash));
    }

    function mint(
        uint256 id,
        bytes32 emailHash,
        bytes memory sig
    ) public onlyWhenMintable(id) {
        bytes32 redeemCode = keccak256(abi.encodePacked(id, emailHash));
        require(
            redeemCodeSigner == redeemCode.recover(sig),
            "Signature is not valid"
        );
        require(!redeemed[redeemCode], "Already used");
        redeemed[redeemCode] = true;
        _mint(msg.sender, id, 1, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _uri[id];
    }
}
