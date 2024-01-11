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
    address public treasuryAddress;
    uint8 public treasuryShare;
    address public launchpassAddress;
    ERC721AContract[] public nfts;
    address[] payees;
    uint256[] shares;

    constructor(address _treasuryAddress, address _launchpassAddress, uint8 _treasuryShare) {
        treasuryAddress = _treasuryAddress;
        treasuryShare = _treasuryShare;
        launchpassAddress = _launchpassAddress;
    }

    function setTreasuryShare(uint8 _treasuryShare) public onlyOwner {
        treasuryShare = _treasuryShare;
    }

    function setTreasuryAddress(address payable _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setLaunchPassAddress(address _launchpassAddress) public onlyOwner {
        launchpassAddress = _launchpassAddress;
    }

    function getDeployedNFTs() public view returns (ERC721AContract[] memory) {
        return nfts;
    }

    function deploy(
        address[] memory _payees,
        uint256[] memory _shares,
        ERC721AContract.InitialParameters memory initialParameters
    ) public {
        require(_payees.length == _shares.length,  "Shares and payees must have the same length.");
        payees = _payees;
        shares = _shares;
        payees.push(treasuryAddress);
        shares.push(treasuryShare);
        uint256 totalShares = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            totalShares = totalShares + shares[i];
        }
        require(totalShares == 100,  "Sum of shares must equal 100.");
        LaunchPass launchpass = LaunchPass(launchpassAddress);
        require(launchpass.balanceOf(msg.sender) > 0,  "You do not have a LaunchPass.");
        require(launchpass.ownerOf(initialParameters.launchpassId) == msg.sender,  "You do not own this LaunchPass.");
        require(deployments[initialParameters.launchpassId] == address(0),  "This LaunchPass has already been used.");
        ERC721AContract nft = new ERC721AContract(payees, shares, msg.sender, initialParameters);
        deployments[initialParameters.launchpassId] = address(nft);
        nfts.push(nft);
        payees = new address[](0);
        shares = new uint256[](0);
    }

}
