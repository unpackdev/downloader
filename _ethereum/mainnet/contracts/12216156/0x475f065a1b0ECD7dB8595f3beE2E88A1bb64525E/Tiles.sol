pragma solidity >=0.6.0 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract Tiles is ERC1155, Ownable {
    constructor() public ERC1155("https://token.milliontokenwebsite.com/info/{id}.json") {}

    function mint(address account, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) public onlyOwner {
        _mintBatch(account, ids, amounts, data);
    }
}
