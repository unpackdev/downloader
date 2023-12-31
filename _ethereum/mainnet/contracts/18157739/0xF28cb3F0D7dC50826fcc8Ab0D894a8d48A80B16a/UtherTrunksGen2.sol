// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MRC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IERC20.sol";


contract UtherTrunksGen2 is MRC1155, Ownable {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant MALE = 1;
    uint256 public constant FEMALE = 2;

    // total number of NFTs that could be minted
    // in public sale
    uint256 public maxCap = 2805;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), 'Only Admin');
        _;
    }

    constructor(
    ) MRC1155(
        "The Uther Trunks 2",
        "TUT2",
        "https://uther-trunks2.communitynftproject.io/"
    )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    	_setupRole(ADMIN_ROLE, msg.sender);
    	_setupRole(MINTER_ROLE, msg.sender);
    }

    function _beforeMint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        require(id == MALE || id == FEMALE, "invalid id");
        require(totalSupply(MALE) + totalSupply(FEMALE) + amount <= maxCap, "> maxCap");
    }

    function uri(uint256 _id) override view public returns(string memory){
        return string(abi.encodePacked(
            super.uri(_id),
            Strings.toString(_id)
        ));
    }

    function setMaxCap(uint256 cap) public onlyAdmin{
        maxCap = cap;
    }

    // lets the owner withdraw ETH and ERC20 tokens
    function ownerWT(uint256 amount, address _to,
            address _tokenAddr) public onlyOwner{
        require(_to != address(0));
        if(_tokenAddr == address(0)){
            payable(_to).transfer(amount);
        }else{
            IERC20(_tokenAddr).transfer(_to, amount);
        }
    }
}
