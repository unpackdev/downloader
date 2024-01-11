// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./MintPassContract.sol";

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

contract MintPassFactory is Ownable {

    mapping(uint256 => address) public deployments;
    address public launchpassAddress;
    address payable public treasuryAddress;
    uint256 public treasuryShare;
    MintPassContract[] public nfts;

    constructor(address payable _treasuryAddress, address _launchpassAddress, uint256 _treasuryShare) {
        treasuryAddress = _treasuryAddress;
        launchpassAddress = _launchpassAddress;
        treasuryShare = _treasuryShare;
    }

    function setTreasuryShare(uint256 _treasuryShare) public onlyOwner {
        treasuryShare = _treasuryShare;
    }

    function setTreasuryAddress(address payable _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setLaunchPassAddress(address _launchpassAddress) public onlyOwner {
        launchpassAddress = _launchpassAddress;
    }

    function getDeployedNFTs() public view returns (MintPassContract[] memory) {
        return nfts;
    }

    function deploy(
        MintPassContract.InitialParameters memory initialParameters
    ) public {
        LaunchPass launchpass = LaunchPass(launchpassAddress);
        require(launchpass.balanceOf(msg.sender) > 0,  "You do not have a LaunchPass.");
        require(launchpass.ownerOf(initialParameters.launchpassId) == msg.sender,  "You do not own this LaunchPass.");
        MintPassContract nft = new MintPassContract(msg.sender, treasuryAddress, treasuryShare, initialParameters);
        deployments[initialParameters.launchpassId] = address(nft);
        nfts.push(nft);
    }

}
