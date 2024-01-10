// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721AContract.sol";

abstract contract LaunchPass {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address);
}

contract ERC721AFactory is Ownable {

    mapping(uint256 => address) public deployments;
    address payable public treasuryAddress;
    address public launchpassAddress;
    uint8 public revenueShare;
    ERC721AContract[] public nfts;

    constructor(address payable _treasuryAddress, address _launchpassAddress, uint8 _revenueShare) {
        treasuryAddress = _treasuryAddress;
        launchpassAddress = _launchpassAddress;
        revenueShare = _revenueShare;
    }

    function setRevenueShare(uint8 _revenueShare) public onlyOwner {
        revenueShare = _revenueShare;
    }

    function setLaunchPassAddress(address _launchpassAddress) public onlyOwner {
        launchpassAddress = _launchpassAddress;
    }

    function setTreasuryAddress(address payable _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function getDeployedNFTs() public view returns (ERC721AContract[] memory) {
        return nfts;
    }

    function deploy(
        ERC721AContract.InitialParameters memory initialParameters
    ) public {
        LaunchPass launchpass = LaunchPass(launchpassAddress);
        require(launchpass.balanceOf(msg.sender) > 0,  "You do not have a LaunchPass.");
        require(launchpass.ownerOf(initialParameters.launchpassId) == msg.sender,  "You do not own this LaunchPass.");
        require(deployments[initialParameters.launchpassId] == address(0),  "This LaunchPass has already been used.");
        ERC721AContract nft = new ERC721AContract(treasuryAddress, revenueShare, msg.sender, initialParameters);
        deployments[initialParameters.launchpassId] = address(nft);
        nfts.push(nft);
    }

}
