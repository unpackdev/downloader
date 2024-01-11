// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract KEEVO is ERC721, Ownable {
    error NotTransferrable();

    event Granted(address indexed account, uint256 indexed tokenId);
    event Resigned(address indexed account, uint256 indexed tokenId);

    string private _baseUri;
    mapping(uint256 => bytes) private _data;
    address public operator;

    modifier onlyOperator() {
        require(operator == msg.sender, "Only operator can call this method");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _operator
    ) ERC721(name, symbol) {
        operator = _operator;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory uri) external onlyOperator {
        _baseUri = uri;
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function grant(address account, uint256 tokenId) external onlyOperator {
        _safeMint(account, tokenId);
        emit Granted(account, tokenId);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert NotTransferrable();
    }

    function resign(uint256 tokenId) external {
        address ownerOfERC721 = ERC721.ownerOf(tokenId);
        require(
            (msg.sender == ownerOfERC721) || (msg.sender == operator),
            "Only operator or owner of a token can resign it"
        );
        _burn(tokenId);
        emit Resigned(msg.sender, tokenId);
    }
}
