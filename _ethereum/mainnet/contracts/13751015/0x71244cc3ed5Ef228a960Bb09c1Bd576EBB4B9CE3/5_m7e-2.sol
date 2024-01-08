pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";

contract M7e is ERC1155, Ownable {
    mapping(uint256 => string) private tokenUri;

    constructor() ERC1155("") public {}

    function mintBatch(address[] memory users, uint256[] memory types) external onlyOwner {
        require(users.length > 0 && users.length <= 50);
        require(users.length == types.length);

        for (uint256 i = 0 ; i < users.length; i++) {
            _mint(users[i], types[i], 1, "");
        }
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenUri[_id] = _uri;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenUri[_id];
    }
}

