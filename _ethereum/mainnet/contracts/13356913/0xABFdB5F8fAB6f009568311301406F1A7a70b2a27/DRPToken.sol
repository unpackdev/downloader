// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./base64.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";

// DRP + PrimeFlare 2021

contract DRPToken is ERC721Enumerable, Ownable {

    using Strings for uint256;
    uint256 public constant BUY_PRICE = 0.5 ether;
    uint8 public constant MAX_SUPPLY = 150;
    bool public salesActive = true;
    uint8[] public reserved = [3,13,14,15,19,20,22,24,25,32,36,38,39,42,47,50,52,53,54,56,57,58,70,71,76,77,78,81,86,92,93,97,98,99,102,104,109,114,115,119,120,121,124,125,127,128,135,145,148,149,150];

    mapping(uint8 => bool) private _approved;

    constructor() ERC721('DRPToken', 'DRP') {
        for(uint8 i = 0; i < reserved.length; i++){
            _approved[reserved[i]] = true;
        }
    }

    function checkApproval(uint8 tokenId) external view onlyOwner returns(bool) {
        return _isApproved(tokenId);
    }

    function toggleActive() external onlyOwner {
        salesActive = !salesActive;
    }

    function approveClaim(uint8 tokenId) public onlyOwner {
        require(totalSupply() <= MAX_SUPPLY, "All editions allocated");
        require(!_exists(tokenId), "Can not approve already claimed");
        require(tokenId > 0 && tokenId <= MAX_SUPPLY, "Edition number must be between 1 and 150");
        _setTokenApprovedStatus(tokenId, true);

    }

    function removeApproval(uint8 tokenId) public onlyOwner {
        require(!_exists(tokenId), "Can not remove approval on existing token");
        require(tokenId > 0 && tokenId <= MAX_SUPPLY, "Edition number must be between 1 and 150");
        _setTokenApprovedStatus(tokenId, false);
    }


    function claim(uint8 tokenId) external payable {
        require(salesActive, "Claim is not active");
        require(tx.origin == msg.sender, "Claim cannot be made from a contract");
        require(totalSupply() < MAX_SUPPLY, 'All available editions claimed');
        require(tokenId > 0 && tokenId <= MAX_SUPPLY, "Edition must be between 1-150");
        require(_isApproved(tokenId), "Token not approved to be claimed yet");
        require(msg.value >= BUY_PRICE, "Minimum buy amount not reached");
        _safeMint(msg.sender, tokenId);
    }

    function ownerClaim(uint8 tokenId) external onlyOwner {
        require(tokenId > 0 && tokenId <= MAX_SUPPLY, "Edition must be between 1-150");
        require(!_exists(tokenId), "Token has already been claimed");
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "URI query for non existent token");
        return string(abi.encodePacked("data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"SIGMA MALE GRINDSET #',tokenId.toString(),
                '","external_url":"https://drp.io","image":"',"ipfs://Qme4geDE8Az35QmiEX6naezFAssgrMVpzG1CJBfUS4DwJR/drp_lushsux_joker.mp4",
                '","description":"Respect the grindset. NFT tethered to limited edition physical print edition ', tokenId.toString(),
                ' of 150 by Lushsux.","attributes":[{"trait_type":"Edition Number","value":"',tokenId.toString(),'"}]}'
                )))));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Contract balance is 0");
        payable(msg.sender).transfer(balance);
    }

    function _isApproved(uint8 tokenId) internal view returns(bool){
        return _approved[tokenId];
    }

    function _setTokenApprovedStatus(uint8 tokenId, bool value) internal {
        _approved[tokenId] = value;
    }



}
