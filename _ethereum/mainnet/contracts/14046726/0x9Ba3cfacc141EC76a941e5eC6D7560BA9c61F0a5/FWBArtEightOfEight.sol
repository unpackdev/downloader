pragma solidity >=0.6.2 <0.8.0;

//SPDX-License-Identifier: MIT

import "./ERC1155.sol";
import "./Ownable.sol";

contract FWBArtEightOfEight is ERC1155, Ownable {

    bool public claimable = true;

    mapping(address => bool) public allowList;
    mapping(address => bool) public claimed;

    constructor() public ERC1155("https://gateway.pinata.cloud/ipfs/QmWkvB3AotwkBUmidDVrC3i2HQSY5KtCstqFcUmVtecYhg/1.json") {}

    /**
    * @dev Override _beforeTokenTransfer to block transfers
    */
    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        // _beforeTokenTransfer is called in mint so allow address(0)
        // allow dead address in case people want to get rid of token
        address dead = 0x000000000000000000000000000000000000dEaD;
        require(_from == address(0) || _to == dead, "Token is non transferable"); 

        super._beforeTokenTransfer(_operator, _from, _to, _ids, _amounts, _data);
    }

    /**
    * @dev block any contract interractions to prevent listings
    */
    function setApprovalForAll(
        address operator, 
        bool approved
    ) public virtual override {
        revert("no approvals allowed");
    }

    function name() public pure returns (string memory) {
        return "FWB.art 8 of 8";
    }

    function symbol() public pure returns (string memory) {
        return "FWBART8OF8";
    } 

    function claim() public {
        require(claimable, "claim not active");
        require(allowList[msg.sender], "not allowed");
        require(!claimed[msg.sender], "already claimed");

        claimed[msg.sender] = true;
        _mint(msg.sender, 1, 1, "");
    }
    
    /* admin */
    function setBaseURI(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    function setClaimable(bool _claimable) public onlyOwner {
        claimable = _claimable;
    }

    function setAllowList(address[] calldata addresses, bool allowed) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = allowed;
        }
    }
}