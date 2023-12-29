pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";

contract Infinite is ERC721A, Ownable {
    using ECDSA for bytes32;

    address signer;
    uint256 public totalClaimed;
    mapping(address => bool) public claimed;
    uint256 public constant MAX_SUPPLY = 5000;
    string public baseUrl;

    error HadClaimed();
    error OutofMaxSupply();
    error InvalidSignarure();

    constructor(
        string memory _name,
        string memory _symbol,
        address signer_,
        string memory _baseUrl
    ) ERC721A(_name, _symbol) {
        baseUrl = _baseUrl;
        signer = signer_;
        _safeMint(msg.sender, 1);
        totalClaimed++;
    }

    function totalSupply() public view override returns (uint256) {
        unchecked {
            return super.totalSupply() - balanceOf(address(0xdead));
        }
    }

    function claim() external {
        if (claimed[msg.sender]) revert HadClaimed();
        if (!(totalClaimed < MAX_SUPPLY)) revert HadClaimed();
        _safeMint(msg.sender, 1);
        claimed[msg.sender] = true;
        totalClaimed++;
    }

    function burn(
        uint256 tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (keccak256(abi.encodePacked(msg.sender, tokenId)).toEthSignedMessageHash().recover(v, r, s) != signer) {
            revert InvalidSignarure();
        }
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }

    function batchBurn(uint256[] memory tokenids) external onlyOwner {
        uint256 len = tokenids.length;
        for (uint256 i; i < len; i++) {
            uint256 tokenid = tokenids[i];
            _burn(tokenid);
        }
    }

    function setBaseURI(string memory url) external onlyOwner {
        baseUrl = url;
    }
}
