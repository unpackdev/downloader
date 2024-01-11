// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract RoyalIsoroom is ERC721A, Ownable {
    string private _baseURIextended;

    string private constant ERR_LIMIT_EXCEED = "Limit exceeded";
    string private constant ERR_NOT_TARGET = "Not target address";
    string private constant ERR_NOT_SET_VAULT = "Vault not found";

    address public signer = 0x8168e7d3a63b08f8E4609cA74547e911809140d7;
    address public vaultAddress;
    bool public sealVaultAddress = false;

    uint256 public maxSupply = 1000;

    mapping(address => uint16) public mintingRecord;

    constructor() ERC721A("RoyalIsoroom", "RISOROOM") {}

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function mint(
        bytes calldata _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint16 _numberOfTokens
    ) external payable {
        address targetAddress = bytesToAddress(_message[:20]);
        require(msg.sender == targetAddress, ERR_NOT_TARGET);

        uint256 totalSupply = totalSupply();
        require(totalSupply + _numberOfTokens <= maxSupply, ERR_LIMIT_EXCEED);

        uint32 quota = uint32(bytes4(_message[20:24]));
        require(mintingRecord[msg.sender] + _numberOfTokens <= quota, ERR_LIMIT_EXCEED);

        address recoveredSigner = recoverSigner(_message, _v, _r, _s);
        require(signer == recoveredSigner, "Not correct signer");

        mintingRecord[msg.sender] += _numberOfTokens;
        _safeMint(msg.sender, _numberOfTokens);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        /**
         * Approval for isoroom vault for skiping transaction
         */
        if (operator == vaultAddress) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 _numberOfTokens) external onlyOwner {
        _safeMint(msg.sender, _numberOfTokens);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function recoverSigner(
        bytes calldata _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (address addr) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n24";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _message)
        );
        address recoveredSigner = ecrecover(prefixedHashMessage, _v, _r, _s);
        return recoveredSigner;
    }

    function setSealVaultAddress() external onlyOwner {
        require(vaultAddress != address(0x0), ERR_NOT_SET_VAULT);
        sealVaultAddress = true;
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= totalSupply(), ERR_LIMIT_EXCEED);
        maxSupply = _maxSupply;
    }
}
