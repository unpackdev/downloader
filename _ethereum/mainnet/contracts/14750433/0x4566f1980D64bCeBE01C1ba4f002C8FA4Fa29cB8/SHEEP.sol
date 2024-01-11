// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SHEEP is ERC20, Ownable, Pausable {

    address public admin;
    address public NFT_contract;

    uint256 rewardPerDay = 10 ether;

    mapping(address => uint256) public lastClaim;

    constructor() ERC20("SHEEP", "$SHEEP") {

    }

    event Claim(address, uint256);

    function mint(address to, uint256 amount) external onlyOwner{
        _mint(to, amount);
    }

    function getBalance(address owner) public view returns(uint256) {
        return IERC721(NFT_contract).balanceOf(owner);
    }

    function calculateReward(address owner) public view returns(uint256) {
        uint256 lastStamp = lastClaim[owner];

        require(block.timestamp > lastStamp);

        uint256 noClaimDelay = 0;
        uint256 numberOfDay = 0;
        uint256 NFTBalance = getBalance(owner);

        if ( lastStamp > 0) {
            noClaimDelay = block.timestamp - lastStamp;
        numberOfDay = noClaimDelay / 1 days;
        } else {
            numberOfDay = 1;
        }

        return numberOfDay * NFTBalance;
    }

    function claim(address owner) public {
        uint256 _balance = getBalance(owner);
        require(_balance > 0, "you havn't  nft");
        uint256 nb = calculateReward(owner);

        _mint(owner, nb * rewardPerDay);

        lastClaim[owner] = block.timestamp;

        emit Claim(owner, nb * rewardPerDay);
    }

    function setNFT(address _contract) external onlyOwner {
        NFT_contract = _contract;
    }

    function setReward(uint256 _nb) external onlyOwner {
        rewardPerDay = _nb;
    }
}
