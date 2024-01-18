// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IMinteebleStaticMutation.sol";
import "./MinteebleERC721A.sol";
import "./DefaultOperatorFilterer.sol";

contract CabaChan is MinteebleERC721A, DefaultOperatorFilterer {
    address[] public members;
    uint256 public refPercentage = 10;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) MinteebleERC721A(_tokenName, _tokenSymbol, _maxSupply, _mintPrice) {}

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function addMember(address _member) public onlyOwner {
        members.push(_member);
    }

    function addMembers(address[] memory _members) public onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            members.push(_members[i]);
        }
    }

    function getMembers() public view returns (address[] memory) {
        return members;
    }

    function removeMember(uint256 _index) external onlyOwner {
        if (_index >= members.length) return;

        for (uint256 i = _index; i < members.length - 1; i++) {
            members[i] = members[i + 1];
        }
        members.pop();
    }

    function setRefPercentage(uint256 _perc) public onlyOwner {
        require(_perc <= 100, "Invalid value");

        refPercentage = _perc;
    }

    function refMint(uint256 _mintAmount, address _memberAddr)
        public
        payable
        canMint(_mintAmount)
        enoughFunds(_mintAmount)
        active
    {
        super.mint(_mintAmount);

        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _memberAddr) {
                (bool os, ) = payable(_memberAddr).call{
                    value: (msg.value / 100) * refPercentage
                }("");
                require(os);
                break;
            }
        }
    }
}
