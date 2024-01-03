// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721AContract.sol";

contract ERC721AFactory is Ownable {

    mapping(address => bool) public allowlist;
    mapping(address => address) public deployments;
    address public fiatMinter;
    address public r2eAddress;
    address public dcAddress;
    ERC721AContract[] private nfts;

    function updateAllowlist(address _address, bool _active) external onlyOwner {
        allowlist[_address] = _active;
    }

    function updateConfig(address _fiatMinter, address _r2eAddress, address _dcAddress) external onlyOwner {
        r2eAddress = _r2eAddress;
        dcAddress = _dcAddress;
        fiatMinter = _fiatMinter;
    }

    function getDeployedNFTs() external view returns (ERC721AContract[] memory) {
        return nfts;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _provenance,
        address[] memory _payees,
        uint256[] memory _shares,
        ERC721AContract.Token memory _token,
        ERC721AContract.RoyaltyInfo memory _royalties
    ) external {
        require(_payees.length == _shares.length,  "Bad splitter");
        uint16 totalShares = 0;
        for (uint16 i = 0; i < _shares.length; i++) {
            totalShares = totalShares + uint16(_shares[i]);
        }
        require(totalShares == 100,  "Bad splitter");
        require(allowlist[msg.sender],  "Not allowlisted");
        address[] memory _interfaces = new address[](3);
        _interfaces[0] = r2eAddress;
        _interfaces[1] = dcAddress;
        _interfaces[2] = fiatMinter;
        ERC721AContract nft = new ERC721AContract(_name, _symbol, _uri, _payees, _shares, msg.sender, _interfaces, _provenance, _token, _royalties);
        deployments[msg.sender] = address(nft);
        nfts.push(nft);
    }
}
